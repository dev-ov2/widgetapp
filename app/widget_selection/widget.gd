extends VBoxContainer

var widget_metadata: WidgetMetadata
var active_metadata: ActiveWidgetMetadata

func set_data(metadata: WidgetMetadata, active_widget_metadata: Array[ActiveWidgetMetadata], on_enabled) -> void:
	widget_metadata = metadata
	active_metadata = ActiveWidgetMetadata.get_metadata(active_widget_metadata, metadata.get_id())
	
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
	(%Enabled as CheckButton).toggled.connect(_on_enabled_changed.bind(active_widget_metadata, on_enabled))
	
	%ChipContainer.populate_tags(metadata.get_tag_array())

func _on_enabled_changed(enabled: bool, active_widget_metadata: Array[ActiveWidgetMetadata], on_enabled: Callable) -> void:
	active_metadata.set_active(enabled)
	ActiveWidgetMetadata.update_metadata(active_widget_metadata, active_metadata)
	IO.set_active_widgets(active_widget_metadata)
	on_enabled.call(enabled, active_metadata)
