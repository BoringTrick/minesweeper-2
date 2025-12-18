extends Area2D

@onready var sprite = $animatedSprite2D
@onready var crosshair = $crosshair
@onready var chaserLine = $chaserLine

# the chaser mr nose should chase (only dr ear, evil man, mr eye, and mr nose are working)
@export var chaserToChase : Area2D

# the chaser's name!
@export var chaserName = "Mr. Nose"

func _ready():
	# Only connect the signal if it isn't already connected.
	if !gameManager.is_connected("chaserMoved", chaser_moved):
		gameManager.chaserMoved.connect(chaser_moved)

# setup the nose to chase whatever chaser is provided
func initalize(chaser):
	# small delay to make the chaser line not flash for a sec
	chaserToChase = chaser
	await get_tree().create_timer(0.1).timeout
	chaserLine.global_position = Vector2(0, 0)
	chaserLine.points[1] = chaserToChase.global_position
	crosshair.global_position = chaserToChase.global_position
	chaserLine.visible = true
	crosshair.visible = true

# signal that connects for whenever a chaser moves
func chaser_moved(chaserObject, chaserPos, chaserSpeed):
	# make sure its our chaser
	if chaserObject == chaserToChase and gameManager.gameState == "playing":
		# chasing logic, essentially chases position sent via the chaser
		# and then sets the crosshair and line to its new position when done
		sprite.play("chasing")
		var tweenSpeed = ((self.global_position - chaserPos).length()) / 1140
		gameManager.chaserMoved.emit(self, self.global_position, tweenSpeed)
		var tweenAttack = get_tree().create_tween().set_parallel(true)
		tweenAttack.tween_property(self, "global_position", chaserPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		tweenAttack.tween_property(crosshair, "global_position", chaserPos, tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		tweenAttack.tween_property(chaserLine, "global_position", Vector2(0, 0), tweenSpeed)#.set_trans(Tween.TRANS_BOUNCE)
		await tweenAttack.finished
		crosshair.visible = false
		chaserLine.visible = false
		sprite.play("still")
		if (chaserSpeed - tweenSpeed) > 0:
			await get_tree().create_timer(chaserSpeed - tweenSpeed).timeout
		if gameManager.gameState == "playing":
			chaserLine.points[1] = chaserToChase.global_position
			crosshair.global_position = chaserToChase.global_position
			crosshair.visible = true
			chaserLine.visible = true

# constantly set the first point to itself, and end chase if the game ended
func _physics_process(_delta):
	chaserLine.points[0] = self.global_position
	if gameManager.gameState != "playing":
		chaserToChase = null
		crosshair.visible = false
		chaserLine.visible = false
