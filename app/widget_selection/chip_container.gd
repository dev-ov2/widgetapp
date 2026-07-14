extends HFlowContainer

@export var chip_scene: PackedScene

func populate_tags(tags: Array[String]) -> void:
	for tag in tags:
		var scene = chip_scene.instantiate()
		add_child(scene)
		scene.text = tag
