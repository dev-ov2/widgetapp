extends Control

var step: int = 0:
	set(value):
		step = value
		_on_step_change(value)

const Step1Scene = preload("res://studio/steps/step_1.tscn")
const Step2Scene = preload("res://studio/wysiwyg/wysiwyg_editor.tscn")
const Step3Scene = preload("res://studio/steps/step_3.tscn") 

var window: Window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%UndoButton.pressed.connect(_on_undo_button_pressed)
	%RedoButton.pressed.connect(_on_redo_button_pressed)
	Studio.layout_history.history_changed.connect(_update_undo_redo_buttons)
	_on_step_change(0)

func _unhandled_input(event: InputEvent) -> void:
	if step != 1:
		return
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_Z and !event.shift_pressed:
			_on_undo_button_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y or (event.keycode == KEY_Z and event.shift_pressed):
			_on_redo_button_pressed()
			get_viewport().set_input_as_handled()

func _on_next_button_pressed() -> void:
	if step == 1:
		_on_save_button_pressed()
	if step < 2:
		step += 1
	elif step == 2:
		# last step. Save and close.
		_on_save_button_pressed()
		window.queue_free()

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
		scene.loading_changed.connect(_on_loading_changed)
		
	elif new_step == 1:
		%Title.text = "Step 2 | Edit Widget"
		%Subtitle.text = "Use the what-you-see-is-what-you-get (WYSIWYG) editor to customize your widget. Any changes made here will automatically update the preview that's displayed on your screen."
		
		var scene = Step2Scene.instantiate()
		%Content.add_child(scene)
		_layout_full_rect(scene)
		
		scene.load_widget_data()

		
	elif new_step == 2:
		%Title.text = "Step 3 | Finish Widget"
		%Subtitle.text = "Formalize your widget by providing metadata to describe it. This information can be displayed in the Widgetry market."
		%NextButton.text = "Finish"
		
		var scene = Step3Scene.instantiate()
		%Content.add_child(scene)
		_layout_full_rect(scene)
		
		scene.load_widget_data()
	
	_update_undo_redo_buttons()


func _clear_content() -> void:
	for child in %Content.get_children():
		child.queue_free()
		
func _layout_full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_theme_constant_override("margin_left", 0)
	node.add_theme_constant_override("margin_top", 0)
	node.add_theme_constant_override("margin_right", 0)
	node.add_theme_constant_override("margin_bottom", 0)
	
func _on_loading_changed(loading: bool, text = "Next") -> void:
	%BackButton.disabled = loading
	%NextButton.disabled = loading
	%NextButton.text = "Loading..." if loading else text

func _on_save_button_pressed() -> void:
	print("save pressed ", Studio.active_widget)
	IO.save_widget_data(Studio.active_widget)

func _get_wysiwyg_editor() -> Node:
	if step != 1 or %Content.get_child_count() == 0:
		return null
	return %Content.get_child(0)

func _update_undo_redo_buttons() -> void:
	var on_wysiwyg = step == 1
	%UndoButton.visible = on_wysiwyg
	%RedoButton.visible = on_wysiwyg
	%UndoButton.disabled = !on_wysiwyg or !Studio.layout_history.can_undo()
	%RedoButton.disabled = !on_wysiwyg or !Studio.layout_history.can_redo()

func _on_undo_button_pressed() -> void:
	var editor = _get_wysiwyg_editor()
	if editor and editor.has_method("undo"):
		editor.undo()

func _on_redo_button_pressed() -> void:
	var editor = _get_wysiwyg_editor()
	if editor and editor.has_method("redo"):
		editor.redo()
