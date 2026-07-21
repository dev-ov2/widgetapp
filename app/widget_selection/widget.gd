extends VBoxContainer

var widget_metadata: WidgetMetadata
var active_metadata: ActiveWidgetMetadata
var active_widget_metadata: Array[ActiveWidgetMetadata]
var on_settings_changed: Callable
var base_size: Vector2 = Vector2(400, 200)
var updating_ui: bool = false
var _listening_for_hotkey: bool = false
var _advanced_open: bool = false

const _MODIFIER_KEYS := [
	KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META,
	KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK,
]

func set_data(metadata: WidgetMetadata, new_active_widget_metadata: Array[ActiveWidgetMetadata], on_enabled: Callable, new_on_settings_changed: Callable = Callable()) -> void:
	widget_metadata = metadata
	active_widget_metadata = new_active_widget_metadata
	on_settings_changed = new_on_settings_changed
	active_metadata = ActiveWidgetMetadata.get_metadata(active_widget_metadata, metadata.get_id())
	
	var widget_data = IO.get_widget_data(metadata)
	if widget_data:
		base_size = widget_data.get_layout().get_metadata().get("main_config", {}).get("size", Vector2(400, 200))
	
	%ID.text = metadata.get_id()
	var texture_path = metadata.get_absolute_path().path_join(metadata.get_icon_path())
	if texture_path:
		var image = Image.load_from_file(texture_path)
		var texture = ImageTexture.create_from_image(image)
		%Icon.texture = texture
		%Icon.size = Vector2(100, 100)
		%Icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		%Icon.texture = load("res://widget_app2.png")
	
	%Name.text = metadata.get_name()
	%Author.text = metadata.get_author()
	%Version.text = metadata.get_version()
	%Description.text = metadata.get_description()
	%Enabled.button_pressed = active_metadata.is_active()
	(%Enabled as CheckButton).toggled.connect(_on_enabled_changed.bind(on_enabled))
	
	%ChipContainer.populate_tags(metadata.get_tag_array())
	
	%ScaleSlider.value_changed.connect(_on_scale_changed)
	%WidthLineEdit.text_submitted.connect(_on_size_changed.bind("x"))
	%WidthLineEdit.focus_exited.connect(func(): _on_size_changed(%WidthLineEdit.text, "x"))
	%HeightLineEdit.text_submitted.connect(_on_size_changed.bind("y"))
	%HeightLineEdit.focus_exited.connect(func(): _on_size_changed(%HeightLineEdit.text, "y"))
	%DedicatedSceneCheck.toggled.connect(_on_dedicated_scene_toggled)
	%GameModeCheck.toggled.connect(_on_game_mode_toggled)
	%HotkeyButton.pressed.connect(_on_hotkey_button_pressed)
	%VisibleWhenNotFocusedCheck.toggled.connect(_on_visible_when_not_focused_toggled)
	%OpacitySlider.value_changed.connect(_on_opacity_changed)
	%VolumeSlider.value_changed.connect(_on_volume_changed)
	%AdvancedToggle.pressed.connect(_on_advanced_toggled)
	_update_settings_ui()

func _input(event: InputEvent) -> void:
	if !_listening_for_hotkey:
		return
	
	if !(event is InputEventKey):
		return
	
	var key_event := event as InputEventKey
	
	if !key_event.pressed or key_event.echo:
		return
	
	if key_event.keycode == KEY_ESCAPE:
		_listening_for_hotkey = false
	
		_update_hotkey_button_text()
		get_viewport().set_input_as_handled()
	
		return
	
	if key_event.keycode in _MODIFIER_KEYS:
		return

	var key := int(key_event.physical_keycode)
	
	if key == KEY_NONE:
		key = int(key_event.keycode)
	if key <= 0:
		return

	_listening_for_hotkey = false
	
	active_metadata.get_game_mode_settings().set_hotkey(
		{
			"key": key,
			"ctrl": key_event.ctrl_pressed,
			"alt": key_event.alt_pressed,
			"shift": key_event.shift_pressed,
			"meta": key_event.meta_pressed,
		}
	)
	
	_update_hotkey_button_text()
	_save_settings()
	get_viewport().set_input_as_handled()

