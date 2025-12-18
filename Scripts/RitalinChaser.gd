extends Area2D

@onready var sprite = $animatedSprite2D
@onready var movementTween : Tween

# can be changed by the gamemode script
@export var maxSpeed = 225

# the chaser's name!
@export var chaserName = "Dr. Ritalin"

# main logic loop for chasing the mouse
func _process(_delta):
	if gameManager.gameState == "playing":
		# calculate dr ritalin's speed value. He goes faster the more tiles are revealed
		var newSpeed = (1 - (float(gameManager.tilesLeft) / float(gameManager.xSize * gameManager.ySize))) * maxSpeed
		# calculate what angle dr ritalin is from the target
		# and change his facing angle accordingly
		var facingAngle = (self.get_global_mouse_position() - self.global_position).angle() + PI # add PI so there arent negative values
		facingAngle += PI/8 # shift a bit so left bound doesn;t need to be checked twice
		if facingAngle < PI/4:
			sprite.play("left")
		elif facingAngle < PI/2:
			sprite.play("topleft")
		elif facingAngle < (3*PI)/4:
			sprite.play("top")
		elif facingAngle < PI:
			sprite.play("topright")
		elif facingAngle < (5*PI)/4:
			sprite.play("right")
		elif facingAngle < (3*PI)/2:
			sprite.play("bottomright")
		elif facingAngle < (7*PI)/4:
			sprite.play("bottom")
		elif facingAngle <= 2*PI:
			sprite.play("bottomleft")
			
		# check if the movement tween exists, and end if exists
		# this is so we dont make multiple overlapping tweens
		if movementTween: 
			movementTween.kill()
			movementTween = null
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", self.get_global_mouse_position(), ((self.global_position - self.get_global_mouse_position()).length()) / newSpeed)
		movementTween = tween
	else:
		# if no more target stop moving and kill the movement tween
		if movementTween: 
			movementTween.kill()
			movementTween = null
		sprite.play("center")
