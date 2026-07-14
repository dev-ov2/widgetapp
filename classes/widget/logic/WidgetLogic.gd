class_name WidgetLogic


var variables: Array[LogicVariable] = []
var components: Array[LogicComponent] = []
var configured_addons: Array[Constants.Addon] = []

func _init(_data: Variant) -> void:
	for component_data in _data.get("components", []):
		components.append(LogicComponent.new(component_data))
		
		
	for variable_data in _data.get("variables", []):
		variables.append(LogicVariable.new(variable_data))
		
	for addon in _data.get("configured_addons", []):
		configured_addons.append(addon)

func get_index(name: String) -> int:
	var idx = components.find_custom(func(a: LayoutComponent): return a.get_name() == name)
	if idx == -1:
		push_error("Component with name '%s' not found." % name)
	return idx

func add_variable(variable: LogicVariable) -> void:
	variables.append(variable)

func update_variable(name: String, variable: LogicVariable) -> void:
	var idx = variables.find_custom(func(a: LogicVariable): return a.get_name() == name)
	if idx != -1:
		variables[idx] = variable
	else:
		push_error("Variable with name '%s' not found." % name)

func remove_variable(variable: LogicVariable) -> void:
	variables.erase(variable)

func clear_variables() -> void:
	variables.clear() 

func get_variables() -> Array[LogicVariable]:
	return variables

func add_component(component: LogicComponent) -> void:
	components.append(component)

func update_component(name: String, component: LogicComponent) -> void:
	var idx = components.find_custom(func(a: LogicComponent): return a.get_name() == name)
	if idx != -1:
		components[idx] = component
	else:
		push_error("Component with name '%s' not found." % name)

func remove_component(component: LogicComponent) -> void:
	components.erase(component)

func get_components() -> Array[LogicComponent]:
	return components

func set_components(new_components: Array[LogicComponent]) -> void:
	components = new_components

func get_configured_addons() -> Array[Constants.Addon]:
	return configured_addons

func add_configured_addon(new_addon: Constants.Addon) -> void:
	var idx = configured_addons.find(new_addon)
	if idx == -1:
		configured_addons.append(new_addon)

func remove_configured_addon(new_addon: Constants.Addon) -> void:
	var idx = configured_addons.find(new_addon)
	if idx != -1:
		configured_addons.erase(new_addon)

func to_dict() -> Dictionary:
	return {
		"variables": variables.map(func(v: LogicVariable) -> Dictionary:
		return v.to_dict()
		),
		"components": components.map(func(c: LogicComponent) -> Dictionary:
		return c.to_dict()
		),
		"configured_addons": configured_addons
	}

func _to_string() -> String:	
	return JSON.stringify(to_dict())
