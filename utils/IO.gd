class_name IO

static func convert_dict(metadata: Dictionary) -> Dictionary:
	# var vec_keys = metadata.keys().filter(func(k): return metadata[k] is Vector2)
	for key in metadata.keys():
		if metadata[key] is Vector2:
			var vector = metadata.get(key, Vector2.ZERO)
			metadata.set(key, {"type": "tuple", "value": [vector.x, vector.y] })
		elif metadata[key] is Dictionary:
			metadata[key] = convert_dict(metadata[key])
	
	return metadata

static func parse_dict(metadata: Dictionary) -> Dictionary:
	for key in metadata.keys():
		if metadata[key] is Dictionary and metadata[key].has("type") and metadata[key]["type"] == "tuple" and metadata[key].has("value"):
			var value = metadata[key]["value"]
			if value is Array and value.size() == 2:
				metadata.set(key, Vector2(value[0], value[1]))
		elif metadata[key] is Dictionary:
			metadata[key] = parse_dict(metadata[key])
	
	return metadata

static func get_user_widgets() -> Array[WidgetMetadata]:
	var user_widgets: Array[WidgetMetadata] = []
	var user_widgets_dir = "user://widgets"
	if DirAccess.dir_exists_absolute(user_widgets_dir):
		var dir = DirAccess.open(user_widgets_dir)
		if dir != null:
			dir.list_dir_begin()
			var has_next = true
			while has_next:
				var dir_name = dir.get_next()
				if dir_name.is_empty():
					has_next = false
					break
				if dir_name == "." or dir_name == "..":
					continue
				var subdir = user_widgets_dir + "/" + dir_name
				if DirAccess.dir_exists_absolute(subdir):
					var subdir_access = DirAccess.open(subdir)
					if subdir_access != null:
						var metadata_path = subdir + "/metadata.json"
						if FileAccess.file_exists(metadata_path):
							var metadata_file = FileAccess.open(metadata_path, FileAccess.READ)
							if metadata_file != null:
								var metadata_json = metadata_file.get_as_text()
								var metadata = JSON.parse_string(metadata_json)
								if metadata != null:
									var widget_metadata = WidgetMetadata.new(metadata)
									widget_metadata.set_absolute_path(subdir)
									user_widgets.append(widget_metadata)
	return user_widgets

static func get_active_widgets() -> Array[ActiveWidgetMetadata]:
	var active_widgets: Array[ActiveWidgetMetadata] = []
	var config_file = "user://config/widgets.json"
	if FileAccess.file_exists(config_file):
		var file = FileAccess.open(config_file, FileAccess.READ)
		if file != null:
			var json = file.get_as_text()
			var arr = JSON.parse_string(json)
			for widget_metadata in arr:
				active_widgets.append(ActiveWidgetMetadata.new(widget_metadata))
	return active_widgets

static func set_active_widgets(active_widgets: Array[ActiveWidgetMetadata]) -> void:
	var config_file = "user://config/widgets.json"
	if not FileAccess.file_exists(config_file):
		var dir = DirAccess.open("user://config")
		if dir == null:
			DirAccess.make_dir_absolute("user://config")
	var file = FileAccess.open(config_file, FileAccess.WRITE)
	if file != null:
		var arr = active_widgets.map(func(widget_metadata: ActiveWidgetMetadata) -> Dictionary:
			return widget_metadata.to_dict()
		)
		file.store_string(JSON.stringify(arr))
		file.close()

