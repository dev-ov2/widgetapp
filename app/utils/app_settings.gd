class_name AppSettings

const PATH := "user://config/app.cfg"
const LANDING_CONFIG_KEY = "landing"
const RUN_VALUE_NAME := "widgetapp"

static func _ensure_config_dir() -> void:
	if not DirAccess.dir_exists_absolute("user://config"):
		DirAccess.make_dir_recursive_absolute("user://config")

static func _load() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(PATH)
	return config

static func get_hide_on_startup() -> bool:
	return bool(_load().get_value(LANDING_CONFIG_KEY, "hide_on_startup", false))

static func set_hide_on_startup(enabled: bool) -> void:
	_ensure_config_dir()
	var config := _load()
	config.set_value(LANDING_CONFIG_KEY, "hide_on_startup", enabled)
	config.save(PATH)

static func get_launch_on_startup() -> bool:
	return bool(_load().get_value(LANDING_CONFIG_KEY, "launch_on_startup", false))

static func set_launch_on_startup(enabled: bool) -> void:
	_ensure_config_dir()
	var config := _load()
	config.set_value(LANDING_CONFIG_KEY, "launch_on_startup", enabled)
	config.save(PATH)
	apply_launch_on_startup(enabled)

static func apply_launch_on_startup(enabled: bool) -> void:
	if OS.get_name() != "Windows":
		push_warning("Launch on startup is only supported on Windows.")
		return
	var exe := OS.get_executable_path()
	if enabled:
		OS.execute("reg", [
			"add",
			"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
			"/v", RUN_VALUE_NAME,
			"/t", "REG_SZ",
			"/d", exe,
			"/f"
		], [], true, false)
	else:
		OS.execute("reg", [
			"delete",
			"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
			"/v", RUN_VALUE_NAME,
			"/f"
		], [], true, false)
