extends Area2D

@onready var movementTween : Tween

@export var target : CollisionShape2D = null

func _process(_delta):
	if target != null and gameManager.gameState == "playing":
		# check if the movement tween exists, and end if exists
		# this is so we dont make multiple overlapping tweens
		if movementTween: 
			movementTween.kill()
			movementTween = null
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", target.global_position, 1.25)
		movementTween = tween
	else:
		# if no more target stop moving and kill the movement tween
		if movementTween: 
			movementTween.kill()
			movementTween = null
