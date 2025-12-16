extends Node2D

@onready var numberLayer = $minesNumbersLayer
@onready var coverLayer = $minesCoverLayer
@onready var camera = $minesNumbersLayer/camera
@onready var timerLabel = $uiLayer/timerLabel
@onready var flagLabel = $uiLayer/flagsLeftLabel
@onready var endMenuStats = $endMenuLayer/endMenu/vBoxContainer/marginContainer/vBoxContainer/stats
@onready var endMenuLabel = $endMenuLayer/endMenu/vBoxContainer/endLabel
@onready var endMenu = $endMenuLayer/endMenu
@onready var mouseHitbox = $mouseLayer/mouseHitbox

# useful resources:
# https://forum.godotengine.org/t/how-to-declare-2d-arrays-matrices-in-gdscript/38638/5
# https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972
# https://www.geeksforgeeks.org/cpp/cpp-implementation-minesweeper-game/

# used for flag amount counter in top left
var flagsLeft = gameManager.mineCount

# used for the tiles around a tile calculation in various contexts
var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
var dy = [-1, 0, 1, -1, 1, -1, 0, 1]

# the current gamemode scene loaded in
var gamemodeScene

# backend array that stores mines and numbers
var gridArray = []

# ENEMIES GAMEMODE: difficulty arrays, used for enemies for specific difficulties
var easyEnemies = ["Mouth", "Nose"]
var mediumEnemies = ["Eye", "Ear"]
var hardEnemies = ["Ritalin", "Groni", "EvilMan"]

# returns true if the input row and column are inside the board size
func isValid(row, col):
	return (row >= 0) and (row < gameManager.xSize) and (col >= 0) and (col < gameManager.ySize)

# utility function to update the flag text in the corner
func changeFlagAmount(amount):
	flagsLeft += amount
	flagLabel.text = "Flags Remaining: " + str(flagsLeft)

# recursive function which reveals the neighbors of a tile
# if the neighbor is a 0, recurse and reveal its neighbors
func revealNeighbors(row, col):
	for d in range(0, 8, 1):
		# the row and col checked use the dx and dy arrays 
		# to check all 8 touching tiles via addition
		var newRow = row + dx[d]
		var newCol = col + dy[d]
		if (isValid(newRow, newCol)):
			# if the cover tile isn't empty (very important, infinite loop if not here)
			if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) != Vector2i(-1, -1):
				if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) == Vector2i(1, 1):
					changeFlagAmount(1)
				coverLayer.erase_cell(Vector2i(newRow, newCol))
				gameManager.tilesLeft -= 1
				# emit a signal when tile revealed via neighbor reveal
				gameManager.emit_signal("tileRevealed", gridArray[(newCol * gameManager.xSize) + newRow], "neighborRevealed")
				if gridArray[(newCol * gameManager.xSize) + newRow] == 0:
					revealNeighbors(newRow, newCol)

# function which adds a mine to the array (mines are ID -1)
# will recurse if it tries to place a mine at the clickedTile or
# where there's already a mine
func addMine(clickedTile):
	var mineX = randi() % (gameManager.xSize)
	var mineY = randi() % (gameManager.ySize)
	if gridArray[(mineY * gameManager.xSize) + mineX] == -1 or Vector2i(mineX, mineY) == clickedTile:
		addMine(clickedTile)
	else:
		# extreme difficulty: first tile should be a 0
		if gameManager.difficulty != "Extreme":
			gridArray[(mineY * gameManager.xSize) + mineX] = -1
		else:
			var mineIsInRange = false
			for d in range(0, 8, 1):
				var newRow = clickedTile.x + dx[d]
				var newCol = clickedTile.y + dy[d]
				if (isValid(newRow, newCol)):
					# if a mine is found in range set to true
					if Vector2i(mineX, mineY) == Vector2i(newRow, newCol):
						mineIsInRange = true
			# recurse if a mine was within start tile range
			if mineIsInRange == true:
				addMine(clickedTile)
			else:
				gridArray[(mineY * gameManager.xSize) + mineX] = -1

# set common stats for the end screen for winning and losing
func populateEndScreen():
	endMenuStats.text += "\nGamemode: " + gameManager.gamemode
	endMenuStats.text += "\nDifficulty: " + gameManager.difficulty
	endMenuStats.text += "\nGrid Size: " + str(gameManager.xSize) + "x" + str(gameManager.ySize)
	endMenuStats.text += "\nMine Amount: " + str(gameManager.mineCount)
	if gameManager.gamemode != "Classic":
		endMenuStats.text += gamemodeScene.endScreenText("common")

