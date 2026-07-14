class_name SaveData

var variables: Array[ConfigVariable]

var shop_data: Dictionary
var component_overrides: Dictionary

func _init(_data: Variant) -> void:
	for variable_data in _data.get("variables", []):
		variables.append(ConfigVariable.new(variable_data))
	
	shop_data = IO.parse_dict(_data.get("shop_data", {}))
	component_overrides = IO.parse_dict(_data.get("component_overrides", {}))

func get_variable_index(name: String) -> int:
	return variables.find_custom(func(v: ConfigVariable): return v.get_name() == name)

func get_variable(name: String) -> ConfigVariable:
	var idx = get_variable_index(name)
	print ('idx here? ', idx)
	if idx == -1:
		return null
	return variables[idx]

func add_variable(variable: ConfigVariable) -> void:
	variables.append(variable)

func update_variable(name: String, variable: ConfigVariable) -> void:
	var idx = get_variable_index(name)
	if idx != -1:
		variables[idx] = variable
	else:
		push_error("Variable with name '%s' not found." % name)

func remove_variable(variable: ConfigVariable) -> void:
	variables.erase(variable)

func clear_variables() -> void:
	variables.clear() 

func get_variables() -> Array[ConfigVariable]:
	return variables

func get_shop_data() -> Dictionary:
	return shop_data

func set_shop_data(new_shop_data: Dictionary) -> void:
	shop_data = new_shop_data

func get_component_overrides() -> Dictionary:
	return component_overrides

func set_component_overrides(new_component_overrides: Dictionary) -> void:
	component_overrides = new_component_overrides

func to_dict() -> Dictionary:

	return {
		"variables": variables.map(func(v: ConfigVariable) -> Dictionary:
		return v.to_dict()
		),
		"shop_data": IO.convert_dict(shop_data.duplicate_deep()),
		"component_overrides": IO.convert_dict(component_overrides.duplicate_deep())
	}

func _to_string() -> String:
	return JSON.stringify(to_dict())
