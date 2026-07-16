class_name ActiveWidgetMetadata

var id: String
var active: bool
var scale: Vector2
var position: Vector2
var opacity: float
var volume: float
var dedicated_scene: bool

func _init(_data: Variant) -> void:
	var data = IO.parse_dict(_data)
	id = data.get("id", "")
	active = data.get("active", false)
	scale = _vector2_or_default(data.get("scale", null), Vector2.ONE)
	position = _position_from_data(data.get("position", null))
	opacity = clampf(float(data.get("opacity", 1.0)), 0.0, 1.0)
	volume = clampf(float(data.get("volume", 1.0)), 0.0, 1.0)
	dedicated_scene = bool(data.get("dedicated_scene", false))

func get_id() -> String:
	return id

func is_active() -> bool:
	return active

func get_scale() -> Vector2:
	return scale

func get_position() -> Vector2:
	return position

func has_saved_position() -> bool:
	return position.is_finite()

func get_opacity() -> float:
	return opacity

func get_volume() -> float:
	return volume

func is_dedicated_scene() -> bool:
	return dedicated_scene

func set_id(new_id: String) -> void:
	id = new_id

func set_active(new_active: bool) -> void:
	active = new_active

func set_scale(new_scale: Vector2) -> void:
	scale = new_scale

func set_position(new_position: Vector2) -> void:
	position = new_position

func set_opacity(new_opacity: float) -> void:
	opacity = clampf(new_opacity, 0.0, 1.0)

func set_volume(new_volume: float) -> void:
	volume = clampf(new_volume, 0.0, 1.0)

func set_dedicated_scene(new_dedicated_scene: bool) -> void:
	dedicated_scene = new_dedicated_scene

func to_dict() -> Dictionary:
	var dict := {
		"id": id,
		"active": active,
		"scale": scale,
		"opacity": opacity,
		"volume": volume,
		"dedicated_scene": dedicated_scene,
	}
	if has_saved_position():
		dict["position"] = position
	return IO.convert_dict(dict)

func _to_string() -> String:
	return JSON.stringify(to_dict())

static func _position_from_data(raw: Variant) -> Vector2:
	if raw == null:
		return Vector2.INF
	if raw is Vector2 and (raw as Vector2).is_finite():
		return raw
	return Vector2.INF

static func _vector2_or_default(raw: Variant, fallback: Vector2) -> Vector2:
	if raw is Vector2 and (raw as Vector2).is_finite():
		return raw
	return fallback

static func find(arr: Array[ActiveWidgetMetadata], id_to_find: String) -> int:
	var idx = arr.find_custom(func(a: ActiveWidgetMetadata): return a.get_id() == id_to_find)
	if idx == -1:
		push_warning("ActiveWidgetMetadata with id '%s' not found..." % id_to_find)
	return idx


static func get_metadata(arr: Array[ActiveWidgetMetadata], id_to_find: String) -> ActiveWidgetMetadata:
	var idx = find(arr, id_to_find)
	if idx == -1:
		push_warning("Creating new metadata...")
		arr.append(ActiveWidgetMetadata.new({ "id": id_to_find, "active": false }))
		return arr[arr.size() - 1]
	return arr[idx]
	
static func update_metadata(arr: Array[ActiveWidgetMetadata], metadata: ActiveWidgetMetadata) -> void:
	var idx = find(arr, metadata.get_id())
	if idx == -1:
		arr.append(metadata)
	arr.set(idx, metadata)
