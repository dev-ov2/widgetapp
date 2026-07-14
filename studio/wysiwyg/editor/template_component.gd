extends Control

@export_enum("Button", "Label", "Panel", "TextureRect", "VideoStreamPlayer", "Control") var node_type: String = "Button"
@export_enum("main", "shop", "shop_list_item") var parent_type: String
@export var extra_metadata: String = "{}"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var metadata = Studio.active_widget.get_layout().get_metadata()
	var templated_ids = metadata.get("templated_ids", [])
	
	var has_templated_node = templated_ids.has(name)
	if has_templated_node:
		# we already saved this during initialization of the widget data
		name = "_pending_removal"
		queue_free() 
		return
	
	templated_ids.append(name)
	metadata.set("templated_ids", templated_ids)
	Studio.active_widget.get_layout().set_metadata(metadata)
	
	var component = LayoutComponent.new({ "name": name, "type": node_type, "parent": parent_type, "metadata": JSON.parse_string(extra_metadata) })
	get_parent().call("instantiate_component", self, component, Studio.EditorEvent.TEMPLATED)
