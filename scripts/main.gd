extends Node2D

var current_level: Node2D = null
var levels: Dictionary = {
	"Training": preload("res://scenes/levels/training_level.tscn"),
	"Infinity": preload("res://scenes/levels/infinity.tscn")
}

var player = null

@onready var player_scene = preload("res://scenes/characters/physics_dude.tscn")

@onready var world = $world
@onready var menu = $UI/menu
@onready var hud = $UI/Hud

func _ready() -> void:
	player = player_scene.instantiate()
	load_settings()
	menu.update_levels(levels.keys())
	load_level(levels.keys()[0])
	menu.level_changed.connect(load_level)
	add_child(player)
	
func load_level(level_name):
	if current_level:
		current_level.queue_free()
	current_level = levels[level_name].instantiate()
	world.add_child(current_level)
	player.global_position = current_level.get_node("Spawn").global_position
	player.velocity = Vector2.ZERO
	hud.current_health = hud.max_health
	var camera: Camera2D = player.get_node("Camera2D")
	match level_name:
		"Training": camera.enabled = false
		"Infinity": 
			camera.enabled = true
			camera.limit_left = 0
			camera.limit_bottom = 648
			camera.limit_top = 0
			current_level.camera = camera
			current_level.player = player
			hud.current_health = current_level.health
			current_level.health_changed.connect(_on_health_changed)
		
	
func _on_health_changed(value: int):
	hud.current_health = value
	
func pause():
	if not menu.visible:
		get_tree().paused = true
		menu.show()
	else:
		get_tree().paused = false
		menu.hide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause()

func save_settings():
	var config = ConfigFile.new()
	var settings = menu.get_settings()
	for key in settings:
		config.set_value("general", key, settings[key])
		config.save("user://dude.cfg")
	
func load_settings():
	var config = ConfigFile.new()
	var error = config.load("user://dude.cfg")
	if error == OK:
		var settings: Dictionary = {}
		for key in config.get_section_keys("general"):
			settings[key] = config.get_value("general", key, 1.0)
		#var volume = config.get_value("general", "volume", 1.0)
		menu.set_settings(settings)
