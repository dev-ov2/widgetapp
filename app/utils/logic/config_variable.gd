class_name ConfigVariable

enum Type { INTEGER, STRING }

var name: String
var type: Type
var current_value: Variant
var min_value: int
var max_value: int

var listening_nodes: PackedStringArray

func _init(_data: Variant) -> void:
	name = _data.get("name", "")
	type = _data.get("type", Type.INTEGER)
	var default_current_value
	match type:
		Type.INTEGER:
			default_current_value = 0
		Type.STRING:
			default_current_value = ""
	current_value = _data.get("current_value", default_current_value)
	min_value = _data.get("min_value", 0)
	max_value = _data.get("max_value", 999999999)
	listening_nodes = _data.get("listening_nodes", PackedStringArray())

func get_name() -> String:
	return name

func get_type() -> Type:
	return type

func get_current_value() -> Variant:
	return current_value

func get_min_value() -> int:
	return min_value

func get_max_value() -> int:
	return max_value

func set_name(new_name: String) -> void:
	name = new_name

func set_type(new_type: Type) -> void:
	type = new_type

func set_current_value(new_current_value: Variant) -> void:
	current_value = new_current_value

func set_min_value(new_min: int) -> void:
	min_value = new_min

func set_max_value(new_max: int) -> void:
	max_value = new_max

func add_listening_node(node_name: String) -> void:
	var idx = listening_nodes.find(node_name)
	if idx == -1:
		listening_nodes.append(node_name)
	# otherwise no-op

func remove_listening_node(node_name: String) -> void:
	var idx = listening_nodes.find(node_name)
	if idx != -1:
		listening_nodes.erase(node_name)

func get_listening_nodes() -> PackedStringArray:
	return listening_nodes

func to_dict() -> Dictionary:
	print ("listening nodes ", listening_nodes)
	return {
		"name": name,
		"type": type,
		"current_value": current_value,
		"min_value": min_value,
		"max_value": max_value,
		"listening_nodes": listening_nodes
	}
