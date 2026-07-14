extends Panel

signal on_node_received(node: Node, component: LayoutComponent, event: Studio.EditorEvent)

const PanelColor: Color = Color(0.0, 0.914, 0.945)

var graph: GraphEdit

@export_enum("main", "shop", "shop_list_item") var parent: String
var nodes: Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph = %GraphEdit

func _initialize_shared_node_data(node: Node, component: LayoutComponent, event: Studio.EditorEvent) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_resize_handle(node)
	
	var editable_script := load("res://studio/wysiwyg/editor/editable_component.gd")
	node.set_script(editable_script)
	
	_on_node_received(node, component, event)
	node.on_node_selected.connect(_on_node_received.bind(component, Studio.EditorEvent.SELECTED))
	node.on_node_changed.connect(_on_node_received.bind(component, Studio.EditorEvent.CHANGED))
	node.on_node_adjusted.connect(_on_node_received.bind(component, Studio.EditorEvent.NODE_ADJUSTED))
	node.on_node_removed.connect(_on_node_received.bind(component, Studio.EditorEvent.REMOVED))

func instantiate_component(new_node: Node, component: LayoutComponent, event: Studio.EditorEvent) -> void:
	if event != Studio.EditorEvent.TEMPLATED: # don't attempt to add if it's a templated variable
		add_child(new_node)
	
	if event == Studio.EditorEvent.DRAGGED:
		new_node.position = get_local_mouse_position()
		_set_default_properties(component.type, new_node)
	
	_initialize_shared_node_data(new_node, component, event)

func instantiate_saved_component(component: LayoutComponent) -> void:
	var new_node
	print("instantiating saved component")
	var found_node = find_child(component.get_name(), true, false)
	if found_node == null:
		if (component.type in Studio.USABLE_NODES or component.type == "Control") and ClassDB.can_instantiate(component.type):
			new_node = ClassDB.instantiate(component.type)
		elif component.type == "Scene":
			var scene_path = "res://utils/custom_components/scene.tscn"
			new_node = load(scene_path).instantiate()
		
		add_child(new_node)
		
		new_node.name = component.get_name()
		new_node.size = component.get_size()
		new_node.position = component.get_position()
		new_node.z_index = component.get_z_index()
		new_node.modulate.a = 1.0 if component.is_visible() else 0.5
		
		_initialize_shared_node_data(new_node, component, Studio.EditorEvent.LOADED)
	else:
		print("noop due to node already found. Name: %s, found node: %s" % [component, found_node])

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is ComponentDragData:
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is ComponentDragData:
		var component_drag_data = data as ComponentDragData
		var component = component_drag_data.component
		component.set_parent(parent)
		
		var new_node
		if component.type in Studio.USABLE_NODES and ClassDB.can_instantiate(component.type):
			new_node = ClassDB.instantiate(component.type)
		elif component.type == "Scene":
			var scene_path = "res://utils/custom_components/scene.tscn"
			new_node = load(scene_path).instantiate()
			new_node.size = Vector2(80, 80)
		
		instantiate_component(new_node, component, Studio.EditorEvent.DRAGGED)

func _set_default_properties(component_type: String, new_node: Control) -> void:
	if component_type == "Button":
		(new_node as Button).text = "Button"
		new_node.size = Vector2(64, 32)
	elif component_type == "Label":
		(new_node as Label).text = "Label"
		new_node.size = Vector2(48, 24)
	elif component_type == "Panel":
		(new_node as Panel).size = Vector2i(64, 48)
	elif component_type == "TextureRect":
		(new_node as TextureRect).texture = load("res://icon.svg")
		(new_node as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(new_node as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		(new_node as TextureRect).size = Vector2i(64, 48)
	elif component_type == "Custom":
		(new_node as TextureRect).texture = load("res://jigsaw.svg")
		(new_node as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(new_node as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		(new_node as TextureRect).size = Vector2i(64, 48)

func _add_resize_handle(node: Control) -> void:
	# Create a panel the same size as the node, and add a small panel in the bottom right corner to act as a resize handle
	var panel = Panel.new()

	var panel_style_box: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	panel_style_box.set_border_width_all(1)
	panel_style_box.set("border_color", PanelColor)
	panel_style_box.set("bg_color", Color("#FFF", 0))
	panel.add_theme_stylebox_override("panel", panel_style_box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	node.add_child(panel, true)
	panel.size = node.size

	var resize_handle: Panel = Panel.new()
	resize_handle.size = Vector2(8, 8)
	var style_box: StyleBoxFlat = resize_handle.get_theme_stylebox("panel").duplicate()
	style_box.set_corner_radius_all(0)
	style_box.set("bg_color", PanelColor)


	panel.add_child(resize_handle, true)
	resize_handle.name = "ResizeHandle"

	resize_handle.add_theme_stylebox_override("panel", style_box)
	resize_handle.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	resize_handle.offset_left = -resize_handle.size.x
	resize_handle.offset_top  = -resize_handle.size.y
	resize_handle.offset_right = 0
	resize_handle.offset_bottom = 0
	resize_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_node_received(node: Node, component: LayoutComponent, event: Studio.EditorEvent) -> void:
	on_node_received.emit(node, component, event)
