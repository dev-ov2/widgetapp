extends Control

enum WindowType { WidgetSelection, Studio, Widget }
var widget_selector_active: bool
var focus_mode_enabled: bool = false
var widget_selection_window: Window

var active_widgets: Dictionary

var tray_icon_supported = (
		DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR)
		and not Engine.is_embedded_in_editor()
	)

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	var win = get_window()
	win.title = "Widget app"
	win.borderless = false
	win.transparent = false
	win.transparent_bg = false
	win.min_size = Vector2i(840, 480)
	win.size = Vector2i(960, 560)
	Display.center(win)
	
	%LandingPage.action_pressed.connect(_on_landing_action_pressed)
	win.close_requested.connect(_close_landing)
	
	var widget_metadata = IO.get_user_widgets()
	var active_widget_metadata = IO.get_active_widgets()
	
	for active_metadata in active_widget_metadata:
		if active_metadata.is_active():
			var active_widget_window = _display_widget(active_metadata, widget_metadata)
			active_widgets.set(active_metadata.get_id(), active_widget_window)
	
	if _should_start_in_tray():
		_minimize_to_tray()
	else:
		_show_landing()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_landing()

func _on_landing_action_pressed(action: LandingPage.Action) -> void:
	match action:
		LandingPage.Action.WIDGETS:
			_open_widget_selection()
		LandingPage.Action.MARKETPLACE:
			_open_marketplace()
		LandingPage.Action.STUDIO:
			_open_studio()

func _should_start_in_tray() -> bool:
	return AppSettings.get_hide_on_startup() and tray_icon_supported and not OS.has_feature("editor")

func _close_landing() -> void:
	if OS.has_feature("editor") or Engine.is_embedded_in_editor() or not tray_icon_supported:
		get_tree().quit()
	else:
		_minimize_to_tray()

func _minimize_to_tray() -> void:
	var win = get_window()
	win.mode = Window.MODE_MINIMIZED
	win.unfocusable = true

func _show_landing() -> void:
	var win = get_window()
	win.unfocusable = false
	win.mode = Window.MODE_WINDOWED
	win.grab_focus()

func update_window_drag_status(draggable: bool) -> void:
	for key in active_widgets.keys():
		var entry = active_widgets[key].get_child(0)
		entry.handle_passthrough(draggable)
		entry.set_edit_border(draggable)

func bring_widget_selector_to_front() -> void:
	if widget_selection_window == null or !is_instance_valid(widget_selection_window):
		return
	widget_selection_window.always_on_top = true
	widget_selection_window.move_to_foreground()
	widget_selection_window.grab_focus()

func _set_focus_mode(enabled: bool) -> void:
	focus_mode_enabled = enabled
	var menu: PopupMenu = %PopupMenu
	if menu:
		var idx := menu.get_item_index(5)
		if idx >= 0:
			menu.set_item_checked(idx, enabled)
	
	for key in active_widgets.keys():
		_apply_focus_mode_to_widget(active_widgets[key], enabled)

func _apply_focus_mode_to_widget(window: Window, enabled: bool) -> void:
	window.visible = !enabled
	var entry = window.get_child(0)
	if entry and entry.has_method("set_widget_focus_mode"):
		entry.set_widget_focus_mode(enabled)

func _open_widget_selection() -> void:
	var user_widget_metadata = IO.get_user_widgets()
	var active_widget_metadata = IO.get_active_widgets()
	var widget_selection_scene = load("res://app/widget_selection/widget_selection.tscn").instantiate()
	widget_selection_window = Display.show(self, "Choose Widgets", widget_selection_scene, Vector2(400, 800), true, _on_window_closed.bind(WindowType.WidgetSelection, widget_selection_scene))
	widget_selection_window.always_on_top = true
	widget_selection_scene.populate_list(
		user_widget_metadata,
		active_widget_metadata,
		on_enabled.bind(user_widget_metadata),
		_on_widget_settings_changed,
	)
	widget_selector_active = true
	update_window_drag_status(widget_selector_active)
	bring_widget_selector_to_front()

func _open_marketplace() -> void:
	OS.shell_open("https://widgette.app")

func _open_studio() -> void:
	var studio_scene = load("res://studio/wizard.tscn").instantiate()
	var window = Display.show(get_node("/root"), "Widgetry Studio", studio_scene, Vector2(1152, 648), true, _on_window_closed.bind(WindowType.Studio, studio_scene))
	studio_scene.window = window

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			_open_widget_selection()
		1:
			_open_marketplace()
		2:
			_open_studio()
		3: # Show Home
			_show_landing()
		4: # Quit
			get_tree().quit()
		5: # Focus Mode
			_set_focus_mode(not focus_mode_enabled)

