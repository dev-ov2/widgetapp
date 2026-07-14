extends Control

var node_events_to_propogate: Array[Dictionary] = []
var _applying_history: bool = false

func _on_store_logic_check_button_toggled(toggled_on: bool) -> void:
	%WidgetStoreNode.visible = toggled_on
	%WidgetStoreListItemNode.visible = toggled_on
	%EditShopOfferingsButton.visible = toggled_on
	if toggled_on:
		Studio.active_widget.get_logic().add_configured_addon(Constants.Addon.SHOP)
	else:
		Studio.active_widget.get_logic().remove_configured_addon(Constants.Addon.SHOP)

func _on_pet_logic_check_button_toggled(_toggled_on: bool) -> void:
	# TODO do we want to force scene usage here? I'd say prolly
	pass # Replace with function body.

func _on_panel_on_node_event_received(node: Node, component: LayoutComponent, event: Studio.EditorEvent) -> void:
	if Studio.active_widget == null: # if we don't have this yet, just add to events to propogate later
		node_events_to_propogate.append({"node": node, "component": component, "event": event})
		return
	
	if node != null:
		var live = WidgetLayout.find_component(Studio.active_widget.get_layout().get_components(), node.name)
		if live != null:
			component = live
	
	if _applying_history:
		return
	
	if event == Studio.EditorEvent.NODE_ADJUSTED:
		if component != null:
			_write_node_transform_to_component(node, component)
		Studio.layout_history.commit()
		return
	
	_record_history_for_event(event)
	if event == Studio.EditorEvent.CHANGED and component != null:
		_write_node_transform_to_component(node, component)
	
	if node == null:
		%InspectorLayout.call("clear_state")
		%InspectorLayout.visible = false
	else:
		%InspectorLayout.call("update_state", node, component, event)
		%InspectorLayout.visible = true

func _record_history_for_event(event: Studio.EditorEvent) -> void:
	var layout = Studio.active_widget.get_layout()
	match event:
		Studio.EditorEvent.CHANGED:
			Studio.layout_history.begin(layout)
		Studio.EditorEvent.DRAGGED, Studio.EditorEvent.REMOVED:
			Studio.layout_history.record(layout)

func _write_node_transform_to_component(node: Node, component: LayoutComponent) -> void:
	component.set_size(node.size)
	component.set_position(node.position)
	component.set_z_index(node.z_index)
	component.set_visible(node.modulate.a == 1.0)

func _populate_panels(components: Array[LayoutComponent]) -> void:
	var widget_components = WidgetLayout.filter_parent(components, "main")
	for component in widget_components:
		%WidgetPanel.instantiate_saved_component(component)
	
	var shop_components = WidgetLayout.filter_parent(components, "shop")
	for component in shop_components:
		%StorePanel.instantiate_saved_component(component)
	
	var shop_list_item_components = WidgetLayout.filter_parent(components, "shop_list_item")
	for component in shop_list_item_components:
		%StoreListItemPanel.instantiate_saved_component(component)

func _apply_component_transform(node: Node, component: LayoutComponent) -> void:
	node.size = component.get_size()
	node.position = component.get_position()
	node.z_index = component.get_z_index()
	node.modulate.a = 1.0 if component.is_visible() else 0.5
	var overlay = node.find_child("Panel", false, false)
	if overlay != null:
		overlay.size = component.get_size()

func _sync_panel_to_layout(panel: Node, parent_key: String) -> void:
	var components = WidgetLayout.filter_parent(Studio.active_widget.get_layout().get_components(), parent_key)
	var kept_names = {}
	for component in components:
		kept_names[component.get_name()] = true
	
	# Only remove editable components — never wipe templated/structural nodes (ShopList)
	for child in panel.get_children():
		if kept_names.has(child.name):
			continue
		if child.has_signal("on_node_selected"):
			child.free()
	
	for component in components:
		var existing: Node = null
		for child in panel.get_children():
			if child.name == component.get_name():
				existing = child
				break
		
		if existing:
			# Transform only. Do NOT call update_state(LOADED) — that re-registers the
			# inspector and reloads Scene SubViewport packs, which clobber restore.
			_apply_component_transform(existing, component)
		else:
			panel.instantiate_saved_component(component)

