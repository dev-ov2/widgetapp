class_name Option
extends VBoxContainer

var type: Studio.LogicStage
var logic_component: LogicComponent

func init(new_type: Studio.LogicStage, new_logic_component: LogicComponent, options: Array, update_logic_component: bool) -> void:
	type = new_type
	logic_component = new_logic_component
	
	for i in options.size():
		%SourceOptionButton.add_item(options[i].name, i + 1)
	
	if update_logic_component:
		var metadata = get_metadata()
		var selected_item = get_selected_item(%SourceOptionButton)
		metadata.set("source", selected_item.get("text", ""))
		set_metadata(metadata)
		
	else:
		var source = get_metadata().get("source", "")
		var idx = options.find_custom(func(o): return o.name == source)
		%SourceOptionButton.select(idx + 1) # to account for the "Choose an *..." entry
		

func get_selected_item(option_button: OptionButton) -> Dictionary:
	var selected_id = option_button.get_selected_id()
	var idx = option_button.get_item_index((selected_id))
	var text = option_button.get_item_text(idx)
	
	return { "id": selected_id, "text": text.to_lower() }

func get_metadata() -> Dictionary:
	if logic_component == null:
		return {} # just return a blank dict to hold values for now. We will update the logic component later
	match type:
		Studio.LogicStage.ACTION:
			return logic_component.get_action_metadata()
		Studio.LogicStage.DEPENDENCY:
			return logic_component.get_dependency_metadata()
		Studio.LogicStage.EFFECT:
			return logic_component.get_effect_metadata()
	return { "ERROR": "no matching type!" } # shouldn't ever occur

func set_metadata(new_metadata: Dictionary) -> void:
	if logic_component == null:
		return # no-op if we don't have a logic_component present
	match type:
		Studio.LogicStage.ACTION:
			logic_component.set_action_metadata(new_metadata)
		Studio.LogicStage.DEPENDENCY:
			logic_component.set_dependency_metadata(new_metadata)
		Studio.LogicStage.EFFECT:
			logic_component.set_effect_metadata(new_metadata)

func _on_option_button_item_selected(index: int, key: String, option_button: OptionButton, callback: Callable = Callable()) -> void:
	if !callback.is_null():
		callback.call(index, option_button)
		return
	
	var id = option_button.get_item_id(index)
	var text = option_button.get_item_text(index)
	var metadata = get_metadata()
	
	metadata.set(key, { "id": id, "text": text.to_lower() })
	set_metadata(metadata)

func _on_source_option_button_item_selected(index: int, option_button: OptionButton) -> void:
	var text = option_button.get_item_text(index)
	var metadata = get_metadata()
	
	metadata.set("source", text)
	set_metadata(metadata)

func _on_text_changed(new_text: String, key: String, cast_to_int: bool = false) -> void:
	var metadata = get_metadata()
	
	var new_value = new_text
	if cast_to_int:
		new_value = int(new_text)
	
	metadata.set(key, new_value)
	set_metadata(metadata)
