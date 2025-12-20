extends Control

@onready var mouseHitbox = $mouseLayer/mouseHitbox

var lastChaserSpawned
# which chaser killed you
var chaserKill = "None"

# connect some signals if they arent connected already on scene load
func _ready():
	if !gameManager.is_connected("gameStateChanged", onGameStateChange):
		gameManager.gameStateChanged.connect(onGameStateChange)
	if !gameManager.is_connected("clickEvent", spawnNose):
		gameManager.clickEvent.connect(spawnNose)

# constantly set the hitbox position and hide the mouse
func _process(_delta):
	mouseHitbox.global_position = mouseHitbox.get_global_mouse_position()
	# gets set during process so unpausing the game hides mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# returns which chaser killed the player if applicable
func endScreenText(context):
	var returnText = ""
	if context == "ended":
		returnText = "\nDied To: "
		if chaserKill == "None":
			returnText += "A Mine"
		else:
			returnText += chaserKill
	return returnText

# this function will load a chaser that's passed in
# and place it on the board at the spawnPos node number, returning
# the chaser. if an invalid pos is sent, choose a random one
func spawnChaser(chaser, spawnPos):
	var spawnedChaser = load("res://Prefabs/" + chaser + "ChaserEnemy.tscn").instantiate()
	if spawnPos <= 0 or spawnPos > 5:
		spawnedChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
	else:
		spawnedChaser.position = $chaserLayer.get_node("enemySpawn" + str(spawnPos)).position
	$chaserLayer.add_child(spawnedChaser)
	return spawnedChaser

# --SIGNALS--

func spawnNose(_globalMousePos, _clickedTile, context):
	if context == "tileReveal":
		var newNose = spawnChaser("Nose", 0)
		newNose.initalize(lastChaserSpawned)
		lastChaserSpawned = newNose

# stop the timer if the game ends or wins, start it when playing
func onGameStateChange():
	if gameManager.gameState == "playing":
		lastChaserSpawned = spawnChaser("EvilMan", 0)

# kill the player if they hit a chaser, save which chaser killed the player
func _on_mouse_hitbox_area_entered(area):
	if gameManager.gameState == "playing":
		if area.is_in_group("Enemy"):
			chaserKill = area.chaserName
			gameManager.emit_signal("gameOver", Vector2i(-1, -1))
