extends Area2D

@onready var sprite = $animatedSprite2D
@onready var crosshair = $crosshair
@onready var attackTimer = $attackTimer
@onready var warningTimer = $warningTimer
@onready var chaserLine = $chaserLine

# can be changed by the gamemode script
@export var attackInterval : float = 3.0

# the chaser's name!
@export var chaserName = "Mr. Mouth"

var targetPos : Vector2

# set up position of these when the enemy loads
func _ready():
	chaserLine.global_position = Vector2(0, 0)
	attackTimer.wait_time = attackInterval
	warningTimer.wait_time = attackInterval - 0.80
	chase()

# chase a random point on the screen function
func chase():
	# small delay to make the chaser line not flash for a sec
	await get_tree().create_timer(0.01).timeout
	# lots of checks for the gamestate to make sure it can smoothly cancel anytime
	while gameManager.gameState == "playing":
		attackTimer.start()
		warningTimer.start()
		# get a random part of the screen and choose it as the target
		var screenSize = get_viewport().get_visible_rect().size
		targetPos =  Vector2(randi_range(0, screenSize.x), randi_range(0, screenSize.y))
		# wait for the attack timer, while waiting update the line and crosshair
		while attackTimer.time_left > 0.0 and gameManager.gameState == "playing":
			await get_tree().create_timer(0.01).timeout
			# leftover code from when mouth chasers could be in a scene where they move
			# can activate if thats necessary
			#if target != null:
				#targetPos = get_viewport().get_canvas_transform().affine_inverse() * Vector2(rngX, rngY)
			if chaserLine.get_point_count() < 2:
				chaserLine.add_point(targetPos, 1)
			else:
				chaserLine.set_point_position(1, targetPos)
			crosshair.global_position = targetPos
			chaserLine.visible = true
			crosshair.visible = true
		
		# when the timer expires, start moving the chaser via tweening
		sprite.play("chasing")
		if gameManager.gameState == "playing":
			var tweenSpeed = ((self.global_position - targetPos).length()) / 1140
			gameManager.chaserMoved.emit(self, self.global_position, tweenSpeed)
			var tweenAttack = get_tree().create_tween().set_parallel(true)
			tweenAttack.tween_property(self, "global_position", targetPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
			tweenAttack.tween_property(crosshair, "global_position", targetPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
			tweenAttack.tween_property(chaserLine, "global_position", Vector2(0, 0), tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
			
			await tweenAttack.finished
			sprite.play("still")
			chaserLine.visible = false
			crosshair.visible = false
			chaserLine.remove_point(1)
			#await get_tree().create_timer(0.65).timeout
	attackTimer.stop()
	warningTimer.stop()
	chaserLine.visible = false
	crosshair.visible = false
	# prevent index out of bounds error
	if chaserLine.get_point_count() == 2:
		chaserLine.remove_point(1)
	sprite.play("still")

# constantly make the first point the chaser's position
func _physics_process(_delta):
	chaserLine.points[0] = self.global_position

# play the warning animation when the warning needs to happen
func _on_warning_timer_timeout():
	sprite.play("warning")
