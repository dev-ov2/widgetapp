class_name WidgetPackInputMap

const _PROJECT_BINARY_MAGIC := "ECFG"
const _MAX_PROJECT_SETTINGS := 10000

static var _action_overrides: Dictionary = {}

var _zip_paths: Array[String] = []

var _owner_id: int

var _actions: Dictionary = {}
var _owned_actions: Array[String] = []

var _active := false
var _loaded := false

func _init() -> void:
	_owner_id = get_instance_id()

func configure(zip_paths: Array[String]) -> void:
	if _zip_paths == zip_paths:
		return
	
	var reactivate := _active
	
	set_active(false)
	
	_zip_paths = zip_paths.duplicate()
	_loaded = false
	
	if reactivate:
		set_active(true)

func set_active(enabled: bool) -> void:
	if _active == enabled:
		return
	
	_active = enabled
	
	if _active:
		_load_actions()
		_register_actions()
	
	else:
		_unregister_actions()

func _load_actions() -> void:
	if _loaded:
		return
	
	_loaded = true
	
	_actions.clear()
	
	for zip_path in _zip_paths:
		var zip_actions := _read_actions_from_zip(zip_path)
	
		for action_name in zip_actions:
			_actions[action_name] = zip_actions[action_name]
	
	if _actions.is_empty() and !_zip_paths.is_empty():
		push_warning(
			"WidgetPackInputMap: no input actions found in %d pack zip(s)" % _zip_paths.size()
		)

func _register_actions() -> void:
	for action_name in _actions:
		var action_data: Dictionary = _actions[action_name]
		var state: Dictionary = _action_overrides.get(action_name, {})
	
		if state.is_empty():
			state = {
				"baseline": _snapshot_action(action_name, float(action_data.get("deadzone", 0.5))),
				"overrides": [],
			}
	
		var overrides: Array = state["overrides"]
		overrides.append({"owner": _owner_id, "data": action_data})
		state["overrides"] = overrides
	
		_action_overrides[action_name] = state
		_owned_actions.append(action_name)
		_apply_action(action_name, action_data)

func _unregister_actions() -> void:
	for action_name in _owned_actions:
		var state: Dictionary = _action_overrides.get(action_name, {})
		var overrides: Array = state.get("overrides", [])
		var index := overrides.find_custom(
			func(entry: Dictionary): return entry.get("owner") == _owner_id
		)
	
		if index >= 0:
			overrides.remove_at(index)
	
		if overrides.is_empty():
			_restore_action(action_name, state.get("baseline", {}))
			_action_overrides.erase(action_name)
	
		else:
			_apply_action(action_name, overrides.back()["data"])
			state["overrides"] = overrides
			_action_overrides[action_name] = state
	
	_owned_actions.clear()

static func _read_actions_from_zip(zip_path: String) -> Dictionary:
	if zip_path.is_empty() or !zip_path.to_lower().ends_with(".zip"):
		return {}
	
	if !FileAccess.file_exists(zip_path):
		push_warning("WidgetPackInputMap: zip not found at '%s'" % zip_path)
		return {}
	
	var reader := ZIPReader.new()
	
	if reader.open(zip_path) != OK:
		push_warning("WidgetPackInputMap: failed to open zip '%s'" % zip_path)
		return {}
	
	var binary_path := ""
	var godot_path := ""
	
	for path in reader.get_files():
		match path.get_file():
			"project.binary":
				binary_path = path
			
			"project.godot":
				if godot_path.is_empty():
					godot_path = path
	
	var project_path := binary_path if !binary_path.is_empty() else godot_path
	if project_path.is_empty():
		reader.close()
		push_warning(
			"WidgetPackInputMap: project.binary/project.godot missing in '%s'" % zip_path
		)
		return {}
	
	var bytes: PackedByteArray = reader.read_file(project_path)
	
	reader.close()
	
	if bytes.is_empty():
		return {}
	
	if !binary_path.is_empty():
		return _parse_project_binary(bytes)
	
	return _parse_input_section(bytes.get_string_from_utf8())

static func _parse_project_binary(bytes: PackedByteArray) -> Dictionary:
	var actions: Dictionary = {}
	
	if bytes.size() < 8:
		return actions
	
	var magic := bytes.slice(0, 4).get_string_from_ascii()
	
	if magic != _PROJECT_BINARY_MAGIC:
		push_warning("WidgetPackInputMap: invalid project.binary header")
		return actions
	
	var offset := 4
	var count := bytes.decode_u32(offset)
	offset += 4
	
	if count > _MAX_PROJECT_SETTINGS:
		push_warning("WidgetPackInputMap: suspicious project.binary entry count (%d)" % count)
		return actions
	
	for _i in count:
		if offset + 4 > bytes.size():
			break

		var key_len := bytes.decode_u32(offset)
		offset += 4

		if offset + key_len > bytes.size():
			break

		var key := bytes.slice(offset, offset + key_len).get_string_from_utf8()
		offset += key_len

		if offset + 4 > bytes.size():
			break

		var value_len := bytes.decode_u32(offset)
		offset += 4

		if offset + value_len > bytes.size():
			break
		var value_bytes := bytes.slice(offset, offset + value_len)
		offset += value_len

		if !key.begins_with("input/"):
			continue

		var value: Variant = bytes_to_var_with_objects(value_bytes)

		if value is Dictionary and value.has("events"):
			actions[key.trim_prefix("input/")] = value

	return actions

static func _parse_input_section(project_text: String) -> Dictionary:
	var result: Dictionary = {}
	var config := ConfigFile.new()
	
	if config.parse(project_text) != OK:
		push_warning("WidgetPackInputMap: failed to parse project.godot")
		return result
	
	if !config.has_section("input"):
		return result
	
	for action_name in config.get_section_keys("input"):
		var action_data: Variant = config.get_value("input", action_name)
		if action_data is Dictionary and action_data.has("events"):
			result[action_name] = action_data
	
	return result

func _snapshot_action(action_name: String, deadzone: float) -> Dictionary:
	if !InputMap.has_action(action_name):
		return {
			"existed": false,
			"deadzone": deadzone,
			"events": [],
		}
	
	return {
		"existed": true,
		"deadzone": InputMap.action_get_deadzone(action_name),
		"events": _copy_action_events(action_name),
	}

func _restore_action(action_name: String, snapshot: Dictionary) -> void:
	if snapshot.get("existed", false):
		InputMap.action_erase_events(action_name)
		InputMap.action_set_deadzone(action_name, float(snapshot.get("deadzone", 0.5)))
	
		for event in snapshot.get("events", []):
			if event is InputEvent:
				InputMap.action_add_event(action_name, event.duplicate())
	
	elif InputMap.has_action(action_name):
		InputMap.erase_action(action_name)

func _apply_action(action_name: String, action_data: Dictionary) -> void:
	var deadzone := float(action_data.get("deadzone", 0.5))
	
	if !InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)
	
	else:
		InputMap.action_set_deadzone(action_name, deadzone)
	
	InputMap.action_erase_events(action_name)
	
	for event in action_data.get("events", []):
		if event is InputEvent:
			InputMap.action_add_event(action_name, event.duplicate())

func _copy_action_events(action_name: String) -> Array[InputEvent]:
	var copied: Array[InputEvent] = []
	
	for event in InputMap.action_get_events(action_name):
		if event is InputEvent:
			copied.append(event.duplicate())
	
	return copied
