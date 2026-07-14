class_name GraphNodeDragData


var type: Studio.LogicStage
var graph_node: Control

func _init(_type: Studio.LogicStage, _graph_node: Control):
	self.type = _type
	self.graph_node = _graph_node
