extends Option

func init(new_type: Studio.LogicStage, new_logic_component: LogicComponent, options: Array, update_logic_component: bool) -> void:
	super(new_type, new_logic_component, options, update_logic_component)
	
	var metadata = get_metadata()
	
	if update_logic_component:
		match type:
			Studio.LogicStage.ACTION:
				pass # no-op
				
			Studio.LogicStage.DEPENDENCY:
				metadata.set("comparator", get_selected_item(%ComparisonOptionButton))
				metadata.set("expected_value", int((%ExpectedValueLineEdit as LineEdit).get_text()))
				
			Studio.LogicStage.EFFECT:
				metadata.set("modifier", get_selected_item(%ModifierOptionButton))
				metadata.set("modifying_value", int((%ModifierValueLineEdit as LineEdit).get_text()))
		set_metadata(metadata)
	else:
		match type:
			Studio.LogicStage.ACTION:
				pass # no-op, only SourceOptionButton exists in this case
		
			Studio.LogicStage.DEPENDENCY:
				var idx = %ComparisonOptionButton.get_item_index(metadata.get("comparator", {}).get("id", 0))
				%ComparisonOptionButton.select(idx)
				
				%ExpectedValueLineEdit.text = str(metadata.get("expected_value", "5"))
				
			Studio.LogicStage.EFFECT:
				var idx = %ModifierOptionButton.get_item_index(metadata.get("modifier", {}).get("id", 0))
				%ModifierOptionButton.select(idx)
				
				%ModifierValueLineEdit.text = str(metadata.get("modifying_value", 1))

func _ready() -> void:
	%SourceOptionButton.item_selected.connect(_on_option_button_item_selected.bind("source", %SourceOptionButton, _on_source_option_button_item_selected))
	%ComparisonOptionButton.item_selected.connect(_on_option_button_item_selected.bind("comparator", %ComparisonOptionButton))
	%ExpectedValueLineEdit.text_changed.connect(_on_text_changed.bind("expected_value"))
	%ModifierOptionButton.item_selected.connect(_on_option_button_item_selected.bind("modifier", %ModifierOptionButton))
	%ModifierValueLineEdit.text_changed.connect(_on_text_changed.bind("modifying_value"))