# set the game to the game over state and show all mines + incorrect flags
func gameOver(incorrectTile):
	if gameManager.gameState == "playing":
		gameManager.updateState("ended")
		var incorrectFlags = 0
		if isValid(incorrectTile.x, incorrectTile.y):
			numberLayer.set_cell(incorrectTile, 0, Vector2i(3, 1), 0)
		for y in gameManager.ySize:
			for x in gameManager.xSize:
				if Vector2i(x, y) != incorrectTile and gridArray[(y * gameManager.xSize) + x] == -1 and coverLayer.get_cell_atlas_coords(Vector2i(x, y)) != Vector2i(1,1):
					coverLayer.erase_cell(Vector2i(x, y))
				elif gridArray[(y * gameManager.xSize) + x] != -1 and coverLayer.get_cell_atlas_coords(Vector2i(x, y)) == Vector2i(1,1):
					coverLayer.set_cell(Vector2i(x, y), 0, Vector2i(4, 1), 0)
					incorrectFlags += 1
		endMenuLabel.text = "Game Over"
		if gameManager.hideGameTimer == false:
			endMenuStats.text += "\nTime Played: %02d:%02d.%02d" % [mins, secs, millis]
		populateEndScreen()
		# bugfix: timed mode has clicked mines count as a correct flag
		if gameManager.gameEndWhenMineHit == true:
			endMenuStats.text += "\nCorrect Flags: " + str((gameManager.mineCount - flagsLeft) - incorrectFlags)
		else:
			endMenuStats.text += "\nCorrect Flags: " + str(((gameManager.mineCount - (flagsLeft + gameManager.minesClicked)) - incorrectFlags))
		endMenuStats.text += "\nIncorrect Flags: " + str(incorrectFlags)
		if gameManager.gamemode != "Classic":
			endMenuStats.text += gamemodeScene.endScreenText("ended")
		endMenu.show()

# runs when the game wins via uncovering every non-mine
# sets the game state to win, sets up the end menu, and handles other win logic
func winGame():
	if gameManager.gameState == "playing":
		gameManager.updateState("won")
		endMenuLabel.text = "You Won!"
		if gameManager.hideGameTimer == false:
			endMenuStats.text = "Time Played: %02d:%02d.%02d" % [mins, secs, millis]
		if gameManager.gamemode != "Classic":
			endMenuStats.text += gamemodeScene.endScreenText("won")
		populateEndScreen()
		endMenu.show()

