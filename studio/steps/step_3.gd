extends Control

func on_next() -> void:
	print("Next pressed")

func _ready() -> void:
	
	pass # Replace with function body.

func _on_text_changed(new_text: String, key: String) -> void:
	var metadata = Studio.active_widget.get_metadata()
	match key:
		"name":
			metadata.set_name(new_text)
		"tags":
			metadata.set_tags(new_text)
		"author":
			metadata.set_author(new_text)
		"version":
			metadata.set_version(new_text)
		"icon":
			metadata.set_icon_path(new_text)

	Studio.active_widget.set_metadata(metadata)

func _on_description_changed() -> void:
	var metadata = Studio.active_widget.get_metadata()
	metadata.set("description", %DescriptionTextEdit.text)


func load_widget_data() -> void:
	var metadata = Studio.active_widget.get_metadata()
	# Package id is assigned at draft creation and must stay fixed (folder + scene packs).
	# LineEdit has no `disabled` — use editable=false and keep the id text readable.
	%IDLineEdit.text = metadata.get_id()
	%IDLineEdit.editable = false
	%IDLineEdit.focus_mode = Control.FOCUS_NONE
	%IDLineEdit.add_theme_color_override("font_uneditable_color", Color(0.75, 0.78, 0.85, 1))
	%NameLineEdit.text = metadata.get_name()
	%NameLineEdit.text_changed.connect(_on_text_changed.bind("name"))
	%DescriptionTextEdit.text = metadata.get_description()
	%DescriptionTextEdit.text_changed.connect(_on_description_changed)
	%TagsLineEdit.text = metadata.get_tags()
	%TagsLineEdit.text_changed.connect(_on_text_changed.bind("tags"))
	%AuthorLineEdit.text = metadata.get_author()
	%AuthorLineEdit.text_changed.connect(_on_text_changed.bind("author"))
	%VersionLineEdit.text = metadata.get_version()
	%VersionLineEdit.text_changed.connect(_on_text_changed.bind("version"))
	%IconLineEdit.text = metadata.get_icon_path()
	%IconLineEdit.text_changed.connect(_on_text_changed.bind("icon"))
