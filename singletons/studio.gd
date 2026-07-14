extends Node

enum LogicStage { ACTION, DEPENDENCY, EFFECT }
enum LogicOption { 
	KEY_PRESS, 
	VISIBILITY, 
	VALUE,
	
	# addons
	SHOP
}

enum EditorEvent { DRAGGED, TEMPLATED, LOADED, SELECTED, CHANGED, NODE_ADJUSTED, REMOVED }

const USABLE_NODES: PackedStringArray = ["Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer"]
const CUSTOM_COMPONENTS: PackedStringArray = ["Scene"]

var active_widget: WidgetData
var layout_history: LayoutHistory = LayoutHistory.new()
