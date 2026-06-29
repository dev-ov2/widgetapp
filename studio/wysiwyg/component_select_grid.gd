@tool
extends GridContainer

var usable_nodes: PackedStringArray = ["Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer"]
var custom_components: PackedStringArray = ["Scene"]

var component_grid_item_scene: PackedScene = preload("res://studio/wysiwyg/component_grid_item.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node in usable_nodes:
		var scene := component_grid_item_scene.instantiate()
		scene.child_node = node
		add_child(scene)
		
	for node in custom_components:
		var scene := component_grid_item_scene.instantiate()
		scene.custom_type = node
		scene.child_node = "Custom"
		add_child(scene)
