extends Control

var active_widget_metadata: Array[ActiveWidgetMetadata]

func populate_list(
	user_widget_metadata: Array[WidgetMetadata],
	new_active_widget_metadata: Array[ActiveWidgetMetadata],
	on_enabled: Callable,
	on_settings_changed: Callable = Callable(),
) -> void:
	active_widget_metadata = new_active_widget_metadata
	for metadata in user_widget_metadata:
		var widget_item_scene = load("res://app/widget_selection/widget.tscn").instantiate()
		%WidgetList.add_child(widget_item_scene)
		widget_item_scene.set_data(metadata, active_widget_metadata, on_enabled, on_settings_changed)
		
		if metadata.get_id() != user_widget_metadata[user_widget_metadata.size() - 1].get_id():
			var node = HSeparator.new()
			%WidgetList.add_child(node)
