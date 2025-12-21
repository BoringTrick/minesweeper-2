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
	# connect the game over signal
	if !gameManager.is_connected("gameOver", onGameOver):
		gameManager.gameOver.connect(onGameOver)
	chaserLine.global_position = Vector2(0, 0)
	attackTimer.wait_time = attackInterval
	warningTimer.wait_time = attackInterval - 0.80
	# small delay to make the chaser line not flash for a sec
	await get_tree().create_timer(0.01).timeout
	if gameManager.gameState == "playing":
		chaserLine.visible = true
		crosshair.visible = true
		var screenSize = get_viewport().get_visible_rect().size
		# set first target pos
		targetPos =  Vector2(randi_range(0, screenSize.x), randi_range(0, screenSize.y))
		attackTimer.start()
		warningTimer.start()

# constantly make the first point the chaser's position
func _process(_delta):
	chaserLine.points[0] = self.global_position
	if gameManager.gameState == "playing":
		if chaserLine.get_point_count() < 2:
			chaserLine.add_point(targetPos, 1)
		else:
			chaserLine.set_point_position(1, targetPos)
		crosshair.global_position = targetPos

# play the warning animation when the warning needs to happen
func _on_warning_timer_timeout():
	if gameManager.gameState == "playing":
		sprite.play("warning")

# attack when the attack timer runs out, and restart the timer
func _on_attack_timer_timeout():
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
		# prevent index out of bounds error
		if chaserLine.get_point_count() == 2:
			chaserLine.remove_point(1)
		var screenSize = get_viewport().get_visible_rect().size
		# choose new target pos
		targetPos =  Vector2(randi_range(0, screenSize.x), randi_range(0, screenSize.y))
		attackTimer.start()
		warningTimer.start()
		# small delay to make the chaser line stay visible again
		# (and check to make sure it doesnt re-enable if game ends)
		await get_tree().create_timer(0.01).timeout
		if gameManager.gameState == "playing":
			chaserLine.visible = true
			crosshair.visible = true

# set to inactive when the game ends
func onGameOver(_tile):
	attackTimer.stop()
	warningTimer.stop()
	chaserLine.visible = false
	crosshair.visible = false
	# prevent index out of bounds error
	if chaserLine.get_point_count() == 2:
		chaserLine.remove_point(1)
	sprite.play("still")
