@tool
extends Control

@export var custom_type: String

# Custom components aren't listed here since this is a template for listing common components
@export_enum("Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer") var child_node: String = "Button":
	set(value): 
		child_node = value
		
		for child in $PanelContainer/VBoxContainer/Control.get_children():
			child.queue_free()
		
		var new_node
		if child_node == "Custom":
			new_node = TextureRect.new()
		elif ClassDB.can_instantiate(child_node):
			new_node = ClassDB.instantiate(child_node)
		if new_node != null:
			$PanelContainer/VBoxContainer/Control.add_child(new_node)
			_customize_component_slot(new_node)

func _customize_component_slot(new_node):
	$PanelContainer/VBoxContainer/Label.text = child_node

	if child_node == "Button":
		(new_node as Button).text = "Button"
	elif child_node == "Label":
		(new_node as Label).text = "Label"
	elif child_node == "Panel":
		(new_node as Panel).size = Vector2i(64, 48)
	elif child_node == "TextureRect":
		(new_node as TextureRect).texture = load("res://icon.svg")
		(new_node as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(new_node as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		(new_node as TextureRect).size = Vector2i(64, 48)
	elif child_node == "Custom":
		(new_node as TextureRect).texture = load("res://jigsaw.svg")
		(new_node as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(new_node as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		(new_node as TextureRect).size = Vector2i(64, 48)
		$PanelContainer/VBoxContainer/Label.text = custom_type
