extends Control

enum WindowType { WidgetSelection, Studio, Widget }
var widget_selector_active: bool

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
		active_widgets[key].get_child(0).handle_passthrough(draggable)

func _open_widget_selection() -> void:
	var user_widget_metadata = IO.get_user_widgets()
	var active_widget_metadata = IO.get_active_widgets()
	var widget_selection_scene = load("res://app/widget_selection/widget_selection.tscn").instantiate()
	Display.show(self, "Choose Widgets", widget_selection_scene, Vector2(400, 800), true, _on_window_closed.bind(WindowType.WidgetSelection, widget_selection_scene))
	widget_selection_scene.populate_list(user_widget_metadata, active_widget_metadata, on_enabled.bind(user_widget_metadata))
	widget_selector_active = true
	update_window_drag_status(widget_selector_active)

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
		3: # Settings — show landing / prefs
			_show_landing()
		4: # Quit
			get_tree().quit()

func _on_window_closed(window: Window, window_type: WindowType, _scene: Node) -> void:
	match window_type:
		WindowType.WidgetSelection:
			widget_selector_active = false
			update_window_drag_status(widget_selector_active)
	
	window.queue_free()

func _display_widget(active_metadata: ActiveWidgetMetadata, widget_metadata: Array[WidgetMetadata]) -> Window:
	var metadata = WidgetMetadata.get_metadata(widget_metadata, active_metadata.get_id())
	var widget_data = IO.get_widget_data(metadata)
	var scene = load("res://app/utils/widget_entry.tscn").instantiate()
	var widget_size = widget_data.get_layout().get_metadata().get("main_config", {}).get("size", Vector2(400, 200))
	var window = Display.show_widget(self, scene, widget_size, active_metadata.get_position())

	scene.set_widget_data(widget_data)
	scene.handle_passthrough(widget_selector_active)
	scene.draggable = widget_selector_active
	scene.drag_completed.connect(_on_drag_completed.bind(window, active_metadata))

	return window

func on_enabled(enabled: bool, metadata: ActiveWidgetMetadata, widget_metadata: Array[WidgetMetadata]) -> void:
	if enabled:
		var window = _display_widget(metadata, widget_metadata)
		active_widgets.set(metadata.get_id(), window)
	else:
		var window = active_widgets.get(metadata.get_id())
		window.queue_free()
		
		active_widgets.erase(metadata.get_id())

func _on_drag_completed(window: Window, active_metadata: ActiveWidgetMetadata) -> void:
	var active_widget_metadata = IO.get_active_widgets()
	
	active_metadata.set_position(window.position)
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
