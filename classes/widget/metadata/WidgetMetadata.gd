class_name WidgetMetadata

var id: String
var name: String
var description: String
var tags: PackedStringArray
var author: String
var version: String
var icon_path: String
var absolute_path: String # really only useful in case the user decides to try to rename the folder. we're just being a little safe here is all
var active: bool

func _init(_data: Variant) -> void:
	id = _data.get("id", "")
	name = _data.get("name", "")
	description = _data.get("description", "")
	tags = _data.get("tags", PackedStringArray())
	author = _data.get("author", "")
	version = _data.get("version", "")
	icon_path = _data.get("icon_path", "")
	active = _data.get("active", false)

func get_id() -> String:
	return id

func get_name() -> String:
	return name

func get_description() -> String:
	return description

func get_tag_array() -> PackedStringArray:
	return tags

func get_tags() -> String:
	return ",".join(tags)

func get_author() -> String:
	return author

func get_version() -> String:
	return version

func get_icon_path() -> String:
	return icon_path

func get_absolute_path() -> String:
	return absolute_path

func is_active() -> bool:
	return active

func set_id(new_id: String) -> void:
	id = new_id

func set_name(new_name: String) -> void:
	name = new_name

func set_description(new_description: String) -> void:
	description = new_description

func set_tags(new_tags: String) -> void:
	var tag_list = new_tags.split(",")
	for i in range(tag_list.size()):
		tag_list[i] = tag_list[i].strip_edges()
	tags = tag_list

func set_author(new_author: String) -> void:
	author = new_author

func set_version(new_version: String) -> void:
	version = new_version

func set_icon_path(new_icon_path: String) -> void:
	icon_path = new_icon_path

func set_absolute_path(path: String) -> void:
	absolute_path = path

func set_active(new_active: bool) -> void:
	active = new_active

func _to_string() -> String:
	var to_stringify = { "id": id, "name": name, "description": description, "tags": tags, "author": author, "version": version, "icon_path": icon_path, "absolute_path": absolute_path, "active": active }
	return JSON.stringify(to_stringify)

static func get_metadata(arr: Array[WidgetMetadata], id_to_find: String) -> WidgetMetadata:
	var idx = arr.find_custom(func(a: WidgetMetadata): return a.get_id() == id_to_find)
	if idx == -1:
		push_warning("WidgetMetadata with id '%s' not found..." % id_to_find)
	return arr[idx]
