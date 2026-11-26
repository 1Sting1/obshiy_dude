extends Node2D

@export var max_health = 3
@export var health_texture: Texture2D

var current_health: int = max_health:
	set(value):
		current_health = value
		update_health()

func _ready() -> void:
	update_health()

func update_health():
	var container: HBoxContainer = $Panel/HBoxContainer
	if container:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
		
		for i in current_health:
			var health = TextureRect.new()
			health.texture = health_texture
			health.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			container.add_child(health)
		$Panel.visible = current_health > 0
		$Panel.reset_size()
