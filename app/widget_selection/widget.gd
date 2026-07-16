extends VBoxContainer

var widget_metadata: WidgetMetadata
var active_metadata: ActiveWidgetMetadata
var active_widget_metadata: Array[ActiveWidgetMetadata]
var on_settings_changed: Callable
var base_size: Vector2 = Vector2(400, 200)
var updating_ui: bool = false

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
	%OpacitySlider.value_changed.connect(_on_opacity_changed)
	%VolumeSlider.value_changed.connect(_on_volume_changed)
	_update_settings_ui()

func _update_settings_ui() -> void:
	updating_ui = true
	var scale = active_metadata.get_scale()
	var uniform = (scale.x + scale.y) * 0.5
	%ScaleSlider.value = uniform
	%ScaleValue.text = "%.0f%%" % (uniform * 100.0)
	%WidthLineEdit.text = str(maxi(1, int(round(base_size.x * scale.x))))
	%HeightLineEdit.text = str(maxi(1, int(round(base_size.y * scale.y))))
	%DedicatedSceneCheck.button_pressed = active_metadata.is_dedicated_scene()
	%ScaleSlider.editable = !active_metadata.is_dedicated_scene()
	%OpacitySlider.value = active_metadata.get_opacity()
	%OpacityValue.text = "%.0f%%" % (active_metadata.get_opacity() * 100.0)
	%VolumeSlider.value = active_metadata.get_volume()
	%VolumeValue.text = "%.0f%%" % (active_metadata.get_volume() * 100.0)
	updating_ui = false

func _save_settings() -> void:
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
	if on_settings_changed.is_valid():
		on_settings_changed.call(active_metadata)

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
