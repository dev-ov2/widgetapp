class_name WidgetGameModeController
extends Node

signal state_changed

var _widget_entry: Control

var _passthrough_node: Node

var _window_focus_controller: Node

var _settings := WidgetGameModeSettings.new()

var _focused := false
var _focus_mode := false

var _chord_id := ""

var _scene_input_snapshot: Array[Dictionary] = []

var _focus_grace_until_ms := 0
var _hotkey_was_down := false
var _hotkey_stroke_handled := false

var _input_capture_active := false

var _pack_input_map := WidgetPackInputMap.new()

func setup(widget_entry: Control, passthrough_node: Node, window_focus_controller: Node) -> void:
	_widget_entry = widget_entry
	_passthrough_node = passthrough_node
	_window_focus_controller = window_focus_controller
	
	var window := _get_window()
	if window != null and _window_focus_controller != null:
		_window_focus_controller.initialize(window)
	
		if !window.focus_exited.is_connected(_on_window_focus_exited):
			window.focus_exited.connect(_on_window_focus_exited)
	
	if !GlobalKeyBridge.ChordPressed.is_connected(_on_chord_pressed):
		GlobalKeyBridge.ChordPressed.connect(_on_chord_pressed)
	
	if !GlobalKeyBridge.GlobalMousePressed.is_connected(_on_global_mouse_pressed):
		GlobalKeyBridge.GlobalMousePressed.connect(_on_global_mouse_pressed)

func apply_settings(
	settings: WidgetGameModeSettings,
	widget_id: String,
	zip_paths: Array[String],
) -> void:
	var was_active := _is_game_mode_active()
	var was_focused := _focused
	
	_clear_chord()
	_settings = WidgetGameModeSettings.new(settings.to_dict())
	_pack_input_map.configure(zip_paths)

	if !_is_game_mode_active():
		if was_active:
			set_focused(false)
			_restore_scene_input()
		else:
			apply_passthrough(false)
			state_changed.emit()
		return

	if !was_active:
		_snapshot_scene_input()

	if !widget_id.is_empty():
		_chord_id = "game_focus_%s" % widget_id
		GlobalKeyBridge.register_chord(
			_chord_id,
			_settings.key,
			_settings.ctrl,
			_settings.alt,
			_settings.shift,
			_settings.meta,
		)

	set_focused(was_focused)

func set_focused(enabled: bool) -> void:
	_focused = enabled and _is_game_mode_active()
	
	var window := _get_window()
	if window == null:
		state_changed.emit()
		return
	
	if _focused:
		_focus_grace_until_ms = Time.get_ticks_msec() + 500
		_hotkey_was_down = _is_hotkey_down()
		_hotkey_stroke_handled = _hotkey_was_down
		set_process(true)

		window.unfocusable = false
		window.mouse_passthrough = false
		window.always_on_top = true
		window.show()
		
		_widget_entry.show()
		_set_scene_input_enabled(true)
		_set_widget_mouse_capture(true)
		_set_passthrough(true, false)
		_set_input_capture(true)
		_pack_input_map.set_active(true)
		
		call_deferred("_capture_os_focus")
	
	else:
		_hotkey_was_down = _is_hotkey_down()
		_hotkey_stroke_handled = _hotkey_was_down
		set_process(_hotkey_was_down)
		
		_set_input_capture(false)
		_pack_input_map.set_active(false)
		_set_widget_mouse_capture(false)
		_set_scene_input_enabled(false)
		_set_passthrough(false, true)

		if _is_game_mode_active() and !_settings.get_visible_when_not_focused():
			window.unfocusable = true
			_widget_entry.hide()
			window.hide()
		
		else:
			if !_focus_mode:
				window.show()
				_widget_entry.show()
		
			window.unfocusable = true

		call_deferred("_release_os_focus")
	
	state_changed.emit()

func set_focus_mode(enabled: bool) -> void:
	if _focus_mode == enabled:
		return
	
	_focus_mode = enabled
	if _focus_mode and _focused:
		set_focused(false)

func apply_passthrough(draggable: bool) -> void:
	if _focus_mode or _passthrough_node == null:
		return
	
	if draggable:
		_set_passthrough(true, false)
	
		if _is_game_mode_active() and !_focused and !_settings.get_visible_when_not_focused():
			var window := _get_window()
			if window:
				window.show()
				_widget_entry.show()
		return
	
	if _is_game_mode_active() and !_focused:
		_set_passthrough(false, true)
		return
	
	if _focused:
		_set_passthrough(true, false)
		return
	
	_set_passthrough(false, false)

func is_focused() -> bool:
	return _focused

func is_suspended() -> bool:
	return _is_game_mode_active() and !_focused

func _is_game_mode_active() -> bool:
	return _settings.get_enabled() and _settings.key > 0

func _set_input_capture(enabled: bool) -> void:
	if enabled and !_input_capture_active:
		GlobalKeyBridge.push_input_capture()
		_input_capture_active = true
	
	elif !enabled and _input_capture_active:
		GlobalKeyBridge.pop_input_capture()
		_input_capture_active = false

