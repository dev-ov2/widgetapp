class_name LayoutComponent

var name: String
var type: String
var size: Vector2
var position: Vector2
var visible: bool
var z_index: int
var metadata: Dictionary
var parent: String

func _init(_data: Variant) -> void:
	name = _data.get("name", "")
	type = _data.get("type", "")
	var data_size: Array = _data.get("size", [])
	size = Vector2(data_size[0], data_size[1]) if !data_size.is_empty() else Vector2(50,50)
	var data_pos: Array = _data.get("position", [])
	position = Vector2(data_pos[0], data_pos[1]) if !data_pos.is_empty() else Vector2.ZERO
	visible = _data.get("visible", true)
	z_index = _data.get("z_index", 0)
	metadata = _data.get("metadata", {})
	parent = _data.get("parent", "main")

func get_name() -> String:
	return name

func get_type() -> String:
	return type

func get_size() -> Vector2:
	return size

func get_position() -> Vector2:
	return position

func is_visible() -> bool:
	return visible

func get_z_index() -> int:
	return z_index

func get_metadata() -> Dictionary:
	return metadata

func get_parent() -> String:
	return parent

func set_name(new_name: String) -> void:
	name = new_name

func set_type(new_type: String) -> void:
	if new_type in Studio.USABLE_NODES:
		type = new_type
	elif new_type in Studio.CUSTOM_COMPONENTS:
		type = new_type
	elif new_type == "Control":
		# custom controls we have added (such as the ShopList)
		type = new_type
	else:
		push_error("Invalid node type: " + new_type)

func set_size(new_size: Vector2) -> void:
	size = new_size

func set_position(new_position: Vector2) -> void:
	position = new_position

func set_visible(new_visible: bool) -> void:
	visible = new_visible

func set_z_index(new_z_index: int) -> void:
	z_index = new_z_index

func set_metadata(new_metadata: Dictionary) -> void:
	metadata = new_metadata

func set_parent(new_parent: String) -> void:
	parent = new_parent

func _to_string() -> String:
	var to_stringify = { "name": name, "type": type, "size": size, "position": position, "visible": visible, "z_index": z_index, "metadata": metadata, "parent": parent }
	return JSON.stringify(to_stringify)
	
func to_dict() -> Dictionary:
	return {
		"name": name,
		"type": type,
		"size": [size.x, size.y],
		"position": [position.x, position.y],
		"visible": visible,
		"z_index": z_index,
		"metadata": metadata.duplicate_deep(),
		"parent": parent,
	}
