extends Control

var variable_entry_scene = preload("res://studio/wysiwyg/logic/variables/variable.tscn")

func _add_variable(variable: LogicVariable = LogicVariable.new({}), append: bool = true) -> void:
	var scene = variable_entry_scene.instantiate()
	if append:
		Studio.active_widget.get_logic().add_variable(variable)
	%Variables.add_child(scene)
	scene.set_variable(variable)
	scene.on_item_deleted.connect(_on_variable_deleted)

func _on_button_pressed() -> void:
	_add_variable()

func load_widget_data() -> void:
	for variable in Studio.active_widget.get_logic().get_variables():
		_add_variable(variable, false)

func _on_variable_deleted(variable: LogicVariable) -> void:
	Studio.active_widget.get_logic().remove_variable(variable)
