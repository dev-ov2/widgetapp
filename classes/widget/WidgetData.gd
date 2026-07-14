extends RefCounted
class_name WidgetData

const usable_nodes: PackedStringArray = ["Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer"]
const custom_components: PackedStringArray = ["Scene"]

var metadata: WidgetMetadata
var layout: WidgetLayout
var logic: WidgetLogic

func _init(_metadata: WidgetMetadata, _layout: WidgetLayout, _logic: WidgetLogic) -> void:
	metadata = _metadata
	layout = _layout
	logic = _logic


func get_metadata() -> WidgetMetadata:
	return metadata

func get_layout() -> WidgetLayout:
	return layout

func get_logic() -> WidgetLogic:
	return logic

func set_metadata(new_metadata: WidgetMetadata) -> void:
	metadata = new_metadata

func set_layout(new_layout: WidgetLayout) -> void:
	layout = new_layout

func set_logic(new_logic: WidgetLogic) -> void:
	logic = new_logic

func _to_string() -> String:
	var to_stringify = { "metadata": metadata.to_string(), "layout": layout.to_string(), "logic": logic.to_string() }
	
	return JSON.stringify(to_stringify)
