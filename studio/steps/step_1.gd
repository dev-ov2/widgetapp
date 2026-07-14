extends Control

signal loading_changed(loading: bool)

const TemplateTypes: PackedStringArray = ["Amusing Musings"]

var user_widget_metadata: Array[WidgetMetadata]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO uncomment when we have templates
	#for type in TemplateTypes:
		#%TemplateList.add_item(type)
	
	user_widget_metadata = IO.get_user_widgets()
	for metadata in user_widget_metadata:
		%ExistingList.add_item(metadata.get_name())

func on_next() -> void:
	print("Next pressed")

func _on_template_list_item_selected(index: int) -> void:
	loading_changed.emit(true)
	
	# TODO still do templates
	var _template_name = %TemplateList.get_item_text(index)
	
	if index == 0: # starting from scratch
		var metadata = IO.create_widget_draft()
		
		Studio.active_widget = IO.get_widget_data(metadata)
		loading_changed.emit(false)

func _on_existing_list_item_selected(index: int) -> void:
	loading_changed.emit(true)
	var widget_name = %ExistingList.get_item_text(index)
	var selected_widget_metadata
	for widget in user_widget_metadata:
		if widget.get_name() == widget_name:
			selected_widget_metadata = widget
			break
	
	Studio.active_widget = IO.get_widget_data(selected_widget_metadata)
	loading_changed.emit(false)
