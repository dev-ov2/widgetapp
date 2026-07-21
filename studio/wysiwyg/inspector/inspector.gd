extends Control

var latest_node_name: String
var node: Node
var component: LayoutComponent
var _suppress_history: bool = false
# Avoid reloading the same pack scenes (and re-spamming UID warnings) on every select
var _packed_scene_cache: Dictionary = {}

func find_component(component_name: String) -> LayoutComponent:
	return WidgetLayout.find_component(Studio.active_widget.get_layout().get_components(), component_name)

func _ready() -> void:
	%NameLineEdit.text_changed.connect(_on_general_property_changed.bind("name"))
	%SizeWidthLineEdit.text_changed.connect(_on_general_property_changed.bind("width"))
	%SizeHeightLineEdit.text_changed.connect(_on_general_property_changed.bind("height"))
	%PositionXLineEdit.text_changed.connect(_on_general_property_changed.bind("position_x"))
	%PositionYLineEdit.text_changed.connect(_on_general_property_changed.bind("position_y"))
	%ZIndexLineEdit.text_changed.connect(_on_general_property_changed.bind("z_index"))
	%VisibilityCheckButton.toggled.connect(_on_visibility_updated)

func get_component(new_component: LayoutComponent) -> void:
	var widget_component = find_component(node.name)
	if widget_component == null:
		# populate the passed component here and set the ref
		new_component.set_name(node.name)
		new_component.set_size(node.size)
		new_component.set_position(node.position)
		new_component.set_visible(node.modulate.a == 1.0)
		new_component.set_z_index(node.z_index)
		Studio.active_widget.get_layout().add_component(new_component)
		component = new_component
	else:
		component = widget_component

func _update_general_properties() -> void:
	_suppress_history = true
	var _control = node as Control
	%NameLineEdit.text = node.name
	component.set_name(node.name)
	%SizeWidthLineEdit.text = str(node.size.x)
	%SizeHeightLineEdit.text = str(node.size.y)
	component.set_size(Vector2(node.size))
	%PositionXLineEdit.text = str(node.position.x)
	%PositionYLineEdit.text = str(node.position.y)
	component.set_position(node.position)
	%ZIndexLineEdit.text = str(node.z_index)
	component.set_z_index(node.z_index)
	%VisibilityCheckButton.button_pressed = node.modulate.a == 1.0
	component.set_visible(node.modulate.a == 1.0)
	
	%ListItemNameLegendLabel.visible = component.get_parent() == "shop_list_item"
	_suppress_history = false

func clear_state() -> void:
	node = null
	component = null
	latest_node_name = ""
	for child in %TypeContainer.get_children():
		child.free()

func _record_layout_history() -> void:
	if _suppress_history:
		return
	Studio.layout_history.record(Studio.active_widget.get_layout())