func _set_widget_mouse_capture(enabled: bool) -> void:
	_widget_entry.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS
	
	var panel = _widget_entry.get_node_or_null("Panel")
	if panel is Control:
		(panel as Control).mouse_filter = \
			Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _set_passthrough(accept_all_input: bool, force_passthrough: bool) -> void:
	if _passthrough_node == null:
		return
	
	_passthrough_node.set_accept_all_input(accept_all_input)
	_passthrough_node.set_force_passthrough(force_passthrough)

func _capture_os_focus() -> void:
	if _focused and _window_focus_controller != null:
		_window_focus_controller.capture_focus()

func _release_os_focus() -> void:
	if _window_focus_controller != null:
		_window_focus_controller.release_focus()

func _process(_delta: float) -> void:
	if !_is_game_mode_active():
		set_process(false)
		return
	
	var hotkey_down := _is_hotkey_down()
	if _focused and hotkey_down and !_hotkey_was_down and Time.get_ticks_msec() >= _focus_grace_until_ms:
		_hotkey_stroke_handled = true
		set_focused(false)

	elif !_focused and !hotkey_down:
		set_process(false)

	if !hotkey_down:
		_hotkey_stroke_handled = false

	_hotkey_was_down = hotkey_down

func _is_hotkey_down() -> bool:
	if !Input.is_physical_key_pressed(_settings.key as Key):
		return false
	return Input.is_key_pressed(KEY_CTRL) == _settings.ctrl \
		and Input.is_key_pressed(KEY_ALT) == _settings.alt \
		and Input.is_key_pressed(KEY_SHIFT) == _settings.shift \
		and Input.is_key_pressed(KEY_META) == _settings.meta

func _on_window_focus_exited() -> void:
	if !_is_game_mode_active() or !_focused:
		return
	
	if Time.get_ticks_msec() < _focus_grace_until_ms:
		return
	
	set_focused(false)

func _on_global_mouse_pressed(x: int, y: int) -> void:
	if !_focused or Time.get_ticks_msec() < _focus_grace_until_ms:
		return
	
	var window := _get_window()
	if window == null:
		return
	
	var bounds := Rect2i(window.position, window.size)
	if bounds.has_point(Vector2i(x, y)):
		return
	
	set_focused(false)

func _on_chord_pressed(chord_id: String) -> void:
	if !_is_game_mode_active() or chord_id.is_empty() or chord_id != _chord_id:
		return

	if _hotkey_stroke_handled:
		return
	
	_hotkey_stroke_handled = true
	set_focused(!_focused)

func _clear_chord() -> void:
	if _chord_id.is_empty():
		return
	
	GlobalKeyBridge.unregister_chord(_chord_id)
	_chord_id = ""

func _set_scene_input_enabled(enabled: bool) -> void:
	_configure_scene_input(_widget_entry, enabled)

func _configure_scene_input(node: Node, enabled: bool) -> void:
	if node is SubViewport:
		var viewport := node as SubViewport
		viewport.handle_input_locally = enabled
		viewport.gui_disable_input = !enabled
	
	if node is SubViewportContainer:
		(node as SubViewportContainer).mouse_filter = \
			Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	
	for child in node.get_children():
		_configure_scene_input(child, enabled)

func _snapshot_scene_input() -> void:
	_scene_input_snapshot.clear()
	_capture_scene_input(_widget_entry)

func _capture_scene_input(node: Node) -> void:
	if node is SubViewport:
		_scene_input_snapshot.append({
			"node": node,
			"handle_input_locally": (node as SubViewport).handle_input_locally,
			"gui_disable_input": (node as SubViewport).gui_disable_input,
		})
	
	if node is SubViewportContainer:
		_scene_input_snapshot.append({
			"node": node,
			"mouse_filter": (node as SubViewportContainer).mouse_filter,
		})
	
	for child in node.get_children():
	
		_capture_scene_input(child)

func _restore_scene_input() -> void:
	for entry in _scene_input_snapshot:
		var node = entry["node"]
	
		if !is_instance_valid(node):
			continue
	
		if node is SubViewport:
			(node as SubViewport).handle_input_locally = entry["handle_input_locally"]
			(node as SubViewport).gui_disable_input = entry["gui_disable_input"]
	
		if node is SubViewportContainer:
			(node as SubViewportContainer).mouse_filter = entry["mouse_filter"]
	
	_scene_input_snapshot.clear()

func _get_window() -> Window:
	if _widget_entry == null:
		return null
	
	return _widget_entry.get_parent() as Window

func _exit_tree() -> void:
	_restore_scene_input()
	_pack_input_map.set_active(false)
	_set_input_capture(false)
	_clear_chord()
	
	if GlobalKeyBridge.ChordPressed.is_connected(_on_chord_pressed):
		GlobalKeyBridge.ChordPressed.disconnect(_on_chord_pressed)
	
	if GlobalKeyBridge.GlobalMousePressed.is_connected(_on_global_mouse_pressed):
		GlobalKeyBridge.GlobalMousePressed.disconnect(_on_global_mouse_pressed)