# this function fills out the board, with the clickedTile being safe
# from mines
func populateBoard(clickedTile):
	# fill the array with nothing to start
	for i in (gameManager.xSize * gameManager.ySize):
		gridArray.append(0)
	
	# add mineCount amount of mines to the field
	for i in gameManager.mineCount:
		addMine(clickedTile)
	
	# this loop generates the minefield beneath the coverLayer
	for y in gameManager.ySize:
		for x in gameManager.xSize:
			# count the mines in neighboring tiles if the tile isn't a mine
			if gridArray[(y * gameManager.xSize) + x] != -1:
				var mineAmount = 0
				for d in range(0, 8, 1):
					var newRow = x + dx[d]
					var newCol = y + dy[d]
					if (isValid(newRow, newCol)):
						if gridArray[(newCol * gameManager.xSize) + newRow] == -1:
							mineAmount = mineAmount + 1
				# give the index an ID equal to mineAmount and set the tile's sprite
				gridArray[(y * gameManager.xSize) + x] = mineAmount
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(mineAmount, 0), 0)
			else:
				# if its a mine, just set the tile sprite to a mine
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(2, 1), 0)
	# set the game to be active after everything's generated
	gameManager.updateState("playing")
	
	if gameManager.gamemode == "Enemies":
		if gameManager.difficulty != "Extreme":
			# add a mouth and nose chaser, make the nose chase the mouth
			var mouthChaserScene = load("res://Prefabs/MouthChaserEnemy.tscn")
			var noseChaserScene = load("res://Prefabs/NoseChaserEnemy.tscn")
			var mouthChaser = mouthChaserScene.instantiate()
			
			mouthChaser.position = $chaserLayer/enemySpawn1.position
			$chaserLayer.add_child(mouthChaser)
			mouthChaser.chase()
			
			var noseChaser = noseChaserScene.instantiate()
			noseChaser.position = $chaserLayer/enemySpawn2.position
			$chaserLayer.add_child(noseChaser)
			noseChaser.initalize(mouthChaser)
			# spawn a random medium enemy if its medium or hard
			if gameManager.difficulty == "Medium" or gameManager.difficulty == "Hard":
				var randomMediumChaser = mediumEnemies.pick_random()
				var mediumChaserScene = load("res://Prefabs/" + randomMediumChaser + "ChaserEnemy.tscn")
				var mediumChaser = mediumChaserScene.instantiate()
				
				mediumChaser.position = $chaserLayer/enemySpawn3.position
				if randomMediumChaser == "Eye":
					mediumChaser.target = mouseHitbox.get_child(0)
					$chaserLayer.add_child(mediumChaser)
					mediumChaser.chase()
				else:
					$chaserLayer.add_child(mediumChaser)
				
				# rng check for if the nose should lock onto the new medium chaser
				if randi_range(0,1) == 1:
					noseChaser.chaserToChase = mediumChaser
				# spawn a random hard enemy if its hard
				if gameManager.difficulty == "Hard":
					var randomHardChaser = hardEnemies.pick_random()
					var hardChaserScene = load("res://Prefabs/" + randomHardChaser + "ChaserEnemy.tscn")
					var hardChaser = hardChaserScene.instantiate()
					
					hardChaser.position = $chaserLayer/enemySpawn4.position
					hardChaser.target = mouseHitbox.get_child(0)
					$chaserLayer.add_child(hardChaser)
					if randomHardChaser == "EvilMan":
						hardChaser.chase()
					
					# rng check for if the nose should lock onto evil man
					if randi_range(0,1) == 1 and randomHardChaser == "EvilMan":
						noseChaser.chaserToChase = hardChaser
		else:
			# extreme difficulty: spawn every chaser
			# TODO: this sucks. when gamemode recode happens make
			# a spawnChaser function
			var mouthChaser = load("res://Prefabs/MouthChaserEnemy.tscn").instantiate()
			var noseChaser = load("res://Prefabs/NoseChaserEnemy.tscn").instantiate()
			var eyeChaser = load("res://Prefabs/EyeChaserEnemy.tscn").instantiate()
			var earChaser = load("res://Prefabs/EarChaserEnemy.tscn").instantiate()
			var ritalinChaser = load("res://Prefabs/RitalinChaserEnemy.tscn").instantiate()
			var groniChaser = load("res://Prefabs/GroniChaserEnemy.tscn").instantiate()
			var evilManChaser = load("res://Prefabs/EvilManChaserEnemy.tscn").instantiate()
			
			mouthChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			noseChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			eyeChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			earChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			ritalinChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			groniChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			evilManChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,5))).position
			
			eyeChaser.target = mouseHitbox.get_child(0)
			ritalinChaser.target = mouseHitbox.get_child(0)
			groniChaser.target = mouseHitbox.get_child(0)
			evilManChaser.target = mouseHitbox.get_child(0)
			
			$chaserLayer.add_child(mouthChaser)
			$chaserLayer.add_child(noseChaser)
			$chaserLayer.add_child(eyeChaser)
			$chaserLayer.add_child(earChaser)
			$chaserLayer.add_child(ritalinChaser)
			$chaserLayer.add_child(groniChaser)
			$chaserLayer.add_child(evilManChaser)
			
			mouthChaser.chase()
			eyeChaser.chase()
			evilManChaser.chase()
			
			match randi_range(0,3):
				0:
					noseChaser.initalize(mouthChaser)
				1:
					noseChaser.initalize(eyeChaser)
				2:
					noseChaser.initalize(earChaser)
				3:
					noseChaser.initalize(evilManChaser)

# setup the minefield when script loads
func _ready():
	# change the gamestate
	gameManager.updateState("setup")
	
	# default values for these toggles, can be overridden via a gamemode
	gameManager.gameEndWhenMineHit = true
	gameManager.hideGameTimer = false
	
	# load in the current gamemode
	if gameManager.gamemode != "Classic":
		gamemodeScene = load("res://GameModes/" + str(gameManager.gamemode) + ".tscn").instantiate()
		self.add_child(gamemodeScene)
	
	# set up the tiles left to win the game and reset mines clicked
	gameManager.tilesLeft = (gameManager.xSize * gameManager.ySize) - gameManager.mineCount
	gameManager.minesClicked = 0
	
	# this loop generates cover cells for the entire minefield
	for y in gameManager.ySize:
		for x in gameManager.xSize:
			coverLayer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1), 0)
	
	# centers the camera on the board
	# do NOT ask me why *48 works. I couldn't answer why.
	var usedRect: Rect2i = coverLayer.get_used_rect()
	var cameraRect = camera.get_viewport_rect()
	
	# the int and float is to get rid of a console error for integer division
	var xOffset = int((float(usedRect.size.x - usedRect.position.x) * 48) / 2)
	var yOffset = int((float(usedRect.size.y - usedRect.position.y) * 48) / 2)
	camera.offset = Vector2i(xOffset, yOffset)
	
	# get the ratio of camera size to board size and zoom accordingly
	# the number divided by is the normal x and y cameraRect size / 10
	var xRatio = (cameraRect.size.x / usedRect.size.x) / 115.2
	var yRatio = (cameraRect.size.y / usedRect.size.y) / 64.8
	if xRatio < yRatio:
		camera.zoom = Vector2(xRatio,xRatio)
	else:
		camera.zoom = Vector2(yRatio,yRatio)
	
	# set up the flag label
	changeFlagAmount(0)
	
	# global variable used by gamemodes
	if gameManager.hideGameTimer == true:
		timerLabel.hide()
	
	# hide the chaser layer if the gamemode isn't enemies, hide the mouse if it is
	if gameManager.gamemode != "Enemies":
		$chaserLayer.hide()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# connect the game over signal
	if !gameManager.is_connected("gameOver", onGameOverSignal):
		gameManager.gameOver.connect(onGameOverSignal)
	
	gameManager.updateState("before")

