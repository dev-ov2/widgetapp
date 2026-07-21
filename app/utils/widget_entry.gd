extends Control

var widget_data: WidgetData
var widget_id: String

var draggable: bool
var _focus_mode: bool = false
var _buttons_disabled_by_focus: Array[BaseButton] = []

var tracked_nodes: Array[Node]

var dragging: bool
var drag_offset: Vector2
signal drag_completed

var shop: Dictionary
var shop_window: Window

const DynamicPassthrough = preload("res://app/utils//DynamicPassthrough.cs")
const WindowFocusController = preload("res://app/utils/WindowFocusController.cs")
const WidgetGameModeControllerScript = preload("res://app/utils/WidgetGameModeController.gd")
const LOGICAL_NODE_SCRIPT = preload("res://app/utils/logic/logical_node.gd")
const WR_COMPONENT = preload("res://addons/widgetry_runtime/runtime/wr_layout_component.gd")
const EDIT_BORDER_COLOR = Color(0.0, 0.914, 0.945)

var passthrough_node
var window_focus_controller
var game_mode_controller: WidgetGameModeController
var _pending_game_mode_settings: WidgetGameModeSettings
var _edit_border: Panel
var _configured_volume: float = 1.0
var _pack_suppression_snapshot: Array[Dictionary] = []
var _scene_mouse_filter_snapshot: Array[Dictionary] = []

func set_widget_data(new_widget_data: WidgetData) -> void:
	widget_data = new_widget_data
	_construct_widget()

func apply_display_settings(opacity: float, volume: float) -> void:
	modulate.a = clampf(opacity, 0.0, 1.0)
	_configured_volume = clampf(volume, 0.0, 1.0)
	_apply_effective_volume()

func _apply_effective_volume() -> void:
	var suppressed := game_mode_controller != null and game_mode_controller.is_suspended()
	var volume := 0.0 if suppressed else _configured_volume
	_apply_volume(self, volume)
	_set_pack_simulation_suppressed(self, suppressed)
	if shop_window and is_instance_valid(shop_window):
		_apply_volume(shop_window, volume)
		_set_pack_simulation_suppressed(shop_window, suppressed)

func _apply_volume(root: Node, volume: float) -> void:
	var linear := clampf(volume, 0.0, 1.0)
	var volume_db := -80.0 if linear <= 0.0 else linear_to_db(linear)
	_set_volume_recursive(root, volume_db)

func _set_volume_recursive(node: Node, volume_db: float) -> void:
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).volume_db = volume_db
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).volume_db = volume_db
	elif node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).volume_db = volume_db
	for child in node.get_children():
		_set_volume_recursive(child, volume_db)

func _set_pack_simulation_suppressed(node: Node, suppressed: bool) -> void:
	if node is SubViewport:
		_set_subviewport_suppressed(node as SubViewport, suppressed)
	
	elif node is SubViewportContainer:
		(node as SubViewportContainer).process_mode = \
			Node.PROCESS_MODE_DISABLED if suppressed else Node.PROCESS_MODE_INHERIT
	
	for child in node.get_children():
		_set_pack_simulation_suppressed(child, suppressed)

func _set_subviewport_suppressed(viewport: SubViewport, suppressed: bool) -> void:
	if suppressed:
		if _find_viewport_snapshot(viewport) < 0:
			_pack_suppression_snapshot.append({
				"viewport": viewport,
				"process_mode": viewport.process_mode,
				"render_target_update_mode": viewport.render_target_update_mode,
				"audio_listener_enable_2d": viewport.audio_listener_enable_2d,
				"audio_listener_enable_3d": viewport.audio_listener_enable_3d,
			})
	
		viewport.process_mode = Node.PROCESS_MODE_DISABLED
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		viewport.audio_listener_enable_2d = false
		viewport.audio_listener_enable_3d = false
	
		for child in viewport.get_children():
			_suppress_pack_tree(child)
	else:
		_restore_viewport_snapshot(viewport)
	
		for child in viewport.get_children():
			_unsuppress_pack_tree(child)

func _find_viewport_snapshot(viewport: SubViewport) -> int:
	for i in _pack_suppression_snapshot.size():
		var entry: Dictionary = _pack_suppression_snapshot[i]

		if entry.get("viewport") == viewport:
			return i
	
	return -1

