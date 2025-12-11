extends Area2D

@onready var sprite = $animatedSprite2D
@onready var crosshair = $crosshair
@onready var chaserLine = $chaserLine

@export var cooldownTime = 3.25

# debounce to make it so mr ear only attacks while not under cooldown
var isBusy = false

func _ready():
	# Only connect the signal if it isn't already connected.
	if !gameManager.is_connected("clickEvent", moveToPos):
		gameManager.clickEvent.connect(moveToPos)

# signal that connects for whenever a click event happens
func moveToPos(clickPos):
	# make sure dr ear isnt busy
	if gameManager.gameState == "playing" and isBusy == false:
		isBusy = true
		chaserLine.points[1] = clickPos
		crosshair.global_position = clickPos
		chaserLine.global_position = Vector2(0, 0)
		chaserLine.visible = true
		crosshair.visible = true
		# very simple chase to the clicked position logic
		var tweenSpeed = ((self.global_position - clickPos).length()) / 950
		gameManager.chaserMoved.emit(self, self.global_position, tweenSpeed)
		var tweenAttack = get_tree().create_tween().set_parallel(true)
		tweenAttack.tween_property(self, "global_position", clickPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		tweenAttack.tween_property(crosshair, "global_position", clickPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		tweenAttack.tween_property(chaserLine, "global_position", Vector2(0, 0), tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		await tweenAttack.finished
		
		crosshair.visible = false
		chaserLine.visible = false
		
		# shaking logic with some parameters for it, plays a shake anim
		# when it reaches the target pos
		var shakeTween = get_tree().create_tween()
		var shakeLimit = 25
		var shakeTime = 0.05
		var shakeAmount = 15

		for i in shakeAmount:
			shakeTween.tween_property(self, "global_position", (self.global_position + Vector2(randf_range(-shakeLimit, shakeLimit), randf_range(-shakeLimit, shakeLimit))), shakeTime)
		await shakeTween.finished
		
		# wait time for the cooldown
		sprite.play("cooldown")
		await get_tree().create_timer(cooldownTime).timeout
		isBusy = false
		sprite.play("default")

# constantly set the first point to itself, and end chase if the game ended
func _physics_process(_delta):
	chaserLine.points[0] = self.global_position