func _rebuild_from_layout() -> void:
	_applying_history = true
	%InspectorLayout.call("clear_state")
	%InspectorLayout.visible = false
	
	_sync_panel_to_layout(%WidgetPanel, "main")
	_sync_panel_to_layout(%StorePanel, "shop")
	_sync_panel_to_layout(%StoreListItemPanel, "shop_list_item")
	
	_applying_history = false

func undo() -> void:
	if Studio.active_widget == null or !Studio.layout_history.can_undo():
		return
	var snapshot = Studio.layout_history.undo(Studio.active_widget.get_layout())
	if snapshot.is_empty():
		return
	Studio.active_widget.set_layout(WidgetLayout.new(snapshot))
	_rebuild_from_layout()

func redo() -> void:
	if Studio.active_widget == null or !Studio.layout_history.can_redo():
		return
	var snapshot = Studio.layout_history.redo(Studio.active_widget.get_layout())
	if snapshot.is_empty():
		return
	Studio.active_widget.set_layout(WidgetLayout.new(snapshot))
	_rebuild_from_layout()

func load_widget_data() -> void:
	for node_event in node_events_to_propogate:
		%InspectorLayout.call("update_state", node_event.node, node_event.component, node_event.event)
	
	var components = Studio.active_widget.get_layout().get_components()
	_populate_panels(components)
	
	_apply_area_config(%WidgetGraphNode, "main")
	%WidgetGraphNode.dragged.connect(_on_dragged.bind(%WidgetGraphNode, "main"))
	%WidgetGraphNode.resize_end.connect(_on_area_resized.bind("main"))
	
	_apply_area_config(%WidgetStoreNode, "shop")
	%WidgetStoreNode.dragged.connect(_on_dragged.bind(%WidgetStoreNode, "shop"))
	%WidgetStoreNode.resize_end.connect(_on_area_resized.bind("shop"))
	
	_apply_area_config(%WidgetStoreListItemNode, "shop_list_item")
	%WidgetStoreListItemNode.dragged.connect(_on_dragged.bind(%WidgetStoreListItemNode, "shop_list_item"))
	%WidgetStoreListItemNode.resize_end.connect(_on_area_resized.bind("shop_list_item"))
	
	# addons
	var addons = Studio.active_widget.get_logic().get_configured_addons()
	%StoreLogicCheckButton.button_pressed = addons.has(Constants.Addon.SHOP)
	
	# don't let initial template / load events flood the undo stack
	Studio.layout_history.clear()

func _apply_area_config(graph_node: GraphNode, area: String) -> void:
	var metadata = Studio.active_widget.get_layout().get_metadata()
	var config: Dictionary = metadata.get("%s_config" % area, {})
	if config.has("position_offset"):
		graph_node.position_offset = config.get("position_offset")
	if config.has("size"):
		graph_node.size = config.get("size")

func _on_edit_shop_offerings_button_pressed() -> void:
	var scene = load("res://studio/addons/shop/shop_configuration.tscn").instantiate()
	Display.show(self, "Configure Shop", scene, Vector2(400, 600), true, _on_shop_close_requested.bind(scene))
	scene.load_widget_data()

func _on_shop_close_requested(window: Window, scene: Node) -> void:
	scene.save_shop_items()
	window.queue_free()

func _on_area_changed(area: String, value_key: String, value: Variant) -> void:
	var metadata = Studio.active_widget.get_layout().get_metadata()
	var config_key = "%s_config" % area
	var config = metadata.get(config_key, {})
	config.set(value_key, value)
	metadata.set(config_key, config)
	Studio.active_widget.get_layout().set_metadata(metadata)

func _on_area_resized(new_size: Vector2, area: String) -> void:
	_on_area_changed(area, "size", new_size)

func _on_dragged(_from: Vector2, _to:Vector2, node: GraphNode, area: String) -> void:
	_on_area_changed(area, "position_offset", node.position_offset)
