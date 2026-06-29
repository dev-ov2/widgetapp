extends Control

var step: int = 0:
	set(value):
		step = value
		print("Ope", value)
		_on_step_change(value)

const Step1Scene = preload("res://studio/steps/step_1.tscn")
const Step2Scene = preload("res://studio/wysiwyg/wysiwyg_editor.tscn")
const Step3Scene = preload("res://studio/steps/step_3.tscn") 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_step_change(0)

func _on_next_button_pressed() -> void:
	print("Hello world")
	print("Step", step)
	if step < 3:
		step += 1
		
func _on_back_button_pressed() -> void:
	if step > 0:
		step = step - 1



func _on_step_change(new_step: int) -> void:
	_clear_content()
	if new_step == 0:
		%Title.text = "Step 1 | Choose Widget"
		%Subtitle.text = "Select a widget to edit, or choose to create an entirely new one."
		
		var scene = Step1Scene.instantiate()
		%Content.add_child(scene)
		_layout_full_rect(scene)
		
	elif new_step == 1:
		%Title.text = "Step 2 | Edit Widget"
		%Subtitle.text = "Use the what-you-see-is-what-you-get (WYSIWYG) editor to customize your widget. Any changes made here will automatically update the preview that's displayed on your screen."
		%NextButton.text = "Continue to Step 3"
		
		var scene = Step2Scene.instantiate()
		%Content.add_child(scene)
		_layout_full_rect(scene)
		
	elif new_step == 2:
		%Title.text = "Step 3 | Finish Widget"
		%Subtitle.text = "Formalize your widget by providing metadata to describe it. This information can be displayed in the Widgetry market."
		%NextButton.text = "Finish"
		
		var scene = Step3Scene.instantiate()
		%Content.add_child(scene)
		_layout_full_rect(scene)

func _clear_content() -> void:
	for child in %Content.get_children():
		child.queue_free()
		
func _layout_full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_theme_constant_override("margin_left", 0)
	node.add_theme_constant_override("margin_top", 0)
	node.add_theme_constant_override("margin_right", 0)
	node.add_theme_constant_override("margin_bottom", 0)
