class_name LogicComponent

var action: Studio.LogicOption
var action_metadata: Dictionary
var dependency: Studio.LogicOption
var dependency_metadata: Dictionary
var effect: Studio.LogicOption
var effect_metadata: Dictionary

func _init(_data: Variant) -> void:
	action = _data.get("action", Studio.LogicOption.KEY_PRESS)
	action_metadata = IO.parse_dict(_data.get("action_metadata", {}))
	dependency = _data.get("dependency", Studio.LogicOption.VALUE)
	dependency_metadata = IO.parse_dict(_data.get("dependency_metadata", {}))
	effect = _data.get("effect", Studio.LogicOption.VALUE)
	effect_metadata = IO.parse_dict(_data.get("effect_metadata", {}))

func get_option(stage: Studio.LogicStage) -> Studio.LogicOption:
	match stage:
		Studio.LogicStage.ACTION:
			return get_action()
		Studio.LogicStage.DEPENDENCY:
			return get_dependency()
		Studio.LogicStage.EFFECT:
			return get_effect()
	return get_action()

func set_option(stage: Studio.LogicStage, option: Studio.LogicOption) -> void:
	match stage:
		Studio.LogicStage.ACTION:
			return set_action(option)
		Studio.LogicStage.DEPENDENCY:
			return set_dependency(option)
		Studio.LogicStage.EFFECT:
			return set_effect(option)
	return # no-op

func get_metadata(stage: Studio.LogicStage) -> Dictionary:
	match stage:
		Studio.LogicStage.ACTION:
			return get_action_metadata()
		Studio.LogicStage.DEPENDENCY:
			return get_dependency_metadata()
		Studio.LogicStage.EFFECT:
			return get_effect_metadata()
	return get_action_metadata()

func set_metadata(stage: Studio.LogicStage, metadata: Dictionary) -> void:
	match stage:
		Studio.LogicStage.ACTION:
			set_action_metadata(metadata)
		Studio.LogicStage.DEPENDENCY:
			set_dependency_metadata(metadata)
		Studio.LogicStage.EFFECT:
			set_effect_metadata(metadata)

func get_action() -> Studio.LogicOption:
	return action

func get_action_metadata() -> Dictionary:
	return action_metadata

func get_dependency() -> Studio.LogicOption:
	return dependency

func get_dependency_metadata() -> Dictionary:
	return dependency_metadata

func get_effect() -> Studio.LogicOption:
	return effect

func get_effect_metadata() -> Dictionary:
	return effect_metadata

func set_action(new_action: Studio.LogicOption) -> void:
	action = new_action

func set_action_metadata(new_metadata: Dictionary) -> void:
	action_metadata = new_metadata

func set_dependency(new_dependency: Studio.LogicOption) -> void:
	dependency = new_dependency

func set_dependency_metadata(new_metadata: Dictionary) -> void:
	dependency_metadata = new_metadata

func set_effect(new_effect: Studio.LogicOption) -> void:
	effect = new_effect

func set_effect_metadata(new_metadata: Dictionary) -> void:
	effect_metadata = new_metadata

func to_dict() -> Dictionary:
	return {
		"action": action,
		"action_metadata": IO.convert_dict(action_metadata.duplicate_deep()),
		"dependency": dependency,
		"dependency_metadata": IO.convert_dict(dependency_metadata.duplicate_deep()),
		"effect": effect,
		"effect_metadata": IO.convert_dict(effect_metadata.duplicate_deep()),
	}
