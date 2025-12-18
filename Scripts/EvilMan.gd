extends Area2D

@onready var sprite = $animatedSprite2D
@onready var crosshair = $crosshair
@onready var chaserLine = $chaserLine

# this can be changed by the gamemode script
@export var turnSpeed : float = 0.85

# the chaser's name!
@export var chaserName = "Evil Man"

var targetPos : Vector2
var startPos : Vector2
var currentDir : String = "right"

# set up position of these when the enemy loads
func _ready():
	chaserLine.global_position = Vector2(0, 0)
	chase()

# chase the mouse !!
func chase():
	var chaseDir : String
	# small delay to make the chaser line not flash for a sec
	await get_tree().create_timer(0.1).timeout
	while gameManager.gameState == "playing":
		# check what longer direction is to the player, x or y and choose that
		# afterwards, choose what direction the chaser needs to turn
		var mousePos = self.get_global_mouse_position()
		if (abs(mousePos.x - self.global_position.x) > abs(mousePos.y - self.global_position.y)):
			targetPos = Vector2(mousePos.x, self.global_position.y)
			if (mousePos.x - self.global_position.x) >= 0:
				chaseDir = "right"
			else:
				chaseDir = "left"
		else:
			targetPos = Vector2(self.global_position.x, mousePos.y)
			if (mousePos.y - self.global_position.y) >= 0:
				chaseDir = "down"
			else:
				chaseDir = "up"
		
		# set the crosshair and line to the target
		chaserLine.set_point_position(1, targetPos)
		crosshair.global_position = targetPos
		chaserLine.visible = true
		crosshair.visible = true
		
		# if the chaser is chasing the same direction, little cooldown
		# if not, slowly turn a specific orientation
		if chaseDir != currentDir:
			currentDir = chaseDir
			var orientationToTurn
			match currentDir:
				"right":
					orientationToTurn = 0
				"left":
					orientationToTurn = 180
				"down":
					orientationToTurn = 90
				"up":
					orientationToTurn = -90
			var tweenTurn = get_tree().create_tween()
			tweenTurn.tween_property(sprite, "rotation_degrees", orientationToTurn, turnSpeed)
			await tweenTurn.finished
			# this + duplicate code in other case is to give him a small
			# grace period before attacking
			sprite.play("attacking")
			await get_tree().create_timer(.5).timeout
		else:
			sprite.play("attacking")
			await get_tree().create_timer(turnSpeed / 12).timeout
			await get_tree().create_timer(.25).timeout
		
		# another check if the game is still active
		if gameManager.gameState == "playing":
			
			# chase to the target
			var tweenSpeed = ((self.global_position - targetPos).length()) / 1500
			gameManager.chaserMoved.emit(self, self.global_position, tweenSpeed)
			var tweenAttack = get_tree().create_tween().set_parallel(true)
			tweenAttack.tween_property(self, "global_position", targetPos, tweenSpeed)
			tweenAttack.tween_property(crosshair, "global_position", targetPos, tweenSpeed)
			tweenAttack.tween_property(chaserLine, "global_position", Vector2(0, 0), tweenSpeed)
			
			await tweenAttack.finished
			
		chaserLine.visible = false
		crosshair.visible = false
		sprite.play("idle")

# constantly make the first point the chaser's position
func _physics_process(_delta):
	chaserLine.points[0] = self.global_position