# TODO separate into individual inspector type scripts!
func _register_type_properties(type: String, event: Studio.EditorEvent) -> void:
	# we'll be loading the default values into the component and saving it into the layout if this is true.
	var new_node = event in [Studio.EditorEvent.DRAGGED, Studio.EditorEvent.TEMPLATED]
	
	var metadata = component.get_metadata()
	match type:
		"Button":
			var button = node as Button
			var text_line_edit = %TypeContainer.find_child("TextLineEdit", true, false)
			var click_action_option_button = %TypeContainer.find_child("ClickActionOptionButton", true, false)
			
			if new_node:
				metadata.set("text", button.text)
				metadata.set("click_action", {"id": 0, "text": click_action_option_button.get_item_text(0)})
			
			var button_text = metadata.get("text", button.text)
			button.text = button_text
			
			text_line_edit.text = button_text
			text_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "text"))
			
			var selected_id = metadata.get("click_action", {}).get("id", 0)
			click_action_option_button.select(selected_id)
			click_action_option_button.item_selected.connect(_on_item_selected.bind(type, click_action_option_button))
		"Label":
			var label = node as Label
			var label_line_edit = %TypeContainer.find_child("LabelLineEdit", true, false)
			var size_line_edit = %TypeContainer.find_child("SizeLineEdit", true, false)
			
			if new_node:
				metadata.set("text", label.text)
				metadata.set("font_size", label.get_theme_font_size("font_size"))
			
			var label_text = metadata.get("text", label.text)
			label.text = label_text
			
			var label_font_size = metadata.get("font_size", label.get_theme_font_size("font_size"))
			label.add_theme_font_size_override("font_size", label_font_size)
			
			label_line_edit.text = label_text
			size_line_edit.text = str(label_font_size)
			
			label_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "text"))
			size_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "font_size"))
		"TextureRect":
			var texture_rect = node as TextureRect
			var texture_path_line_edit = %TypeContainer.find_child("TexturePathLineEdit", true, false)
			
			if new_node:
				metadata.set("texture_path", "res://icon.svg")
			
			var texture_path = metadata.get("texture_path", "res://icon.svg")
			texture_rect.texture = load(texture_path)
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_path_line_edit.text = texture_path
			texture_path_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "texture_path"))
			
			
		"Panel":
			var panel = node as Panel
			var color_picker_button = %TypeContainer.find_child("ColorPickerButton", true, false)
			var default_color = (panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
			
			var hex_color
			if new_node:
				hex_color = "#%s" % default_color.to_html()
				metadata.set("hex_color", hex_color)
			
			hex_color = metadata.get("hex_color", "")
			var color = Color(hex_color) if !hex_color.is_empty() else ((panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color)
			color_picker_button.color = color
			var stylebox := (node as Panel).get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			stylebox.bg_color = color
			panel.add_theme_stylebox_override("panel", stylebox)
			
			color_picker_button.color_changed.connect(_on_panel_color_changed)
		"Scene":
			var _scene = node
			var pack_path_line_edit = %TypeContainer.find_child("PackPathLineEdit", true, false)
			var scene_path_line_edit = %TypeContainer.find_child("ScenePathLineEdit", true, false)
			var scale_width_line_edit = %TypeContainer.find_child("ScaleWidthLineEdit", true, false)
			var scale_height_line_edit = %TypeContainer.find_child("ScaleHeightLineEdit", true, false)
			
			var pack_path = metadata.get("pack_path", "").trim_prefix("./")
			var scene_path = metadata.get("scene_path", "")
			var scale_x = metadata.get("scale_x", 1)
			var scale_y = metadata.get("scale_y", 1)
			
			pack_path_line_edit.text = metadata.get("pack_path", "")
			scene_path_line_edit.text = scene_path
			scale_width_line_edit.text = str(scale_x)
			scale_height_line_edit.text = str(scale_y)
			
			_mount_scene_into_node(node, pack_path, scene_path, scale_x, scale_y)
			node.size = component.get_size()
			
			pack_path_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "pack_path"))
			scene_path_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "scene_path"))
			scale_width_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "scale_x"))
			scale_height_line_edit.text_changed.connect(_on_text_value_changed.bind(type, "scale_y"))
	
	if new_node:
		Studio.active_widget.get_layout().update_component(latest_node_name, component)

func _get_cached_packed_scene(pack_file: String, scene_path: String) -> PackedScene:
	var key = "%s|%s" % [pack_file, scene_path]
	if _packed_scene_cache.has(key):
		return _packed_scene_cache[key]
	# CACHE_MODE_REUSE: don't re-parse (and re-warn about stale UIDs) every select
	var packed_scene := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	_packed_scene_cache[key] = packed_scene
	return packed_scene

func _apply_instance_scale(instance: Node, scale_x: float, scale_y: float) -> void:
	if instance == null:
		return
	
	if instance is Node2D:
		(instance as Node2D).scale = Vector2(scale_x, scale_y)
	
	elif instance is Control:
		(instance as Control).scale = Vector2(scale_x, scale_y)
	
	elif instance is Node3D:
		(instance as Node3D).scale = Vector3(scale_x, scale_y, 1.0)

