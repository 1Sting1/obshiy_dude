extends Area2D

signal collected

var taken: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var sprite = $Sprite2D
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if taken or not body is CharacterBody2D:
		return
	taken = true
	collected.emit()
