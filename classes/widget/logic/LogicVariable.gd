class_name LogicVariable

enum Type { INTEGER, STRING }

var name: String
var type: Type
var default_value: Variant
var min_value: int
var max_value: int


func _init(_data: Variant) -> void:
	name = _data.get("name", "")
	type = _data.get("type", Type.INTEGER)
	default_value = _data.get("default_value", "")
	min_value = _data.get("min_value", 0)
	max_value = _data.get("max_value", 999999999)

func get_name() -> String:
	return name

func get_type() -> Type:
	return type

func get_default_value() -> Variant:
	return default_value

func get_min_value() -> int:
	return min_value

func get_max_value() -> int:
	return max_value

func set_name(new_name: String) -> void:
	name = new_name

func set_type(new_type: Type) -> void:
	type = new_type

func set_default_value(new_default_value: Variant) -> void:
	default_value = new_default_value

func set_min_value(new_min: int) -> void:
	min_value = new_min

func set_max_value(new_max: int) -> void:
	max_value = new_max
	
func to_dict() -> Dictionary:
	return {
		"name": name,
		"type": type,
		"default_value": default_value,
		"min_value": min_value,
		"max_value": max_value
	}
