extends VBoxContainer

signal on_item_deleted(variable: LogicVariable)

var variable: LogicVariable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%NameLineEdit.text_changed.connect(_on_name_changed)
	for key in LogicVariable.Type.keys():
		%TypeOptionButton.add_item(key.to_pascal_case(), LogicVariable.Type[key])
	
	%TypeOptionButton.item_selected.connect(_on_type_option_button_item_selected)

func set_variable(new_variable: LogicVariable) -> void:
	variable = new_variable
	
	%NameLineEdit.text = variable.get_name()
	
	var idx = %TypeOptionButton.get_item_index(variable.get_type())
	%TypeOptionButton.select(idx)
	_on_type_option_button_item_selected(idx)

func _on_type_option_button_item_selected(index: int) -> void:
	var type = %TypeOptionButton.get_item_id(index)
	variable.set_type(type)
	
	match type:
		LogicVariable.Type.INTEGER: # Integer
			var int_scene = load("res://studio/wysiwyg/logic/variables/integer.tscn").instantiate()
			%Variable.add_child(int_scene)
			
			if variable != null:
				var default_value_line_edit = int_scene.find_child("DefaultValueLineEdit", true, false)
				default_value_line_edit.text = str(variable.default_value)
				default_value_line_edit.text_changed.connect(_on_text_changed.bind(LogicVariable.Type.INTEGER, "default_value"))

				var min_value_line_edit = int_scene.find_child("MinValueLineEdit", true, false)
				min_value_line_edit.text = str(variable.get_min_value())
				min_value_line_edit.text_changed.connect(_on_text_changed.bind(LogicVariable.Type.INTEGER, "min_value"))

				var max_value_line_edit = int_scene.find_child("MaxValueLineEdit", true, false)
				max_value_line_edit.text = str(variable.get_max_value())
				max_value_line_edit.text_changed.connect(_on_text_changed.bind(LogicVariable.Type.INTEGER, "max_value"))

func _on_name_changed(new_text) -> void:
	variable.set_name(new_text)

func _on_text_changed(new_text: String, type: LogicVariable.Type, key: String) -> void:
	match type:
		LogicVariable.Type.INTEGER:
			match key:
				"default_value":
					variable.set_default_value(int(new_text))
				"minimum_value":
					variable.set_min_value(int(new_text))
				"maximum_value":
					variable.set_max_value(int(new_text))


func _on_texture_button_pressed() -> void:
	on_item_deleted.emit(variable)
	queue_free()