func _mount_scene_into_node(target: Node, pack_path: String, scene_path: String, scale_x: float, scale_y: float, force_reload: bool = false) -> void:
	var sub = target.find_child("SubViewport", true, false)
	if sub == null:
		return
	
	var mount_key = "%s|%s" % [pack_path, scene_path]
	if !force_reload and target.get_meta("_mounted_scene_key", "") == mount_key and sub.get_child_count() > 0:
		_apply_instance_scale(sub.get_child(0), scale_x, scale_y)
		return
	
	if pack_path.is_empty() or scene_path.is_empty():
		return
	
	var absolute_path = Studio.active_widget.get_metadata().get_absolute_path()
	var path = absolute_path.path_join(pack_path).simplify_path()
	var pack_file = ProjectSettings.globalize_path(path)
	
	if !FileAccess.file_exists(path) or !pack_file.to_lower().ends_with(".zip"):
		if !pack_path.is_empty():
			push_warning("Scene: pack must be a .zip at '%s'" % path)
		return
	
	if !ProjectSettings.load_resource_pack(pack_file, false):
		push_warning("Scene: failed to load resource pack at '%s'" % pack_file)
		return
	
	var packed_scene := _get_cached_packed_scene(pack_file, scene_path)
	if packed_scene == null:
		push_warning("Scene: couldn't load '%s' from pack (check the path matches the zip, e.g. res://drop-scene/coaster.tscn)" % scene_path)
		return
	
	for child in sub.get_children():
		child.free()
	var instance: Node = packed_scene.instantiate()
	if sub is SubViewport:
		(sub as SubViewport).handle_input_locally = true
		(sub as SubViewport).gui_disable_input = false
	
	sub.add_child(instance)
	_apply_instance_scale(instance, scale_x, scale_y)
	target.set_meta("_mounted_scene_key", mount_key)

func update_state(new_node: Node, new_component: LayoutComponent, event: Studio.EditorEvent) -> void:
	if event in [Studio.EditorEvent.DRAGGED, Studio.EditorEvent.TEMPLATED, Studio.EditorEvent.LOADED, Studio.EditorEvent.SELECTED] and latest_node_name != new_node.name:
		latest_node_name = new_node.name
		node = new_node
		get_component(new_component)
		for child in %TypeContainer.get_children():
			child.free() # if we don't immediately free, we'll get hung up on this node in the next few lines (like above).
		if component.type in Studio.USABLE_NODES:
			var scene_path = "res://studio/wysiwyg/inspector/types/%s.tscn" % component.type
			var scene = load(scene_path).instantiate()
			%TypeContainer.add_child(scene)
		elif component.type == "Scene":
			var scene_path = "res://studio/wysiwyg/inspector/types/scene.tscn"
			var scene = load(scene_path).instantiate()
			%TypeContainer.add_child(scene)
		
		_register_type_properties(component.type, event)
	
	if event == Studio.EditorEvent.REMOVED:
		node = new_node
		get_component(new_component)
		Studio.active_widget.get_layout().remove_component(component)
		node = null
		latest_node_name = ""
		return
	
	# need to update on each move so we get the updated position/scale
	_update_general_properties()

