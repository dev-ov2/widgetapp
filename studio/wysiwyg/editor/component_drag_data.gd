class_name ComponentDragData

var source: Control = null
var destination: Control = null

var component: LayoutComponent
var preview: Control

func _init(_source: Control, _component: LayoutComponent, _preview: Control):
	self.source = _source
	self.component = _component
	self.preview = _preview
