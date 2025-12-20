extends Control

@onready var mouseHitbox = $mouseLayer/mouseHitbox

# difficulty arrays, used for difficulty-specific enemies
var easyEnemies = ["Mouth", "Nose"]
var mediumEnemies = ["Eye", "Ear"]
var hardEnemies = ["Ritalin", "Groni", "EvilMan"]
# which chaser killed you
var chaserKill = "None"

# connect some signals if they arent connected already on scene load
func _ready():
	if !gameManager.is_connected("gameStateChanged", onGameStateChange):
		gameManager.gameStateChanged.connect(onGameStateChange)

# sets up the enemies on the board, called once the game begins
func setupEnemies():
	if gameManager.difficulty != "Extreme":
		# EASY OR HIGHER: add a mouth and nose chaser, 
		# make the nose chase the mouth
		var mouthChaser = spawnChaser("Mouth", 1)
		var noseChaser = spawnChaser("Nose", 2)
		noseChaser.initalize(mouthChaser)
		# MEDIUM OR HIGHER: spawn random medium enemy, rng
		# for if nose chases the medium chaser
		if gameManager.difficulty == "Medium" or gameManager.difficulty == "Hard":
			var mediumChaser = spawnChaser(mediumEnemies.pick_random(), 3)
			if randi_range(0,1) == 1:
				noseChaser.chaserToChase = mediumChaser
			# HARD: spawn random hard chaser, if it's evil man
			# rng check for if nose chases it
			if gameManager.difficulty == "Hard":
				var hardChaser = spawnChaser(hardEnemies.pick_random(), 4)
				# rng check for if the nose should lock onto evil man
				if hardChaser.chaserName == "Evil Man" and randi_range(0,1) == 1:
					noseChaser.chaserToChase = hardChaser
	else:
		# EXTREME: spawn every chaser, randomly choose
		# which chaser the nose chases
		var mouthChaser = spawnChaser("Mouth", 0)
		var noseChaser = spawnChaser("Nose", 0)
		var eyeChaser = spawnChaser("Eye", 0)
		var earChaser = spawnChaser("Ear", 0)
		var evilManChaser = spawnChaser("EvilMan", 0)
		spawnChaser("Ritalin", 0)
		spawnChaser("Groni", 0)
		
		# randomly choose a chaser for nose 1 to chase, 
		# make a new nose, and choose a new chaser for nose 2
		# to chase
		var noseCandidates = [mouthChaser, eyeChaser, earChaser, evilManChaser]
		noseChaser.initalize(noseCandidates.pop_at(randi_range(0,(noseCandidates.size() - 1))))
		
		noseCandidates.push_back(noseChaser)
		var noseChaser2 = spawnChaser("Nose", 0)
		noseChaser2.initalize(noseCandidates.pop_at(randi_range(0,(noseCandidates.size() - 1))))

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

# run the setup enemies function when the game starts
func onGameStateChange():
	if gameManager.gameState == "playing":
		setupEnemies()

# kill the player if they hit a chaser, save which chaser killed the player
func _on_mouse_hitbox_area_entered(area):
	if gameManager.gameState == "playing":
		if area.is_in_group("Enemy"):
			chaserKill = area.chaserName
			gameManager.emit_signal("gameOver", Vector2i(-1, -1))
			# for any chasers which do something special when killing
			if area.has_method("onKill"):
				area.onKill()
