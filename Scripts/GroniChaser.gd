extends Area2D

@onready var movementTween : Tween

# the chaser's name!
@export var chaserName = "Groni"

func _process(_delta):
	if gameManager.gameState == "playing":
		# check if the movement tween exists, and end if exists
		# this is so we dont make multiple overlapping tweens
		if movementTween: 
			movementTween.kill()
			movementTween = null
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", self.get_global_mouse_position(), 1.5)
		movementTween = tween
	else:
		# if no more target stop moving and kill the movement tween
		if movementTween: 
			movementTween.kill()
			movementTween = null
