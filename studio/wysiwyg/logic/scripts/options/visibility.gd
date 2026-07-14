extends Option

func init(new_type: Studio.LogicStage, new_logic_component: LogicComponent, options: Array, update_logic_component: bool) -> void:
	super(new_type, new_logic_component, options, update_logic_component)
	
	var metadata = get_metadata()
	
	if update_logic_component:
		match type:
			Studio.LogicStage.ACTION:
				pass # no-op
				
			Studio.LogicStage.DEPENDENCY:
				metadata.set("current_visibility", get_selected_item(%StatusOptionButton))
				
			Studio.LogicStage.EFFECT:
				metadata.set("new_visibility", get_selected_item(%OutcomeOptionButton))
		
		set_metadata(metadata)
	else:
		match type:
			Studio.LogicStage.ACTION:
				pass # no-op, only SourceOptionButton exists in this case
		
			Studio.LogicStage.DEPENDENCY:
				var idx = %StatusOptionButton.get_item_index(metadata.get("current_visibility", {}).get("id", 0))
				%StatusOptionButton.select(idx)
				
			Studio.LogicStage.EFFECT:
				var idx = %OutcomeOptionButton.get_item_index(metadata.get("new_visibility", {}).get("id", 0))
				%OutcomeOptionButton.select(idx)

func _ready() -> void:
	%SourceOptionButton.item_selected.connect(_on_option_button_item_selected.bind("source", %SourceOptionButton, _on_source_option_button_item_selected))
	%StatusOptionButton.item_selected.connect(_on_option_button_item_selected.bind("current_visibility", %StatusOptionButton))
	%OutcomeOptionButton.item_selected.connect(_on_option_button_item_selected.bind("new_visibility", %OutcomeOptionButton))
