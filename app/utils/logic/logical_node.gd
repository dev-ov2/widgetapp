extends Control

signal on_visibility_changed(visible: bool)

func set_visibility(new_visible) -> void:
	visible = new_visible
	on_visibility_changed.emit(visible)
