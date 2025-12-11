extends Area2D

@onready var sprite = $Sprite2D

@export var target : CollisionShape2D = null

func _process(_delta):
	if target != null and gameManager.gameState == "playing":
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", target.global_position, 1.25)
		await tween.finished