func _on_text_value_changed(new_text: String, type: String, key: String) -> void:
	_record_layout_history()
	var metadata = component.get_metadata()
	
	match type:
		"Button":
			if key == "text":
				(node as Button).text = new_text
				metadata.set("text", new_text)
		"Label":
			if key == "text":
				(node as Label).text = new_text
				metadata.set("text", new_text)
			elif key == "font_size":
				(node as Label).add_theme_font_size_override("font_size", int(new_text))
				metadata.set("font_size", int(new_text))
		"TextureRect":
			if key == "texture_path":
				if !FileAccess.file_exists(new_text):
					return
				(node as TextureRect).texture = load(new_text)
				metadata.set("texture_path", new_text)
		"Panel":
			if key == "color":
				pass # handled elsewhere for now
		"Scene":
			if key == "pack_path" or key == "scene_path":
				metadata.set(key, new_text)
				
				var pack_path = metadata.get("pack_path", "").trim_prefix("./")
				var scene_path = metadata.get("scene_path", "")
				var scale_x = float(metadata.get("scale_x", 1))
				var scale_y = float(metadata.get("scale_y", 1))
				_mount_scene_into_node(node, pack_path, scene_path, scale_x, scale_y, true)
			elif key == "scale_x":
				_apply_instance_scale(
					node.find_child("SubViewport").get_child(0),
					float(new_text),
					float(metadata.get("scale_y", 1)),
				)
				metadata.set("scale_x", float(new_text))
			elif key == "scale_y":
				_apply_instance_scale(
					node.find_child("SubViewport").get_child(0),
					float(metadata.get("scale_x", 1)),
					float(new_text),
				)
				metadata.set("scale_y", float(new_text))
	
	component.set_metadata(metadata)
	Studio.active_widget.get_layout().update_component(latest_node_name, component)
	pass
	
func _on_panel_color_changed(color: Color) -> void:
	_record_layout_history()
	var metadata = component.get_metadata()
	
	var stylebox := (node as Panel).get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	stylebox.bg_color = color
	(node as Panel).add_theme_stylebox_override("panel", stylebox)
	
	var hex_color = "#%s" % color.to_html()
	metadata.set("hex_color", hex_color)
	
	component.set_metadata(metadata)
	Studio.active_widget.get_layout().update_component(latest_node_name, component)

func _on_item_selected(idx: int, type: String, option_button: OptionButton) -> void:
	_record_layout_history()
	var metadata = component.get_metadata()
	
	match type:
		"Button":
			var option_dict = { "value": option_button.get_item_text(idx), "idx": idx}
			metadata.set("click_action", option_dict)
	
	component.set_metadata(metadata)
	Studio.active_widget.get_layout().update_component(latest_node_name, component)

func _on_general_property_changed(new_text: String, field: String) -> void:
	if node != null:
		_record_layout_history()
		match field:
			"name":
				var layout = Studio.active_widget.get_layout()
				var unique = layout.make_unique_name(new_text, component)
				node.name = unique
				# Godot may uniquify among siblings; keep layout in sync / free of collisions
				unique = layout.make_unique_name(str(node.name), component)
				if str(node.name) != unique:
					node.name = unique
				unique = str(node.name)
				component.set_name(unique)
				latest_node_name = unique
				if %NameLineEdit.text != unique:
					_suppress_history = true
					%NameLineEdit.text = unique
					_suppress_history = false
			"width":
				node.size.x = int(new_text)
				node.find_child("Panel", true, false).size.x = int(new_text)
				component.set_size(Vector2(float(new_text), component.get_size().y))
			"height":
				node.size.y = int(new_text)
				node.find_child("Panel", true, false).size.y = int(new_text)
				component.set_size(Vector2(component.get_size().x, float(new_text)))
			"position_x":
				node.position.x = int(new_text)
				component.set_position(Vector2(float(new_text), component.get_position().y))
			"position_y":
				node.position.y = int(new_text)
				component.set_position(Vector2(component.get_position().y, float(new_text)))
			"z_index":
				node.z_index = int(new_text)
				component.set_z_index(int(new_text))
	
	Studio.active_widget.get_layout().update_component(latest_node_name, component)

func _on_visibility_updated(new_visible: bool) -> void:
	_record_layout_history()
	node.modulate.a = 1.0 if new_visible else 0.5
	component.set_visible(new_visible)
	Studio.active_widget.get_layout().update_component(latest_node_name, component)


func _on_edit_logic_button_pressed() -> void:
	var scene = load("res://studio/wysiwyg/logic/logic_flow.tscn").instantiate()
	Display.show(self, "Edit Widget Logic", scene, Vector2(1152, 648), true, _on_logic_flow_close_requested.bind(scene))
	scene.load_widget_data()

func _on_logic_flow_close_requested(window: Window, scene: Node) -> void:
	scene.save_widget_data()
	window.queue_free()
