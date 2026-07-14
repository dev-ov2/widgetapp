extends Control

signal on_node_selected(node: Node)
signal on_node_changed(node: Node)
signal on_node_adjusted(node: Node)
signal on_node_removed(node: Node)

# since the script is being instantiated after the component is ready, we don't get an onready event. Just hook into what's already present
var graph_node: GraphNode
var graph_edit: GraphEdit
var resize_handle: Panel
var panel: Panel

var dragging: bool = false
var grab_offset: Vector2 = Vector2.ZERO

var resizing: bool = false
var resize_start_offset := Vector2.ZERO
var resize_start_size := Vector2.ZERO

func _init() -> void:
	graph_node = get_parent().get_parent() as GraphNode
	graph_edit = graph_node.get_parent() as GraphEdit
	resize_handle = find_child("ResizeHandle", true, false) as Panel
	panel = find_child("Panel", true, false) as Panel

func _snap(pos: Vector2) -> Vector2:
	if graph_edit == null or not graph_edit.snapping_enabled:
		return pos
	var d := float(graph_edit.snapping_distance)
	if d <= 0.0:
		return pos
	return Vector2(round(pos.x / d), round(pos.y / d)) * d

func _snap_value(v: float) -> float:
	if graph_edit == null or not graph_edit.snapping_enabled:
		return v
	var d := float(graph_edit.snapping_distance)
	if d <= 0.0:
		return v
	return round(v / d) * d

func _snap_size(sz: Vector2) -> Vector2:
	return Vector2(_snap_value(sz.x), _snap_value(sz.y))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				on_node_selected.emit(self)
				if resize_handle.get_global_rect().has_point(event.global_position):
					resizing = true
					dragging = false
					resize_start_offset = graph_node.get_local_mouse_position()
					resize_start_size = size
					
					return
				
				dragging = true
				var local_pos = graph_node.get_local_mouse_position()

				grab_offset = local_pos - position
			else:
				if dragging or resizing:
					on_node_adjusted.emit(self)
				dragging = false
				resizing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			on_node_removed.emit(self)
			queue_free()
		
	if event is InputEventMouseMotion:
		if dragging:
			var local_pos = graph_node.get_local_mouse_position()
			position = _snap(local_pos - grab_offset)
			on_node_changed.emit(self)
		
		if resizing:
			var graph_local =  graph_node.get_local_mouse_position()
			var delta_local = graph_local - resize_start_offset
			var new_size := resize_start_size + Vector2(delta_local.x, delta_local.y)
			
			new_size.x = max(new_size.x, 16)
			new_size.y = max(new_size.y, 16)
			
			size = _snap_size(new_size)
			panel.size = _snap_size(new_size)
			on_node_changed.emit(self)
