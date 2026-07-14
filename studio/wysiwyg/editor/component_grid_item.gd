@tool
extends Control

@export var custom_type: String = ""

# Custom components aren't listed here since this is a template for listing common components
@export_enum("Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer") var child_node: String = "Button":
	set(value): 
		child_node = value
		
		var node_parent = get_node_parent()
		
		if node_parent == null:
			return
		
		for child in node_parent.get_children():
			child.queue_free()
		
		var new_node
		if child_node == "Custom":
			new_node = TextureRect.new()
		elif ClassDB.can_instantiate(child_node):
			new_node = ClassDB.instantiate(child_node)
		if new_node != null:
			node_parent.add_child(new_node)
			_customize_component_slot(new_node)

func get_node_parent() -> Control:
	return find_child("NodeParent", true, false)

func _customize_component_slot(new_node):
	%Label.text = child_node

	new_node.mouse_filter = Control.MOUSE_FILTER_PASS

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
		%Label.text = custom_type

func _get_drag_data(_at_position: Vector2) -> Variant:
	var component = LayoutComponent.new({ "type": child_node if child_node != "Custom" else custom_type })
	var drag_node = get_node_parent().get_child(0)
	
	var drag_data = ComponentDragData.new(drag_node, component, drag_node.duplicate())
	set_drag_preview(drag_data.preview)

	return drag_data