func _restore_viewport_snapshot(viewport: SubViewport) -> void:
	var index := _find_viewport_snapshot(viewport)
	if index < 0:
		viewport.process_mode = Node.PROCESS_MODE_INHERIT
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.audio_listener_enable_2d = true
		viewport.audio_listener_enable_3d = false
		return
	
	var entry: Dictionary = _pack_suppression_snapshot[index]
	
	viewport.process_mode = entry.process_mode
	viewport.render_target_update_mode = entry.render_target_update_mode
	viewport.audio_listener_enable_2d = entry.audio_listener_enable_2d
	viewport.audio_listener_enable_3d = entry.audio_listener_enable_3d
	
	_pack_suppression_snapshot.remove_at(index)

func _suppress_pack_tree(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stream_paused = true
		player.volume_db = -80.0
	
	elif node is AudioStreamPlayer2D:
		var player2d := node as AudioStreamPlayer2D
		player2d.stream_paused = true
		player2d.volume_db = -80.0
	
	elif node is AudioStreamPlayer3D:
		var player3d := node as AudioStreamPlayer3D
		player3d.stream_paused = true
		player3d.volume_db = -80.0
	
	for child in node.get_children():
		_suppress_pack_tree(child)

func _unsuppress_pack_tree(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).stream_paused = false
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).stream_paused = false
	elif node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).stream_paused = false
	for child in node.get_children():
		_unsuppress_pack_tree(child)

func set_draggable(new_draggable: bool) -> void:
	var changed := draggable != new_draggable
	draggable = new_draggable
	if changed:
		_set_scene_drag_passthrough(draggable)
	handle_passthrough()

func _set_scene_drag_passthrough(enabled: bool) -> void:
	if enabled:
		_scene_mouse_filter_snapshot.clear()
		_capture_scene_mouse_filters(self)
		return
	_restore_scene_mouse_filters()

func _capture_scene_mouse_filters(node: Node) -> void:
	if node is SubViewportContainer:
		var container := node as SubViewportContainer
		_scene_mouse_filter_snapshot.append({
			"container": container,
			"mouse_filter": container.mouse_filter,
		})
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_capture_scene_mouse_filters(child)

func _restore_scene_mouse_filters() -> void:
	for entry in _scene_mouse_filter_snapshot:
		var container := entry["container"] as SubViewportContainer
		if is_instance_valid(container):
			container.mouse_filter = entry["mouse_filter"]
	_scene_mouse_filter_snapshot.clear()

func handle_passthrough() -> void:
	if game_mode_controller != null:
		game_mode_controller.apply_passthrough(draggable)

func set_edit_border(enabled: bool) -> void:
	_prepare_edit_border()
	_edit_border.visible = enabled
	if enabled:
		move_child(_edit_border, get_child_count() - 1)

func _prepare_edit_border() -> void:
	if _edit_border != null and is_instance_valid(_edit_border):
		return
	_edit_border = Panel.new()
	_edit_border.name = "EditBorder"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.set_border_width_all(1)
	style.border_color = EDIT_BORDER_COLOR
	_edit_border.add_theme_stylebox_override("panel", style)
	_edit_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edit_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edit_border.z_index = 4096
	_edit_border.visible = false
	add_child(_edit_border)

func set_widget_focus_mode(enabled: bool) -> void:
	if enabled == _focus_mode:
		return
	_focus_mode = enabled
	
	if game_mode_controller != null:
		game_mode_controller.set_focus_mode(enabled)
	
	if enabled:
		_buttons_disabled_by_focus.clear()
		_disable_interactive_buttons(self)
		if shop_window:
			shop_window.hide()
		if passthrough_node:
			handle_passthrough()
	else:
		for button in _buttons_disabled_by_focus:
			if is_instance_valid(button):
				button.disabled = false
		_buttons_disabled_by_focus.clear()
		if passthrough_node:
			handle_passthrough()

func apply_game_mode_settings(settings: WidgetGameModeSettings) -> void:
	if game_mode_controller == null:
		_pending_game_mode_settings = settings
		return
	
	_apply_game_mode_settings(settings)

