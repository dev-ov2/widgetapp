class_name WidgetGameModeSettings

var enabled: bool
var key: int
var ctrl: bool
var alt: bool
var shift: bool
var meta: bool
var visible_when_not_focused: bool

func _init(data: Dictionary = {}) -> void:
	enabled = bool(data.get("enabled", data.get("game_mode", false)))
	key = int(data.get("key", data.get("game_mode_key", 0)))
	ctrl = bool(data.get("ctrl", data.get("game_mode_ctrl", false)))
	alt = bool(data.get("alt", data.get("game_mode_alt", false)))
	shift = bool(data.get("shift", data.get("game_mode_shift", false)))
	meta = bool(data.get("meta", data.get("game_mode_meta", false)))
	visible_when_not_focused = bool(data.get("visible_when_not_focused", true))

func get_enabled() -> bool:
	return enabled

func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled

func get_visible_when_not_focused() -> bool:
	return visible_when_not_focused

func set_visible_when_not_focused(new_visible_when_not_focused: bool) -> void:
	visible_when_not_focused = new_visible_when_not_focused

func set_hotkey(data: Dictionary) -> void:
	key = int(data.get("key", key))
	ctrl = bool(data.get("ctrl", ctrl))
	alt = bool(data.get("alt", alt))
	shift = bool(data.get("shift", shift))
	meta = bool(data.get("meta", meta))

func get_hotkey_label() -> String:
	if key <= 0:
		return ""
	var parts: PackedStringArray = []
	if ctrl:
		parts.append("Ctrl")
	if alt:
		parts.append("Alt")
	if shift:
		parts.append("Shift")
	if meta:
		parts.append("Meta")
	var key_name := OS.get_keycode_string(key as Key)
	if key_name.is_empty():
		key_name = "Key %d" % key
	parts.append(key_name)
	return "+".join(parts)

func to_dict() -> Dictionary:
	return {
		"enabled": enabled,
		"key": key,
		"ctrl": ctrl,
		"alt": alt,
		"shift": shift,
		"meta": meta,
		"visible_when_not_focused": visible_when_not_focused,
	}
