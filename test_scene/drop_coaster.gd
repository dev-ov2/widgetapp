extends Sprite2D

@export var top_position_y: float = 20

@onready var bottom_position_y: float = position.y

var current_speed: float = 0.0
var custom_offset: float = 0.0

func _process(delta: float) -> void:
	# Intelligently roll the offset forward based on our exact current speed
	custom_offset += delta * current_speed
	
	# Keep the offset numbers small so the graphics card doesn't lose precision
	if custom_offset > 1.0:
		custom_offset -= 1.0
		
	if material is ShaderMaterial:
		material.set_shader_parameter("time_offset", custom_offset)

func _ready() -> void:
	current_speed = 0.0
	run_ride_sequence()

func run_ride_sequence() -> void:
	var tween = create_tween().set_loops()
	
	tween.tween_property(self, "position:y", top_position_y, 12)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_interval(8)
		
	tween.tween_property(self, "position:y", bottom_position_y, 6)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN_OUT)
