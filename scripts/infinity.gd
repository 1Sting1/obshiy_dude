extends Node2D

signal health_changed(value: int)

var camera: Camera2D
var player: CharacterBody2D

@onready var platforms = $platforms
@onready var spawn = $Spawn

@export var platform_scene: PackedScene
@export var pineapple_scene: PackedScene
@export var offscreen_distance: float = 300.
@export var min_gap: float = 50
@export var max_gap: float = 150
@export var min_y: float = 300
@export var max_y: float = 500

@export var max_health: int = 3
@export var fall_y: float = 700
@export var finish_distance: float = 4000
@export var time_to_max_difficulty: float = 120
@export var hard_min_gap: float = 110
@export var hard_max_gap: float = 220
@export var easy_step_y: float = 80
@export var hard_step_y: float = 150
@export var easy_move_chance: float = 0.1
@export var hard_move_chance: float = 0.8
@export var easy_move_speed: float = 1.0
@export var hard_move_speed: float = 3.0
@export var easy_move_amplitude: float = 30
@export var hard_move_amplitude: float = 90

var spawned: Array[Node] = []
var right_x: float = 0
var left_x: float = 0
var last_y: float = 0

var health: int = 0
var run_time: float = 0
var difficulty: float = 0
var laps: int = 0
var finish_spawned: bool = false
var pineapple: Node2D = null
var last_platform: Node2D = null

func _ready() -> void:
	health = max_health
	build_start()

func _process(delta: float) -> void:
	if camera == null or player == null or platform_scene == null:
		return
	run_time += delta
	difficulty = clamp(run_time / time_to_max_difficulty, 0.0, 1.0)

	print("Platforms", spawned.size())
	var screen_size = get_viewport_rect().size
	var camera_pos = camera.global_position
	var half_w = screen_size.x/2
	var left_edge = camera_pos.x - half_w
	var right_edge = camera_pos.x + half_w
	while not finish_spawned and right_x < right_edge + offscreen_distance:
		if right_x - spawn.position.x >= finish_distance:
			spawn_finish()
		else:
			spawn_next()

	for i in range(spawned.size()-1, -1, -1):
		var platform = spawned[i]
		if platform.position.x < left_edge - offscreen_distance:
			platform.queue_free()
			spawned.remove_at(i)

	track_floor()
	if player.global_position.y > fall_y:
		on_fall()

func build_start():
	for platform in spawned:
		platform.queue_free()
	spawned.clear()
	if pineapple:
		pineapple.queue_free()
		pineapple = null
	finish_spawned = false
	last_platform = null
	last_y = spawn.position.y + 100
	for i in 3:
		create_platform(spawn.position.x + (i - 1) * 48, last_y)
	right_x = spawn.position.x + 48

func spawn_next():
	var gap = randf_range(lerp(min_gap, hard_min_gap, difficulty), lerp(max_gap, hard_max_gap, difficulty))
	var step = lerp(easy_step_y, hard_step_y, difficulty)
	var offset = Vector2.ZERO
	var speed = 0.0
	if randf() < lerp(easy_move_chance, hard_move_chance, difficulty):
		var amplitude = lerp(easy_move_amplitude, hard_move_amplitude, difficulty)
		speed = lerp(easy_move_speed, hard_move_speed, difficulty) * randf_range(0.8, 1.2)
		if randf() < 0.5:
			offset = Vector2(amplitude, 0)
		else:
			offset = Vector2(0, amplitude)
	var x = right_x + gap + offset.x
	var y = clamp(last_y + randf_range(-step, step), min_y + offset.y, max_y - offset.y)
	create_platform(x, y, offset, speed)
	right_x = x + offset.x
	last_y = y

func spawn_finish():
	var x = right_x + min_gap
	var y = clamp(last_y, min_y, max_y)
	for i in 3:
		create_platform(x + i * 48, y)
	right_x = x + 96
	finish_spawned = true
	if pineapple_scene:
		pineapple = pineapple_scene.instantiate()
		pineapple.position = Vector2(x + 48, y - 40)
		pineapple.collected.connect(on_pineapple_collected)
		add_child(pineapple)

func on_pineapple_collected():
	laps += 1
	restart_lap.call_deferred()

func restart_lap():
	build_start()
	respawn_player(spawn.global_position)

func track_floor():
	if not player.is_on_floor():
		return
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()
		if collision.get_normal().y < -0.7 and collider in spawned:
			last_platform = collider

func on_fall():
	health -= 1
	if health <= 0:
		health = max_health
		run_time = 0
		difficulty = 0
		laps = 0
		build_start()
		respawn_player(spawn.global_position)
	else:
		respawn_player(safe_position())
	health_changed.emit(health)

func safe_position() -> Vector2:
	var target_x = player.global_position.x
	if is_instance_valid(last_platform):
		target_x = last_platform.global_position.x
	var best: Node2D = null
	for platform in spawned:
		if platform.move_speed > 0:
			continue
		if best == null or abs(platform.global_position.x - target_x) < abs(best.global_position.x - target_x):
			best = platform
	if best == null:
		return spawn.global_position
	return best.global_position + Vector2(0, -60)

func respawn_player(pos: Vector2):
	player.global_position = pos
	player.velocity = Vector2.ZERO

func create_platform(x: float, y: float, offset: Vector2 = Vector2.ZERO, speed: float = 0.0) -> Node:
	if not platform_scene:
		return null
	var platform = platform_scene.instantiate()
	platform.position = Vector2(x, y)
	platform.move_offset = offset
	platform.move_speed = speed
	platforms.add_child(platform)
	spawned.append(platform)
	return platform