# Variables for the timer on the top left
var timeElapsed = 0.0
var mins = 0.0
var secs = 0.0
var millis = 0.0

# updates the timer and handles input events
func _process(_delta):
	# handles input events (revealing tiles, flagging/unflagging)
	if Input.is_action_just_pressed("revealTile") or Input.is_action_just_pressed("flagTile"):
		if gameManager.gameState == "playing" or gameManager.gameState == "before":
			# get the global mouse position
			var globalMousePos = get_global_mouse_position()
			# convert the global mouse position to local coordinates for the tileMapLayer
			var localMousePos = coverLayer.to_local(globalMousePos)
			# get the tile coordinates in the grid
			var clickedTile = coverLayer.local_to_map(localMousePos)
			
			# handles uncovering and flagging tiles
			if isValid(clickedTile.x, clickedTile.y) and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(-1,-1) and gameManager.gameState == "playing":
				if Input.is_action_just_pressed("revealTile") and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
					coverLayer.erase_cell(clickedTile)
					# emit a signal when tile revealed normally
					gameManager.emit_signal("tileRevealed", gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x], "normalReveal")
					if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] != -1:
						gameManager.tilesLeft -= 1
						# ENEMIES GAMEMODE: signal for action happening for Dr Ear
						if gameManager.gamemode == "Enemies":
							gameManager.emit_signal("clickEvent", mouseHitbox.get_global_mouse_position())
						if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] == 0:
							revealNeighbors(clickedTile.x, clickedTile.y)
					else:
						gameManager.minesClicked += 1
						# global toggle for if the game should end when mine hit
						if gameManager.gameEndWhenMineHit == true:
							gameOver(clickedTile)
						else:
							numberLayer.set_cell(clickedTile, 0, Vector2i(3, 1), 0)
							changeFlagAmount(-1)
				elif Input.is_action_just_pressed("flagTile"):
					# ENEMIES GAMEMODE: signal for action happening for Dr Ear
					if gameManager.gamemode == "Enemies":
						gameManager.emit_signal("clickEvent", mouseHitbox.get_global_mouse_position())
					if coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
						if flagsLeft > 0:
							changeFlagAmount(-1)
							coverLayer.set_cell(clickedTile, 0, Vector2i(1, 1), 0)
					else:
						changeFlagAmount(1)
						coverLayer.set_cell(clickedTile, 0, Vector2i(0, 1), 0)
			elif isValid(clickedTile.x, clickedTile.y) and gameManager.gameState == "before" and Input.is_action_just_pressed("revealTile"):
				populateBoard(clickedTile)
				coverLayer.erase_cell(clickedTile)
				gameManager.tilesLeft -= 1
				# emit a signal when tile revealed normally
				gameManager.emit_signal("tileRevealed", gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x], "firstTile")
				if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] == 0:
					revealNeighbors(clickedTile.x, clickedTile.y)
			
			# ^^^ runs if the above code makes the tilesLeft hit 0
			if gameManager.tilesLeft <= 0:
				winGame()
	
	# ENEMIES GAMEMODE: give the mouse cursor a hitbox
	if gameManager.gamemode == "Enemies":
		mouseHitbox.global_position = mouseHitbox.get_global_mouse_position()
	
	# timer code for the top right timer
	if gameManager.gameState == "playing" and gameManager.hideGameTimer == false:
		timeElapsed += _delta
		mins = timeElapsed / 60
		secs = fmod(timeElapsed, 60)
		millis = fmod(timeElapsed, 1) * 100
		timerLabel.text = "%02d:%02d.%02d" % [mins, secs, millis]

# ---SIGNALS---

# win/loss menu: new board pressed
func _on_new_board_pressed():
	transitionManager.transitionType = transitionManager.state.NONE
	transitionManager.load_scene(gameManager.mainGame)

# win/loss menu: main menu pressed
func _on_main_menu_pressed():
	transitionManager.transitionType = transitionManager.state.FADE
	transitionManager.load_scene(gameManager.titleScreen)

# lose the game when a chaser is hit
func _on_mouse_hitbox_area_entered(area):
	if gameManager.gameState == "playing":
		if area.is_in_group("Enemy"):
			gameOver(Vector2i(-1, -1))

func onGameOverSignal(lossTile):
	gameOver(lossTile)
