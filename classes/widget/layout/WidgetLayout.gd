class_name WidgetLayout

var components: Array[LayoutComponent] = []
var metadata: Dictionary

func _init(_data: Variant) -> void:
	for component_data in _data.get("components", []):
		components.append(LayoutComponent.new(component_data))
	metadata = IO.parse_dict(_data.get("metadata", {}))

func add_component(component: LayoutComponent) -> void:
	components.append(component)

func get_component_index(name: String) -> int:
	var idx = components.find_custom(func(a: LayoutComponent): return a.get_name() == name)
	if idx == -1:
		push_error("Component with name '%s' not found." % name)
	return idx

func make_unique_name(desired: String, excluding: LayoutComponent = null) -> String:
	desired = desired.strip_edges()
	if desired.is_empty():
		desired = "Component"
	if !_is_name_taken(desired, excluding):
		return desired
	
	var stem = desired
	var next_n = 2
	var i = desired.length() - 1
	while i >= 0 and str(desired[i]).is_valid_int():
		i -= 1
	if i >= 0 and i < desired.length() - 1:
		stem = desired.substr(0, i + 1)
		next_n = int(desired.substr(i + 1)) + 1
	
	var candidate = "%s%d" % [stem, next_n]
	while _is_name_taken(candidate, excluding):
		next_n += 1
		candidate = "%s%d" % [stem, next_n]
	return candidate

func _is_name_taken(name: String, excluding: LayoutComponent = null) -> bool:
	for c in components:
		if excluding != null and c == excluding:
			continue
		if c.get_name() == name:
			return true
	return false


func update_component(name: String, component: LayoutComponent) -> void:
	var idx = get_component_index(name)
	
	if idx != -1:
		components[get_component_index(name)] = component

func remove_component(component: LayoutComponent) -> void:
	var existing = WidgetLayout.find_component(components, component.get_name())
	if existing:
		components.erase(existing)

func clear_components() -> void:
	components.clear()

func get_components() -> Array[LayoutComponent]:
	return components

func get_metadata() -> Dictionary:
	return metadata

func set_metadata(new_metadata: Dictionary) -> void:
	metadata = new_metadata

static func filter_parent(arr: Array[LayoutComponent], parent: String) -> Array[LayoutComponent]:
	return arr.filter(func(a: LayoutComponent): return a.get_parent() == parent)

static func find_component(arr: Array[LayoutComponent], name: String) -> LayoutComponent:
	var idx = arr.find_custom(func(a: LayoutComponent): return a.get_name() == name)
	if idx == -1: 
		return null
	return arr[idx]

func to_dict() -> Dictionary:
	return {
		"components": components.map(func(c: LayoutComponent) -> Dictionary:
		return c.to_dict()
		),
		"metadata": IO.convert_dict(metadata.duplicate_deep())
	}

func _to_string() -> String:	
	return JSON.stringify(to_dict())
