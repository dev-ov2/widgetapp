extends GraphEdit

const NodeTypes = ["action", "dependency", "effect"]

var logic_components: Array[LogicComponent] = [] 

func load_widget_data() -> void:
	logic_components = Studio.active_widget.get_logic().get_components()
	var node_script = load("res://studio/wysiwyg/logic/scripts/logic_node.gd")
	for component in logic_components:
		# spawn action node
		var action_node = load("res://studio/wysiwyg/logic/action_node.tscn").instantiate()
		action_node.set_script(node_script)

		add_child(action_node)

		action_node.position_offset = component.get_action_metadata().get("position_offset", Vector2.ZERO)
		action_node.set_type(Studio.LogicStage.ACTION)
		action_node.set_logic_component(component)
		
		var dependency_metadata = component.get_dependency_metadata()
		
		var dependency_node
		if dependency_metadata.get("connected", false):
			dependency_node = load("res://studio/wysiwyg/logic/depend_node.tscn").instantiate()
			dependency_node.set_script(node_script)
			
			add_child(dependency_node)

			dependency_node.position_offset = dependency_metadata.get("position_offset", Vector2.ZERO)
			dependency_node.set_type(Studio.LogicStage.DEPENDENCY)
			dependency_node.set_logic_component(component)
			
			connect_node(action_node.name, 0, dependency_node.name, 0)
		
		var effect_metadata = component.get_effect_metadata()
		if effect_metadata.get("connected", false):
			var effect_node = load("res://studio/wysiwyg/logic/effect_node.tscn").instantiate()
			effect_node.set_script(node_script)	

			add_child(effect_node)

			effect_node.position_offset = effect_metadata.get("position_offset", Vector2.ZERO)
			effect_node.set_type(Studio.LogicStage.EFFECT)
			effect_node.set_logic_component(component)
			
			connect_node(dependency_node.name if dependency_node != null else action_node.name, 0, effect_node.name, 0)

func _ready() -> void:
	connection_request.connect(_on_connection_request)

func _on_connection_request(from_node: String, from_slot: int, to_node: String, to_slot: int) -> void:
	connect_node(from_node, from_slot, to_node, to_slot)
	
	var leading_node = find_child(from_node, true, false)
	var trailing_node = find_child(to_node, true, false) as GraphNode
	
	var logic_component: LogicComponent = leading_node.get_logic_component()
	match trailing_node.type:
		Studio.LogicStage.DEPENDENCY:
			var metadata = logic_component.get_dependency_metadata()
			metadata.set("connected", true)
			metadata.set("position_offset", trailing_node.position_offset)
			logic_component.set_dependency_metadata(metadata)
			trailing_node.set_slot_enabled_right(0, true)
		Studio.LogicStage.EFFECT:
			var metadata = logic_component.get_effect_metadata()
			metadata.set("connected", true)
			metadata.set("position_offset", trailing_node.position_offset)
			logic_component.set_effect_metadata(metadata)
		
	trailing_node.set_logic_component(logic_component, true)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is GraphNodeDragData:
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is GraphNodeDragData:
		var new_node = data.graph_node
		new_node.script = null
		var node_script = load("res://studio/wysiwyg/logic/scripts/logic_node.gd")
		new_node.set_script(node_script) 
		add_child(data.graph_node)
		
		new_node.set_type(data.type)

		new_node.position_offset = (get_local_mouse_position() + scroll_offset) / zoom
		
		if data.type == Studio.LogicStage.ACTION:
			new_node.set_logic_component(LogicComponent.new({ "action": Studio.LogicOption.KEY_PRESS, "action_metadata": { "position_offset": new_node.position_offset }}))
		if data.type == Studio.LogicStage.DEPENDENCY:
			new_node.set_slot_enabled_right(0, false) # disable until we have a primary connection


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		
		var con := get_closest_connection_at_point(event.position, 6.0)
		if con.is_empty():
			return
		
		disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)
		var leading_node = find_child(con.from_node, true, false) as GraphNode
		var logic_component = leading_node.get_logic_component()
		
		var trailing_node = find_child(con.to_node, true, false) as GraphNode
		match trailing_node.type:
			Studio.LogicStage.DEPENDENCY:
				var metadata = logic_component.get_dependency_metadata()
				metadata.set("connected", false)
				logic_component.set_dependency_metadata(metadata)
			Studio.LogicStage.EFFECT:
				var metadata = logic_component.get_effect_metadata()
				metadata.set("connected", false)
				logic_component.set_effect_metadata(metadata)

func get_variables() -> Array[LogicVariable]:
	return Studio.active_widget.get_logic().get_variables()

func get_shop_items() -> Array[ShopItem]:
	var json = IO.load_file(Studio.active_widget, "shop.json")
	var arr = JSON.parse_string(json)
	var shop_items: Array[ShopItem]
	for item in arr:
		shop_items.append(ShopItem.new(item))
	return shop_items

func get_components() -> Array[LayoutComponent]:
	return WidgetLayout.filter_parent(Studio.active_widget.get_layout().get_components(), "main")

func save_data() -> void:
	var components: Array[LogicComponent] = []
	for child in get_children():
		if child is GraphNode:
			child.save_position_offset(child.position_offset)
		if child.get_property_list().any(func(p): return p.name == "type") and child.type == Studio.LogicStage.ACTION:
			child.get_logic_component().to_dict()
			components.append(child.get_logic_component())
	Studio.active_widget.get_logic().set_components(components)