func _update_settings_ui() -> void:
	updating_ui = true
	var scale = active_metadata.get_scale()
	var uniform = (scale.x + scale.y) * 0.5
	%ScaleSlider.value = uniform
	%ScaleSlider.editable = !active_metadata.is_dedicated_scene()

	%ScaleValue.text = "%.0f%%" % (uniform * 100.0)

	%WidthLineEdit.text = str(maxi(1, int(round(base_size.x * scale.x))))
	%HeightLineEdit.text = str(maxi(1, int(round(base_size.y * scale.y))))
	%OpacitySlider.value = active_metadata.get_opacity()
	%OpacityValue.text = "%.0f%%" % (active_metadata.get_opacity() * 100.0)
	%VolumeSlider.value = active_metadata.get_volume()
	%VolumeValue.text = "%.0f%%" % (active_metadata.get_volume() * 100.0)
	updating_ui = false

	# advanced settings
	%DedicatedSceneCheck.button_pressed = active_metadata.is_dedicated_scene()

	var game_mode := active_metadata.get_game_mode_settings()
	
	%GameModeCheck.button_pressed = game_mode.get_enabled()
	%GameModeOptions.visible = game_mode.get_enabled()
	%VisibleWhenNotFocusedCheck.button_pressed = game_mode.get_visible_when_not_focused()
	
	_update_hotkey_button_text()
	_update_advanced_toggle_text()


func _update_hotkey_button_text() -> void:
	if _listening_for_hotkey:
		%HotkeyButton.text = "Press a key combo..."
		return
	
	var label := active_metadata.get_game_mode_settings().get_hotkey_label()
	%HotkeyButton.text = label if !label.is_empty() else "Click to set"

func _update_advanced_toggle_text() -> void:
	%AdvancedToggle.text = "%s Advanced settings" % ("▾" if _advanced_open else "▸")
	%AdvancedBody.visible = _advanced_open

func _save_settings() -> void:
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
	if on_settings_changed.is_valid():
		on_settings_changed.call(active_metadata)

func _on_advanced_toggled() -> void:
	_advanced_open = !_advanced_open
	_update_advanced_toggle_text()

func _on_enabled_changed(enabled: bool, on_enabled: Callable) -> void:
	active_metadata.set_active(enabled)
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
	on_enabled.call(enabled, active_metadata)

func _on_scale_changed(value: float) -> void:
	if updating_ui:
		return
	active_metadata.set_scale(Vector2(value, value))
	_update_settings_ui()
	_save_settings()

func _on_size_changed(new_text: String, axis: String) -> void:
	if updating_ui:
		return
	if !new_text.is_valid_float():
		_update_settings_ui()
		return
	
	var scale = active_metadata.get_scale()
	if axis == "x":
		scale.x = maxf(1.0, float(new_text)) / maxf(1.0, base_size.x)
	else:
		scale.y = maxf(1.0, float(new_text)) / maxf(1.0, base_size.y)
	active_metadata.set_scale(scale)
	_update_settings_ui()
	_save_settings()

func _on_dedicated_scene_toggled(pressed: bool) -> void:
	if updating_ui:
		return
	active_metadata.set_dedicated_scene(pressed)
	_update_settings_ui()
	_save_settings()

func _on_game_mode_toggled(pressed: bool) -> void:
	if updating_ui:
		return
	
	active_metadata.get_game_mode_settings().set_enabled(pressed)
	
	if !pressed:
		_listening_for_hotkey = false
	
	_update_settings_ui()
	_save_settings()

func _on_hotkey_button_pressed() -> void:
	_listening_for_hotkey = true
	_update_hotkey_button_text()
	%HotkeyButton.grab_focus()

func _on_visible_when_not_focused_toggled(pressed: bool) -> void:
	if updating_ui:
		return
	
	active_metadata.get_game_mode_settings().set_visible_when_not_focused(pressed)
	_update_settings_ui()
	_save_settings()

func _on_opacity_changed(value: float) -> void:
	if updating_ui:
		return
	active_metadata.set_opacity(value)
	_update_settings_ui()
	_save_settings()

func _on_volume_changed(value: float) -> void:
	if updating_ui:
		return
	active_metadata.set_volume(value)
	_update_settings_ui()
	_save_settings()