static func get_widget_data(metadata: WidgetMetadata) -> WidgetData:
	var absolute_path = metadata.get_absolute_path()
	if DirAccess.dir_exists_absolute(absolute_path):
		var layout
		var layout_path = absolute_path + "/layout.json"

		if FileAccess.file_exists(layout_path):
			var layout_file = FileAccess.open(layout_path, FileAccess.READ)
			if layout_file != null:
				var layout_json = layout_file.get_as_text()
				var parsed = JSON.parse_string(layout_json)
				if parsed != null:
					layout = WidgetLayout.new(parsed)

		var logic
		var logic_path = absolute_path + "/logic.json"

		if FileAccess.file_exists(logic_path):
			var logic_file = FileAccess.open(logic_path, FileAccess.READ)
			if logic_file != null:
				var logic_json = logic_file.get_as_text()
				var parsed = JSON.parse_string(logic_json)
				if parsed != null:
					logic = WidgetLogic.new(parsed)
		
		return WidgetData.new(metadata, layout, logic)
	else:
		return WidgetData.new(WidgetMetadata.new({}), WidgetLayout.new({}), WidgetLogic.new({}))

static func create_widget_draft() -> WidgetMetadata:
	# Millis since epoch → unique folder per draft (clashes only if two drafts share the same ms).
	var draft_id := str(int(Time.get_unix_time_from_system() * 1000.0))

	var metadata = WidgetMetadata.new({})
	metadata.set_name("Draft")
	metadata.set_id(draft_id)
	metadata.set_absolute_path("user://widgets/%s" % metadata.get_id())

	var absolute_path = metadata.get_absolute_path()

	if not DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_absolute(absolute_path)

	var layout = WidgetLayout.new({})
	var logic = WidgetLogic.new({})

	var layout_path = absolute_path + "/layout.json"
	var logic_path = absolute_path + "/logic.json"
	var metadata_path = absolute_path + "/metadata.json"

	var layout_file = FileAccess.open(layout_path, FileAccess.WRITE)
	if layout_file != null:
		layout_file.store_string(layout.to_string())
		layout_file.close()

	var logic_file = FileAccess.open(logic_path, FileAccess.WRITE)
	if logic_file != null:
		logic_file.store_string(logic.to_string())
		logic_file.close()

	var metadata_file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if metadata_file != null:
		metadata_file.store_string(metadata.to_string())
		metadata_file.close()

	return metadata

static func save_widget_data(widget_data: WidgetData) -> bool:
	var metadata = widget_data.get_metadata()
	var layout = widget_data.get_layout()
	var logic = widget_data.get_logic()
	
	var absolute_path = metadata.get_absolute_path()
	var expected_path = "user://widgets/%s" % metadata.get_id()
	if absolute_path != expected_path:
		DirAccess.rename_absolute(absolute_path, expected_path)
		metadata.set_absolute_path(expected_path)
		absolute_path = expected_path
		
		

	if not DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_absolute(absolute_path)
	
	var layout_path = absolute_path + "/layout.json"
	var logic_path = absolute_path + "/logic.json"
	var metadata_path = absolute_path + "/metadata.json"
	
	var layout_file = FileAccess.open(layout_path, FileAccess.WRITE)
	if layout_file != null:
		layout_file.store_string(layout.to_string())
		layout_file.close()
	else:
		return false
	
	var logic_file = FileAccess.open(logic_path, FileAccess.WRITE)
	if logic_file != null:
		logic_file.store_string(logic.to_string())
		logic_file.close()
	else:
		return false
	
	var metadata_file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if metadata_file != null:
		metadata_file.store_string(metadata.to_string())
		metadata_file.close()
	else:
		return false
	
	return true

static func save_file(widget_data: WidgetData, stringified_json: String, file_path: String) -> bool:
	var absolute_path = widget_data.get_metadata().get_absolute_path()
	var full_path = absolute_path + "/" + file_path
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if file != null:
		file.store_string(stringified_json)
		file.close()
		return true
	else:
		return false

static func load_file(widget_data: WidgetData, file_path: String, default_return: String = "[]") -> String:
	var absolute_path = widget_data.get_metadata().get_absolute_path()
	var full_path = absolute_path + "/" + file_path
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		if file != null:
			var content = file.get_as_text()
			file.close()
			return content
	return default_return


static func get_save_data(widget_data: WidgetData) -> String:
	return load_file(widget_data, "_saved.json", "{}")

static func save_data(widget_data: WidgetData, stringified_json: String) -> bool:
	return save_file(widget_data, stringified_json, "_saved.json")
