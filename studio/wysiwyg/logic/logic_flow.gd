extends Control

func _ready() -> void:
	#%GraphEdit.
	pass

func load_widget_data() -> void:
	%GraphEdit.load_widget_data()
	%VariableConfiguration.load_widget_data()

func save_widget_data() -> void:
	IO.save_file(Studio.active_widget, JSON.stringify(Studio.active_widget.get_logic().to_dict()), "logic.json")

func _on_save_button_pressed() -> void:
	print ("saving .. ")
	%GraphEdit.save_data()
	save_widget_data()
