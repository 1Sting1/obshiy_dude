extends AnimatableBody2D

var move_offset: Vector2 = Vector2.ZERO
var move_speed: float = 0.0

var origin: Vector2
var phase: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	origin = position
	phase = randf() * TAU

func _physics_process(delta: float) -> void:
	if move_speed <= 0 or move_offset == Vector2.ZERO:
		return
	phase += delta * move_speed
	position = origin + move_offset * sin(phase)
