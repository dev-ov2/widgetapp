class_name DragGraphNode
extends GraphNode

@export var type: Studio.LogicStage

func _ready() -> void:
	pass

func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(self.duplicate())
	var graph_node_drag_data = GraphNodeDragData.new(type, self.duplicate())
	return graph_node_drag_data
