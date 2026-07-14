class_name ActiveWidgetMetadata

var id: String
var active: bool
var scale: Vector2
var position: Vector2
var volume: float

func _init(_data: Variant) -> void:
	var data = IO.parse_dict(_data)
	id = data.get("id", "")
	active = data.get("active", false)
	scale = data.get("scale", Vector2(1, 1))
	position = data.get("position", Vector2.INF)
	volume = data.get("volume", 1.0)

func get_id() -> String:
	return id

func is_active() -> bool:
	return active

func get_scale() -> Vector2:
	return scale

func get_position() -> Vector2:
	return position

func get_volume() -> float:
	return volume

func set_id(new_id: String) -> void:
	id = new_id

func set_active(new_active: bool) -> void:
	active = new_active

func set_scale(new_scale: Vector2) -> void:
	scale = new_scale

func set_position(new_position: Vector2) -> void:
	position = new_position

func set_volume(new_volume: float) -> void:
	volume = new_volume

func to_dict() -> Dictionary:
	return IO.convert_dict({
		"id": id,
		"active": active,
		"scale": scale,
		"position": position,
		"volume": volume
	})

func _to_string() -> String:
	return JSON.stringify(to_dict())

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