func _on_window_closed(window: Window, window_type: WindowType, _scene: Node) -> void:
	match window_type:
		WindowType.WidgetSelection:
			widget_selector_active = false
			widget_selection_window = null
			update_window_drag_status(widget_selector_active)
	
	window.queue_free()

func _display_widget(active_metadata: ActiveWidgetMetadata, widget_metadata: Array[WidgetMetadata]) -> Window:
	var metadata = WidgetMetadata.get_metadata(widget_metadata, active_metadata.get_id())
	var widget_data = IO.get_widget_data(metadata)
	var scene = load("res://app/utils/widget_entry.tscn").instantiate()
	var widget_size = widget_data.get_layout().get_metadata().get("main_config", {}).get("size", Vector2(400, 200))
	var window = Display.show_widget(self, scene, widget_size, active_metadata.get_position())
	window.set_meta("base_size", widget_size)

	scene.set_widget_data(widget_data)
	scene.handle_passthrough(widget_selector_active)
	scene.draggable = widget_selector_active
	
	scene.set_edit_border(widget_selector_active)
	scene.drag_completed.connect(_on_drag_completed.bind(window, active_metadata))
	_apply_widget_settings(window, active_metadata)
	
	if focus_mode_enabled:
		_apply_focus_mode_to_widget(window, true)

	return window

func _apply_widget_settings(window: Window, active_metadata: ActiveWidgetMetadata) -> void:
	var base_size: Vector2 = window.get_meta("base_size", Vector2(400, 200))
	var scale_value := active_metadata.get_scale()
	var target_size := Vector2(
		maxi(1, int(round(base_size.x * scale_value.x))),
		maxi(1, int(round(base_size.y * scale_value.y))),
	)
	window.size = Vector2i(target_size)
	window.min_size = Vector2i(target_size)
	
	var entry = window.get_child(0)
	if entry == null:
		return
	if entry is Control:
		var control := entry as Control
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.anchor_right = 0.0
		control.anchor_bottom = 0.0
		control.position = Vector2.ZERO
		if active_metadata.is_dedicated_scene():
			control.scale = Vector2.ONE
			control.size = target_size
			_resize_layout_to_size(control, base_size, target_size)
		else:
			control.size = base_size
			control.scale = scale_value
			_restore_layout_design_size(control)
	if entry.has_method("apply_display_settings"):
		entry.apply_display_settings(active_metadata.get_opacity(), active_metadata.get_volume())

func _resize_layout_to_size(root: Control, base_size: Vector2, target_size: Vector2) -> void:
	var ratio := Vector2(
		target_size.x / maxf(1.0, base_size.x),
		target_size.y / maxf(1.0, base_size.y),
	)
	var panel = root.find_child("Panel", true, false)
	if panel == null:
		return
	for child in panel.get_children():
		if !(child is Control):
			continue
		var control := child as Control
		if !control.has_meta("_design_size"):
			control.set_meta("_design_size", control.size)
			control.set_meta("_design_pos", control.position)
		control.size = control.get_meta("_design_size") * ratio
		control.position = control.get_meta("_design_pos") * ratio
	_sync_scene_viewports(root)

func _restore_layout_design_size(root: Control) -> void:
	var panel = root.find_child("Panel", true, false)
	if panel == null:
		return
	for child in panel.get_children():
		if !(child is Control):
			continue
		var control := child as Control
		if control.has_meta("_design_size"):
			control.size = control.get_meta("_design_size")
			control.position = control.get_meta("_design_pos")
	_sync_scene_viewports(root)

func _sync_scene_viewports(root: Node) -> void:
	if root is SubViewportContainer:
		var container := root as SubViewportContainer
		var viewport := container.find_child("SubViewport", false, false)
		if viewport is SubViewport:
			(viewport as SubViewport).size = Vector2i(maxi(1, int(round(container.size.x))), maxi(1, int(round(container.size.y))))
	for child in root.get_children():
		_sync_scene_viewports(child)

func _on_widget_settings_changed(active_metadata: ActiveWidgetMetadata) -> void:
	var window: Window = active_widgets.get(active_metadata.get_id())
	if window == null or not is_instance_valid(window):
		return
	_apply_widget_settings(window, active_metadata)
	bring_widget_selector_to_front()

func on_enabled(enabled: bool, metadata: ActiveWidgetMetadata, widget_metadata: Array[WidgetMetadata]) -> void:
	if enabled:
		var window = _display_widget(metadata, widget_metadata)
		active_widgets.set(metadata.get_id(), window)
	else:
		var window = active_widgets.get(metadata.get_id())
		window.queue_free()
		
		active_widgets.erase(metadata.get_id())
	bring_widget_selector_to_front()

func _on_drag_completed(window: Window, active_metadata: ActiveWidgetMetadata) -> void:
	var active_widget_metadata = IO.get_active_widgets()
	
	active_metadata.set_position(Vector2(window.position))
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
	bring_widget_selector_to_front()
