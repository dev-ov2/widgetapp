class_name Display

static func show(parent: Node, title: String, scene: Node, size: Vector2, default_visible: bool, on_close_requested: Callable) -> Window:
	var ui_window = Window.new()
	ui_window.set_size(size)
	ui_window.set_min_size(size)
	#ui_window.set_ime_position()
	# ui_window.
	ui_window.title = title
	ui_window.borderless = false
	ui_window.close_requested.connect(func(): on_close_requested.call(ui_window))
	center(ui_window, size)
	if default_visible:
		ui_window.show()
	else:
		ui_window.hide()
	parent.add_child(ui_window)
	
	ui_window.add_child(scene)
	return ui_window

static func center(window: Window, size: Vector2 = Vector2.INF) -> void:
	var screen := DisplayServer.get_primary_screen()
	var origin := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var win_size := DisplayServer.window_get_size(window.get_window_id()) # client size
	
	var pos_size = size if size != Vector2.INF else win_size
	@warning_ignore("integer_division")
	var pos := Vector2i(
		origin.x + (screen_size.x - pos_size.x) / 2,
		origin.y + (screen_size.y - pos_size.y) / 2
	)
	
	window.set_position(pos)
	#DisplayServer.window_set_position(pos, window.get_window_id())

static func show_widget(parent: Node, scene: Node, size: Vector2, position: Vector2 = Vector2.INF) -> Window:
	var ui_window = Window.new()
	ui_window.set_size(size)
	ui_window.unfocusable = true
	ui_window.set_min_size(size)
	ui_window.always_on_top = true
	ui_window.borderless = true
	ui_window.transparent_bg = true
	ui_window.transparent = true
	ui_window.force_native = true
	parent.add_child(ui_window)

	ui_window.add_child(scene)
	ui_window.show()
	if position == Vector2.INF or not position.is_finite():
		center(ui_window)
	else:
		ui_window.position = Vector2i(position)
	return ui_window