func _apply_game_mode_settings(settings: WidgetGameModeSettings) -> void:
	var id := widget_data.get_metadata().get_id() if widget_data != null else ""
	
	game_mode_controller.apply_settings(settings, id, get_widget_pack_zip_files())

func _disable_interactive_buttons(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		if not button.disabled:
			button.disabled = true
			_buttons_disabled_by_focus.append(button)
	for child in node.get_children():
		_disable_interactive_buttons(child)

func _ready() -> void:
	passthrough_node = DynamicPassthrough.new()
	add_child(passthrough_node)
	window_focus_controller = WindowFocusController.new()
	add_child(window_focus_controller)
	
	game_mode_controller = WidgetGameModeControllerScript.new()
	add_child(game_mode_controller)
	
	game_mode_controller.setup(self, passthrough_node, window_focus_controller)
	game_mode_controller.state_changed.connect(_on_game_mode_state_changed)
	
	if _pending_game_mode_settings != null:
		_apply_game_mode_settings(_pending_game_mode_settings)
		_pending_game_mode_settings = null
	
	var key_bridge := get_tree().root.get_node_or_null("GlobalKeyBridge")
	
	if key_bridge != null:
		if !key_bridge.GlobalKeyPressed.is_connected(_on_global_key_pressed):
			key_bridge.GlobalKeyPressed.connect(_on_global_key_pressed)
		if !key_bridge.GlobalKeyCaptured.is_connected(_on_global_key_captured):
			key_bridge.GlobalKeyCaptured.connect(_on_global_key_captured)
	
	_connect_action_button()

func _exit_tree() -> void:
	_restore_scene_mouse_filters()
	var key_bridge := get_tree().root.get_node_or_null("GlobalKeyBridge") if is_inside_tree() else null
	
	if key_bridge != null:
		if key_bridge.GlobalKeyPressed.is_connected(_on_global_key_pressed):
			key_bridge.GlobalKeyPressed.disconnect(_on_global_key_pressed)
		if key_bridge.GlobalKeyCaptured.is_connected(_on_global_key_captured):
			key_bridge.GlobalKeyCaptured.disconnect(_on_global_key_captured)

func _on_game_mode_state_changed() -> void:
	_apply_effective_volume()
	handle_passthrough()

func _connect_action_button() -> void:
	if %Panel.has_signal("button_action") and !%Panel.button_action.is_connected(_on_layout_button_pressed):
		%Panel.button_action.connect(_on_layout_button_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if draggable:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_offset = get_parent().position - DisplayServer.mouse_get_position()
				else:
					if dragging:
						drag_completed.emit()
					dragging = false

	if event is InputEventMouseMotion:
		if dragging:
			(get_parent() as Window).position = DisplayServer.mouse_get_position() + Vector2i(drag_offset)

func _construct_widget() -> void:
	_connect_action_button()
	var save_data = _get_save_data()
	var mounted = _mount_layout(%Panel, "main", save_data)
	if !mounted:
		push_error("widget_entry: failed to mount main layout")
		return

	_populate_root(%Panel, save_data, "main")

	var configured_addons = widget_data.get_logic().get_configured_addons()
	_register_logic(configured_addons)

	if configured_addons.has(Constants.Addon.SHOP):
		_construct_shop(widget_data.get_layout().get_components())

func _layout_dict() -> Dictionary:
	return widget_data.get_layout().to_dict()

func _package_root() -> String:
	return widget_data.get_metadata().get_absolute_path()

func get_widget_pack_zip_files() -> Array[String]:
	var files: Array[String] = []
	
	if widget_data == null:
		return files
	
	var root := _package_root()
	
	for component in widget_data.get_layout().get_components():
		if component.get_type() != "Scene":
			continue
		
		var pack_path := str(component.get_metadata().get("pack_path", "")).trim_prefix("./")
		if pack_path.is_empty():
			continue
		
		var absolute := root.path_join(pack_path).simplify_path()
		if !absolute.to_lower().ends_with(".zip"):
			continue
		
		if FileAccess.file_exists(absolute) and absolute not in files:
			files.append(absolute)
	return files

func _variables_for_mount(save_data: SaveData) -> Dictionary:
	var variables := {}
	for variable in save_data.get_variables():
		variables[variable.name] = variable.get_current_value()
	return variables

func _mount_layout(renderer: Node, parent_key: String, save_data: SaveData, incoming_mouse_filter: int = Control.MOUSE_FILTER_IGNORE) -> bool:
	if renderer == null or !renderer.has_method("mount"):
		return false
	return bool(renderer.mount(_layout_dict(), {
		"package_root": _package_root(),
		"enable_scene_packs": true,
		"parent_key": parent_key,
		"variables": _variables_for_mount(save_data),
		"mouse_filter": incoming_mouse_filter,
		"ghost_hidden_nodes": false,
	}))

func _populate_root(root: Node, save_data: SaveData, bind_type: String) -> void:
	for child in root.get_children():
		if !(child is Control):
			continue
		_display_node(child as Control, save_data, bind_type)

func _display_node(node: Control, save_data: SaveData, bind_type: String) -> void:
	_apply_save_overrides(node, save_data)

	var component = WidgetLayout.find_component(
		widget_data.get_layout().get_components(),
		str(node.name),
	)

	if bind_type == "main":
		node.set_script(LOGICAL_NODE_SCRIPT)
		if node.has_signal("on_visibility_changed"):
			node.on_visibility_changed.connect(_on_visibility_action.bind(node))
		if component != null and component.get_type() == "Button":
			var click_metadata = component.get_metadata().get("click_action", {})
			var click_action = int(click_metadata.get("id", 0))
			(node as Button).pressed.connect(_on_layout_button_pressed.bind(click_action))

	if component != null and ["Button", "Label"].has(component.get_type()):
		node.text = _substitute(node, str(component.get_metadata().get("text", node.text)))

	if node is Button:
		tracked_nodes.append(node)
		if passthrough_node:
			passthrough_node.add_control(node)

func _apply_save_overrides(node: Control, save_data: SaveData) -> void:
	var overrides: Dictionary = save_data.get_component_overrides().get(node.name, {})
	if overrides.is_empty():
		return
	if overrides.has("size"):
		node.size = overrides.get("size")
	if overrides.has("position"):
		node.position = overrides.get("position")
	if overrides.has("visible"):
		node.visible = overrides.get("visible")
	if overrides.has("z_index"):
		node.z_index = overrides.get("z_index")

func _get_save_data() -> SaveData:
	var parsed = JSON.parse_string(IO.get_save_data(widget_data))
	var save_data = SaveData.new(parsed)
	var widget_variables = widget_data.get_logic().get_variables()
	if save_data.get_variables().size() != widget_variables.size():
		for widget_variable in widget_variables:
			var idx = save_data.get_variables().find(func(cv): return cv.name == widget_variable.name)
			if idx == -1:
				var config_variable = ConfigVariable.new(widget_variable.to_dict())
				save_data.add_variable(config_variable)

		_save_data(save_data)
		save_data = SaveData.new(JSON.parse_string(IO.get_save_data(widget_data)))

	return save_data

func _save_data(save_data: SaveData) -> void:
	IO.save_data(widget_data, save_data.to_string())

func _substitute(node: Variant, text: String) -> String:
	var new_text = text
	var re := RegEx.new()
	re.compile("\\{([^}]+)\\}")
	var matches := re.search_all(new_text)
	var detected_names := {}

	if matches.size() > 0:
		var save_data = _get_save_data()
		var variables = save_data.get_variables()
		for m in matches:
			detected_names[m.get_string(1)] = true
		for variable in variables:
			if detected_names.has(variable.name):
				variable.add_listening_node(node.name)
				save_data.update_variable(variable.name, variable)
				_save_data(save_data)

				new_text = new_text.replace("{%s}" % variable.name, str(int(variable.current_value)))
	return new_text

func _on_layout_button_pressed(action: int) -> void:
	match action:
		0: # open shop
			if shop_window:
				shop_window.show()

func _register_logic(addons: Array[Constants.Addon]) -> void:
	var save_data = _get_save_data()
	for node in %Panel.get_children():
		_on_visibility_action(node.visible, node)

	for variable in save_data.get_variables():
		_on_variable_value_changed(variable.get_name())

	if addons.has(Constants.Addon.SHOP):
		var shop_data = save_data.get_shop_data()
		for shop_item in shop_data.keys():
			_on_shop_item_unlocked(shop_item, save_data)

###########################################
###########################################
################## Logic ##################
###########################################
###########################################

func _get_logic_components(stage: Studio.LogicStage, action: Studio.LogicOption, source: String) -> Array[LogicComponent]:
	var logic_components = widget_data.get_logic().get_components()
	return logic_components.filter(func(c: LogicComponent):
		return c.get_option(stage) == action\
		 and c.get_metadata(stage).get("source", "") == source)

func _on_global_key_captured() -> void:
	if game_mode_controller == null or !game_mode_controller.is_focused():
		return
	
	var bridge := get_tree().root.get_node_or_null("GlobalKeyBridge")
	if bridge == null or !bridge.has_method("build_last_key_event"):
		return
	
	var event: InputEventKey = bridge.build_last_key_event()
	if event == null:
		return
	
	var window := get_parent() as Window
	if window != null and window.has_focus():
		return
	
	_inject_captured_key_into_scene(event)

func _on_global_key_pressed() -> void:
	if game_mode_controller != null and game_mode_controller.is_suspended():
		return

	_dispatch_key_pressed(%Panel)

	var logic_components = widget_data.get_logic().get_components()\
	.filter(func(c: LogicComponent):
		return c.get_option(Studio.LogicStage.ACTION) == Studio.LogicOption.KEY_PRESS
	)
	var save_data = _get_save_data()

	for component in logic_components:
		handle_logic_component(component, save_data)

func _inject_captured_key_into_scene(event: InputEventKey) -> void:
	Input.parse_input_event(event.duplicate())
	
	_push_input_event_to_subviewports(%Panel, event)
	if event.pressed:
		_dispatch_key_pressed(%Panel)

func _push_input_event_to_subviewports(node: Node, event: InputEvent) -> void:
	if node is SubViewport:
		(node as SubViewport).push_input(event.duplicate())
	
	for child in node.get_children():
		_push_input_event_to_subviewports(child, event)

func _dispatch_key_pressed(node: Node) -> void:
	if node is SubViewport and node.get_child_count() > 0:
		var main_node: Node = node.get_child(0)
		if main_node.has_method("on_key_pressed"):
			main_node.call("on_key_pressed")
	for child in node.get_children():
		_dispatch_key_pressed(child)

func _on_visibility_action(_new_visible: bool, node: Control) -> void:
	var logic_components = _get_logic_components(Studio.LogicStage.ACTION, Studio.LogicOption.VISIBILITY, node.name)
	var save_data = _get_save_data()

	for component in logic_components:
		handle_logic_component(component, save_data)

func _on_variable_value_changed(variable_name: String) -> void:
	var save_data = _get_save_data()
	var variable = _get_save_data().get_variable(variable_name)

	for node_name in variable.get_listening_nodes():
		var node = %Panel.find_child(node_name, true, false)
		if node:
			var node_text = WidgetLayout.find_component(widget_data.get_layout().get_components(), node_name).get_metadata().get("text", "")
			var substituted_text = _substitute(node, node_text)
			node.text = substituted_text

	var logic_components = _get_logic_components(Studio.LogicStage.ACTION, Studio.LogicOption.VALUE, variable.name)

	for component in logic_components:
		handle_logic_component(component, save_data)

func _on_shop_item_unlocked(shop_item: String, save_data: SaveData) -> void:
	var logic_components = _get_logic_components(Studio.LogicStage.ACTION, Studio.LogicOption.SHOP, shop_item)

	for component in logic_components:
		handle_logic_component(component, save_data)

func handle_logic_component(component: LogicComponent, save_data: SaveData) -> void:
		var dependency = component.get_dependency()
		var dependency_metadata = component.get_dependency_metadata()

		var effect = component.get_effect()
		var effect_metadata = component.get_effect_metadata()

		var dependency_active = dependency_metadata.get("connected", false)
		var dependency_satisfied = !dependency_active
		if !dependency_satisfied:
			match dependency:
				Studio.LogicOption.VISIBILITY:
					var source = dependency_metadata.get("source")
					var current_visibility = dependency_metadata.get("current_visibility", { "text": "visible" }).get("text", "")
					var visibility_map = { "visible": true, "invisible": false }
					var node = %Panel.find_child(source, true, false)

					if node:
						dependency_satisfied = LogicFn.Dependencies.analyze_visibility(%Panel, node, visibility_map[current_visibility])
					else:
						dependency_satisfied = false
				Studio.LogicOption.VALUE:
					var variable = save_data.get_variable(dependency_metadata.get("source", ""))
					var comparator = dependency_metadata.get("comparator")
					var expected_value = dependency_metadata.get("expected_value")
					if variable == null:
						dependency_satisfied = false
					dependency_satisfied = LogicFn.Dependencies.analyze_variable(variable, comparator, expected_value)
				Studio.LogicOption.SHOP:
					var shop_item = dependency_metadata.get("source")
					var current_unlock_status = dependency_metadata.get("current_unlock_status", { "text": "locked" }).get("text", "")
					var unlock_status_map = { "unlocked": true, "locked": false }
					dependency_satisfied = LogicFn.Dependencies.analyze_shop_item(save_data.get_shop_data(), shop_item, unlock_status_map[current_unlock_status])

		if dependency_satisfied:
			match effect:
				Studio.LogicOption.VISIBILITY:
					var source = effect_metadata.get("source")
					var node = %Panel.find_child(source, true, false)
					var expected_visibility = effect_metadata.get("new_visibility", { "text": "set visible" }).get("text", "")
					var visibility_map = { "set visible": true, "set invisible": false }
					if node:
						LogicFn.Effects.set_visibility(node, visibility_map[expected_visibility])
				Studio.LogicOption.VALUE:
					var variable = save_data.get_variable(effect_metadata.get("source", ""))
					var modifier = effect_metadata.get("modifier", { "text": "+" }).get("text", "")
					var modifying_value = effect_metadata.get("modifying_value")
					if variable == null:
						return
					variable = LogicFn.Effects.modify_value(variable, modifier, modifying_value)
					save_data.update_variable(variable.name, variable)
					_save_data(save_data)
					_on_variable_value_changed(variable.name)
				Studio.LogicOption.SHOP:
					var shop_item = effect_metadata.get("source", "")
					var new_unlock_status = effect_metadata.get("new_unlock_status", { "text": "set locked" }).get("text", "")
					var unlock_status_map = { "set unlocked": true, "set locked": false }

					LogicFn.Effects.set_shop_unlocked(save_data, shop_item, unlock_status_map[new_unlock_status])
					_on_shop_item_unlocked(shop_item, _get_save_data())

###########################################
###########################################
################## Addons #################
###########################################
###########################################

func _construct_shop(components: Array[LayoutComponent]) -> void:
	var save_data = _get_save_data()

	var shop_size = widget_data.get_layout().get_metadata().get("shop_config", {}).get("size", Vector2(400, 800))
	var scene = load("res://app/utils/widget_entry.tscn").instantiate()
	scene.set_script(null)
	if shop_window == null:
		shop_window = Display.show(self, "Shop", scene, shop_size, false, func(w): w.visible = false)

	var panel = scene.find_child("Panel", true, false)
	if panel == null or !panel.has_method("mount"):
		push_error("widget_entry: shop panel renderer missing")
		return

	# Shop is a normal UI window — don't IGNORE the root or clicks fall through.
	_mount_layout(panel, "shop", save_data, Control.MOUSE_FILTER_STOP)

	var list_item_parent = VBoxContainer.new()
	list_item_parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := _find_scroll_container(panel)
	if scroll:
		scroll.add_child(list_item_parent)
	else:
		panel.add_child(list_item_parent)

	# Decorative shop chrome (labels/icons/panels) must not steal clicks from buttons.
	for child in panel.get_children():
		if child == list_item_parent:
			continue
		_filter_shop_mouse_events(child)

	var shop_list_item_components = WidgetLayout.filter_parent(components, "shop_list_item")
	var shop_list_item_size = widget_data.get_layout().get_metadata().get("shop_list_item_config", {}).get("size", Vector2(360, 64))
	var shop_data = JSON.parse_string(IO.load_file(widget_data, "shop.json"))
	var shop_items = shop_data.get("items", [])
	var shop_variable := str(shop_data.get("fund_variable", ""))
	for shop_item in shop_items:
		var list_item_panel = Panel.new()
		list_item_parent.add_child(list_item_panel)
		list_item_panel.custom_minimum_size = shop_list_item_size
		list_item_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		list_item_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		for component in shop_list_item_components:
			var wr_component = WR_COMPONENT.new(component.to_dict())
			var node: Control = panel.instantiate_component(wr_component)
			if node == null:
				continue
			list_item_panel.add_child(node)
			_apply_save_overrides(node, save_data)

			# Absolute-positioned siblings overlap; only the purchase button should catch clicks.
			if component.get_type() != "Button":
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE

			match component.get_name():
				"ListItemName":
					node.text = shop_item.get("name", "")
				"ListItemCost":
					node.text = "$%s" % int(shop_item.get("cost", 1000))
				"ListItemDescription":
					node.text = shop_item.get("description", "")
				"ListItemIcon":
					var icon_path := str(shop_item.get("icon_path", "")).trim_prefix("./")
					if !icon_path.is_empty():
						if panel.has_method("resolve_texture"):
							node.texture = panel.resolve_texture(icon_path)
						if node.texture == null and !icon_path.begins_with("res://"):
							var absolute := _package_root().path_join(icon_path)
							if FileAccess.file_exists(absolute):
								var image := Image.new()
								if image.load(absolute) == OK:
									node.texture = ImageTexture.create_from_image(image)
						elif node.texture == null and icon_path.begins_with("res://") and ResourceLoader.exists(icon_path):
							node.texture = load(icon_path)
				"ListItemPurchaseButton":
					var purchase_button := node as Button
					if purchase_button == null:
						continue
					purchase_button.mouse_filter = Control.MOUSE_FILTER_STOP
					purchase_button.z_index = maxi(purchase_button.z_index, 10)
					if save_data.get_shop_data().get("unlocked_ids", []).has(shop_item.get("id", "")):
						purchase_button.disabled = true
						purchase_button.text = "Owned"
					else:
						purchase_button.pressed.connect(
							_attempt_shop_purchase.bind(purchase_button, shop_item, shop_variable)
						)

func _find_scroll_container(root: Node) -> ScrollContainer:
	if root is ScrollContainer:
		return root as ScrollContainer
	for child in root.get_children():
		var found := _find_scroll_container(child)
		if found:
			return found
	return null

func _filter_shop_mouse_events(node: Node) -> void:
	if node is Button:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_STOP
		return
	if node is Control and !(node is ScrollContainer) and !(node is SubViewportContainer):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_filter_shop_mouse_events(child)

func _attempt_shop_purchase(button: Button, shop_item: Dictionary, shop_variable_name: String) -> void:
	var save_data = _get_save_data()
	var variable = save_data.get_variable(shop_variable_name)
	if variable == null:
		push_warning("widget_entry: shop fund variable '%s' not found" % shop_variable_name)
		return
	var current_value = variable.get_current_value()
	var cost = int(shop_item.get("cost", 1000))
	var component_id = shop_item.get("id", "")
	if variable.get_current_value() >= cost:
		current_value -= cost
		variable.set_current_value(current_value)
		save_data.update_variable(shop_variable_name, variable)
		var shop_data = save_data.get_shop_data()
		var unlocked_ids = shop_data.get("unlocked_ids", [])
		unlocked_ids.append(component_id)
		shop_data.set("unlocked_ids", unlocked_ids)
		save_data.set_shop_data(shop_data)

		button.disabled = true
		button.text = "Owned"

		var child = %Panel.find_child(shop_item.get("id", ""), true, false)
		if child:
			child.visible = true
			var component_overrides = save_data.get_component_overrides()
			var overrides = component_overrides.get(component_id, {})
			overrides.set("visible", true)
			component_overrides.set(component_id, overrides)
			save_data.set_component_overrides(component_overrides)

	_save_data(save_data)
	_on_variable_value_changed(shop_variable_name)
