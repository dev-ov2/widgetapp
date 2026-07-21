class_name LandingPage
extends Control

enum Action { WIDGETS, MARKETPLACE, STUDIO }

signal action_pressed(action: Action)

func _ready() -> void:
	%WidgetsCard.pressed.connect(action_pressed.emit.bind(Action.WIDGETS))
	%MarketplaceCard.pressed.connect(action_pressed.emit.bind(Action.MARKETPLACE))
	%StudioCard.pressed.connect(action_pressed.emit.bind(Action.STUDIO))
	
	%HideOnStartupCheck.button_pressed = AppSettings.get_hide_on_startup()
	%LaunchOnStartupCheck.button_pressed = AppSettings.get_launch_on_startup()
	%KeyRepeatCheck.button_pressed = AppSettings.get_key_repeat_enabled()
	
	%HideOnStartupCheck.toggled.connect(_on_hide_on_startup_toggled)
	%LaunchOnStartupCheck.toggled.connect(_on_launch_on_startup_toggled)
	%KeyRepeatCheck.toggled.connect(_on_key_repeat_toggled)

func _on_hide_on_startup_toggled(pressed: bool) -> void:
	AppSettings.set_hide_on_startup(pressed)

func _on_launch_on_startup_toggled(pressed: bool) -> void:
	AppSettings.set_launch_on_startup(pressed)

func _on_key_repeat_toggled(pressed: bool) -> void:
	AppSettings.set_key_repeat_enabled(pressed)
	GlobalKeyBridge.set_key_repeat_enabled(pressed)
