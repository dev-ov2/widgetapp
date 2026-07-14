extends Panel

signal pressed

@export var title: String = "Title":
	set(value):
		title = value
		if is_node_ready() and has_node("%Title"):
			%Title.text = title

@export_multiline var description: String = "Description":
	set(value):
		description = value
		if is_node_ready() and has_node("%Description"):
			%Description.text = description

var _hover_tween: Tween

func _ready() -> void:
	%Title.text = title
	%Description.text = description
	%Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	%CardButton.pressed.connect(func(): pressed.emit())
	%CardButton.mouse_entered.connect(_on_mouse_entered)
	%CardButton.mouse_exited.connect(_on_mouse_exited)
	resized.connect(_update_pivot)
	_update_pivot()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _on_mouse_entered() -> void:
	_tween_scale(1.03)

func _on_mouse_exited() -> void:
	_tween_scale(1.0)

func _tween_scale(target: float) -> void:
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(target, target), 0.15)
