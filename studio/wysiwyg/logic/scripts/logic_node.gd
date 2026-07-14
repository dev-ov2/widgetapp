extends GraphNode

var metadata: Dictionary

var type: Studio.LogicStage:
	set(v):
		type = v
		populate_options()

func set_type(new_type: Studio.LogicStage) -> void:
	type = new_type


var logic_component: LogicComponent

func set_node_option(option: Studio.LogicOption) -> void:
	if logic_component == null:
		return # no-op until we have a logic_component

	logic_component.set_option(type, option)

func get_metadata() -> Dictionary:
	return metadata


func _ready() -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		logic_component.set_metadata(type, {})
		self.queue_free()

func _update_logic_component() -> void:
	pass
	#match scene_name:
		#pass

func save_position_offset(new_position_offset: Vector2) -> void:
	if logic_component == null:
		return # no-op
	
	var metadata = logic_component.get_metadata(type)
	metadata.set("position_offset", new_position_offset)
	logic_component.set_metadata(type, metadata)

func set_logic_component(new_logic_component: LogicComponent, new_connection = false) -> void:
	logic_component = new_logic_component
	var option = logic_component.get_option(type)
	
	var option_button: OptionButton = find_child("OptionButton")
	var idx = option_button.get_item_index(option)
	option_button.select(idx)
	_on_selected(idx, new_connection) # _on_selected already does the heavy lifting, especially since "scene".init loads all the previously-determined data.

func get_logic_component() -> LogicComponent:
	return logic_component

func get_enum_label(option: Studio.LogicOption, selection_type: Studio.LogicStage) -> String:
	match selection_type:
		Studio.LogicStage.ACTION:
			match option:
				Studio.LogicOption.KEY_PRESS: return "Key Pressed"
				Studio.LogicOption.VISIBILITY: return "Visibility Updated"
				Studio.LogicOption.VALUE: return "Value Changed"
				
				# addons
				Studio.LogicOption.SHOP: return "Item Purchased"
				
		Studio.LogicStage.DEPENDENCY:
			match option:
				Studio.LogicOption.VISIBILITY: return "Visibility"
				Studio.LogicOption.VALUE: return "Specific Value"
				
				# addons
				Studio.LogicOption.SHOP: return "Shop Item"
				
		Studio.LogicStage.EFFECT:
			match option:
				Studio.LogicOption.VISIBILITY: return "Update Visibility"
				Studio.LogicOption.VALUE: return "Update Value"
				
				# addons
				Studio.LogicOption.SHOP: return "Update Shop Item"
				
	return ""

func get_option_button_items(option: Studio.LogicOption) -> Array:
	var options: Array = []
	match option:
		Studio.LogicOption.VISIBILITY: options = get_parent().get_components()
		Studio.LogicOption.VALUE: options = get_parent().get_variables()
		
		# addons
		Studio.LogicOption.SHOP: options = get_parent().get_shop_items()

	return options


func _on_selected(idx: int, update_logic_component = false) -> void:
	var option_button = find_child("OptionButton", true, false) as OptionButton
	var option = option_button.get_item_id(idx)
	
	for child in get_children():
		if child.name.to_lower() in Studio.LogicOption.keys().map(func(v:String) -> String: return v.to_lower()):
			child.queue_free()
	
	set_node_option(option)
	
	if option == Studio.LogicOption.KEY_PRESS:
		return
	
	
	var option_key = Studio.LogicOption.keys()[option]
	var scene_path = "res://studio/wysiwyg/logic/scripts/options/%s.tscn" % option_key
	var scene = load(scene_path).instantiate()
	add_child(scene)
	
	scene.find_child("DependencyContainer", true, false).visible = type == Studio.LogicStage.DEPENDENCY
	scene.find_child("EffectContainer", true, false).visible = type == Studio.LogicStage.EFFECT
	
	var options = get_option_button_items(option)
	scene.init(type, logic_component, options, update_logic_component)

func populate_options() -> void:
	var option_button = find_child("OptionButton", true, false) as OptionButton
	
	if type == Studio.LogicStage.ACTION:
		option_button.add_item(get_enum_label(Studio.LogicOption.KEY_PRESS, type), Studio.LogicOption.KEY_PRESS)
	
	# get the base options
	var base_options = [Studio.LogicOption.VISIBILITY, Studio.LogicOption.VALUE]
	for option in base_options:
		option_button.add_item(get_enum_label(option, type), option)
	
	# determine if the addon is enabled
	for addon in Studio.active_widget.get_logic().get_configured_addons():
		match addon:
			Constants.Addon.SHOP:
				var option = Studio.LogicOption.SHOP
				option_button.add_item(get_enum_label(option, type), option)
	
	option_button.item_selected.connect(_on_selected)
