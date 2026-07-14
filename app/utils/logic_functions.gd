extends RefCounted
class_name LogicFn

class Dependencies:
	static func analyze_visibility(parent: Panel, node: Node, should_be_visible: bool) -> bool:
		return parent.find_child(node.name, true, false).visible == should_be_visible
	
	static func analyze_shop_item(shop: Dictionary, shop_item: String, should_be_unlocked: bool) -> bool:
		return (shop.get(shop_item, {}) as Dictionary).get("unlocked", false) == should_be_unlocked
	
	static func analyze_variable(variable: ConfigVariable, comparator: String, expected_value: Variant) -> bool:
		match variable.type:
			LogicVariable.Type.INTEGER:
				var v = int(variable.get_current_value())
				var d = int(expected_value)
				var success
				match comparator:
					">": success =  v > d
					">=": success = v >= d
					"<": success = v < d
					"<=": success = v <= d
					"==": success = v == d
				return success
		return false

class Effects:
	static func run_effect(option: Studio.LogicOption, ...params: Array) -> void:
		match option:
			Studio.LogicOption.VISIBILITY:
				set_visibility.callv(params)
			Studio.LogicOption.VALUE:
				modify_value.callv(params)
				
			# addons
			Studio.LogicOption.SHOP:
				set_shop_unlocked.callv(params)

	
	
	static func set_visibility(node: Node, visible: bool) -> void:
		node.visible = visible
	
	static func set_shop_unlocked(save_data: SaveData, entry: String, unlocked: bool) -> void:
		var metadata = save_data.get_shop_data()
		metadata.set(entry, {"unlocked": unlocked })
		save_data.set_shop_data(metadata)
	
	static func modify_value(variable: ConfigVariable, modifier: String, by_value: Variant) -> ConfigVariable:
		match variable.type:
			LogicVariable.Type.INTEGER:
				var v = int(variable.get_current_value())
				var d = int(by_value)
				
				match modifier:
					"+": v += d
					"-": v -= d
					"*": v *= d
					@warning_ignore("integer_division")
					"/": v = v if (d == 0) else v / d

				variable.set_current_value(v)
				return variable
		
		return null
