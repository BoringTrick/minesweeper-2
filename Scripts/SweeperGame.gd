extends Node2D

@onready var numberLayer = $minesNumbersLayer
@onready var coverLayer = $minesCoverLayer
@onready var camera = $minesNumbersLayer/camera
@onready var timerLabel = $uiLayer/timerLabel
@onready var flagLabel = $uiLayer/flagsLeftLabel
@onready var timerIcon = $uiLayer/timedModeIcon
@onready var endMenuStats = $uiLayer/endMenu/vBoxContainer/marginContainer/vBoxContainer/stats
@onready var endMenuLabel = $uiLayer/endMenu/vBoxContainer/endLabel
@onready var endMenu = $uiLayer/endMenu
@onready var timedTimeBonusText = $uiLayer/timedModeTimeBonus
@onready var mouseHitbox = $chaserLayer/mouseHitbox

# useful resources:
# https://forum.godotengine.org/t/how-to-declare-2d-arrays-matrices-in-gdscript/38638/5
# https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972
# https://www.geeksforgeeks.org/cpp/cpp-implementation-minesweeper-game/

# used for flag amount counter in top left
var flagsLeft = gameManager.mineCount

# used for the tiles around a tile calculation in various contexts
var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
var dy = [-1, 0, 1, -1, 1, -1, 0, 1]

# backend array that stores mines and numbers
var gridArray = []

# TIMED GAMEMODE: mines clicked stat and the timer queue for timer add/subtraction
var minesClicked = 0
var timerQueue = 0

# returns true if the input row and column are inside the board size
func isValid(row, col):
	return (row >= 0) and (row < gameManager.xSize) and (col >= 0) and (col < gameManager.ySize)

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
			if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) != Vector2i(-1,-1):
				coverLayer.erase_cell(Vector2i(newRow, newCol))
				gameManager.tilesLeft -= 1
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
		gridArray[(mineY * gameManager.xSize) + mineX] = -1

# set common stats for the end screen for winning and losing
func populateEndScreen():
	endMenuStats.text += "\nGamemode: " + gameManager.gamemode
	endMenuStats.text += "\nDifficulty: " + gameManager.difficulty
	endMenuStats.text += "\nGrid Size: " + str(gameManager.xSize) + "x" + str(gameManager.ySize)
	endMenuStats.text += "\nMine Amount: " + str(gameManager.mineCount)
	if gameManager.gamemode == "Timed":
		endMenuStats.text += "\nMines Hit: " + str(minesClicked)

# set the game to the game over state and show all mines + incorrect flags
func gameOver(incorrectTile):
	if gameManager.gameState == "playing":
		gameManager.updateState("ended")
		var incorrectFlags = 0
		if gameManager.gamemode == "Timed":
			$timer.stop()
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
		if gameManager.gamemode != "Timed":
			endMenuStats.text = "Time Played: %02d:%02d.%02d" % [mins, secs, millis]
		else:
			endMenuStats.text = ""
		populateEndScreen()
		endMenuStats.text += "\nCorrect Flags: " + str((gameManager.mineCount - flagsLeft) - incorrectFlags)
		endMenuStats.text += "\nIncorrect Flags: " + str(incorrectFlags)
		endMenu.show()

# runs when the game wins via uncovering every non-mine
# sets the game state to win, sets up the end menu, and handles other win logic
func winGame():
	if gameManager.gameState == "playing":
		gameManager.updateState("won")
		if gameManager.gamemode == "Timed":
			$timer.stop()
		endMenuLabel.text = "You Won!"
		if gameManager.gamemode != "Timed":
			endMenuStats.text = "Time Played: %02d:%02d.%02d" % [mins, secs, millis]
		else:
			endMenuStats.text = "Time Remaining: %02d.%02d" % [int(timedTimeLeft) % 60, fmod(timedTimeLeft, 1) * 100]
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
		var earChaserScene = preload("res://Prefabs/EarChaserEnemy.tscn")
		var earChaser = earChaserScene.instantiate()
		earChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		$chaserLayer.add_child(earChaser)
		
		#var evilManChaserScene = preload("res://Prefabs/EvilManChaserEnemy.tscn")
		#var evilManChaser = evilManChaserScene.instantiate()
		#evilManChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#evilManChaser.target = $chaserLayer/mouseHitbox/collisionShape2d
		#$chaserLayer.add_child(evilManChaser)
		#evilManChaser.chase()
		
		#var mouthChaserScene = preload("res://Prefabs/MouthChaserEnemy.tscn")
		#var mouthChaser = mouthChaserScene.instantiate()
		#mouthChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#$chaserLayer.add_child(mouthChaser)
		#mouthChaser.chase()
		#var noseChaserScene = preload("res://Prefabs/NoseChaserEnemy.tscn")
		#var noseChaser = noseChaserScene.instantiate()
		#noseChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#$chaserLayer.add_child(noseChaser)
		#noseChaser.initalize(mouthChaser)
		#
		#var noseChaser2 = noseChaserScene.instantiate()
		#noseChaser2.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#$chaserLayer.add_child(noseChaser2)
		#noseChaser2.initalize(noseChaser)
		
		#var ritalinChaserScene = preload("res://Prefabs/RitalinChaserEnemy.tscn")
		#var ritalinChaser = ritalinChaserScene.instantiate()
		#ritalinChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#ritalinChaser.target = $chaserLayer/mouseHitbox/collisionShape2d
		#$chaserLayer.add_child(ritalinChaser)
		
		#var eyeChaserScene = preload("res://Prefabs/EyeChaserEnemy.tscn")
		#var eyeChaser = eyeChaserScene.instantiate()
		#eyeChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#eyeChaser.target = $chaserLayer/mouseHitbox/collisionShape2d
		#$chaserLayer.add_child(eyeChaser)
		#eyeChaser.chase()
		#var noseChaserScene = preload("res://Prefabs/NoseChaserEnemy.tscn")
		#var noseChaser = noseChaserScene.instantiate()
		#noseChaser.position = $chaserLayer.get_node("enemySpawn" + str(randi_range(1,2))).position
		#$chaserLayer.add_child(noseChaser)
		#noseChaser.initalize(eyeChaser)

# setup the minefield when script loads
func _ready():
	# change the gamestate
	gameManager.updateState("setup")
	
	# set up the tiles left to win the game
	gameManager.tilesLeft = (gameManager.xSize * gameManager.ySize) - gameManager.mineCount
	
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
	flagLabel.text = "Flags Remaining: " + str(flagsLeft)
	
	# set up the custom timer label for timed mode
	if gameManager.gamemode == "Timed":
		timerLabel.position = Vector2(441, 23)
		timerIcon.show()
		$timer.wait_time = gameManager.timedStartTime
		timerLabel.text = "%02d.%02d" % [int($timer.wait_time) % 60, fmod($timer.wait_time, 1) * 100]
	
	# hide the chaser layer if the gamemode isn't enemies
	if gameManager.gamemode != "Enemies":
		$chaserLayer.hide()
	
	gameManager.updateState("before")

# Variables for the timer on the top left
var timeElapsed = 0.0
var mins = 0.0
var secs = 0.0
var millis = 0.0
var timedTimeLeft = gameManager.timedStartTime

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
					if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] != -1:
						gameManager.tilesLeft -= 1
						# TIMED GAMEMODE: add time equal to number clicked 
						if gameManager.gamemode == "Timed":
							timerQueue += gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x]
						# ENEMIES GAMEMODE: signal for action happening for Dr Ear
						elif gameManager.gamemode == "Enemies":
							gameManager.emit_signal("clickEvent", mouseHitbox.get_global_mouse_position())
						if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] == 0:
							revealNeighbors(clickedTile.x, clickedTile.y)
					else:
						minesClicked += 1
						# TIMED GAMEMODE: time subtraction on mine hit instead of gameover
						if gameManager.gamemode != "Timed":
							gameOver(clickedTile)
						else:
							numberLayer.set_cell(clickedTile, 0, Vector2i(3, 1), 0)
							if ($timer.time_left + gameManager.timedTimeLossOnMineHit) <= 0:
								timerQueue += gameManager.timedTimeLossOnMineHit
								$timer.start(0.00001)
							else:
								flagsLeft -= 1
								flagLabel.text = "Flags Remaining: " + str(flagsLeft)
								timerQueue += gameManager.timedTimeLossOnMineHit
				elif Input.is_action_just_pressed("flagTile"):
					# ENEMIES GAMEMODE: signal for action happening for Dr Ear
					if gameManager.gamemode == "Enemies":
						gameManager.emit_signal("clickEvent", mouseHitbox.get_global_mouse_position())
					if coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
						if flagsLeft > 0:
							flagsLeft -= 1
							flagLabel.text = "Flags Remaining: " + str(flagsLeft)
							coverLayer.set_cell(clickedTile, 0, Vector2i(1, 1), 0)
					else:
						flagsLeft += 1
						flagLabel.text = "Flags Remaining: " + str(flagsLeft)
						coverLayer.set_cell(clickedTile, 0, Vector2i(0, 1), 0)
			elif isValid(clickedTile.x, clickedTile.y) and gameManager.gameState == "before" and Input.is_action_just_pressed("revealTile"):
				populateBoard(clickedTile)
				coverLayer.erase_cell(clickedTile)
				# TIMED GAMEMODE: start the timer
				if gameManager.gamemode == "Timed":
					$timer.start()
				gameManager.tilesLeft -= 1
				if gridArray[(clickedTile.y * gameManager.xSize) + clickedTile.x] == 0:
					revealNeighbors(clickedTile.x, clickedTile.y)
			
			# ^^^ runs if the above code makes the tilesLeft hit 0
			if gameManager.tilesLeft <= 0:
				winGame()
	
	# TIMED GAMEMODE: timer queue: if multiple timer events happen at
	# the same time they all get processed at once
	# this code also handles the text that appears under the timer
	if timerQueue != 0 and gameManager.gameState == "playing" and gameManager.gamemode == "Timed":
		# cap the time if it's over the max time allowed
		if ($timer.time_left + timerQueue) > gameManager.timedMaxTimeAllowed:
			var amountToCapWith = ($timer.time_left + timerQueue) - gameManager.timedMaxTimeAllowed
			timerQueue = int(floor(timerQueue - amountToCapWith))
		var bonusText = timedTimeBonusText.duplicate()
		$uiLayer.add_child(bonusText)
		if timerQueue > 0:
			bonusText.text = "+" + str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.GREEN)
		elif timerQueue == 0:
			bonusText.text = "+" + str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.WHITE)
		else:
			bonusText.text = str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.RED)
		bonusText.show()
		# use tweens to animate the text appearing under the timer
		var tween = get_tree().create_tween()
		tween.tween_property(bonusText, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1.5)
		tween.parallel().tween_property(bonusText, "position", Vector2(bonusText.position.x, (bonusText.position.y + 35)), 1.5)
		tween.tween_callback(bonusText.queue_free)
		$timer.start($timer.time_left + timerQueue)
		timerQueue = 0
	
	# ENEMIES GAMEMODE: give the mouse cursor a hitbox
	if gameManager.gamemode == "Enemies":
		mouseHitbox.global_position = mouseHitbox.get_global_mouse_position()
	
	# timer code for the top right timer, count up for normal count down for timed
	if gameManager.gameState == "playing":
		if gameManager.gamemode == "Timed":
			timedTimeLeft = $timer.time_left
			timerLabel.text = "%02d.%02d" % [int(timedTimeLeft) % 60, fmod(timedTimeLeft, 1) * 100]
		else:
			timeElapsed += _delta
			mins = timeElapsed / 60
			secs = fmod(timeElapsed, 60)
			millis = fmod(timeElapsed, 1) * 100
			timerLabel.text = "%02d:%02d.%02d" % [mins, secs, millis]

# ---SIGNALS---

# timer mode: when time runs out
func _on_timer_timeout():
	gameOver(Vector2i(-1, -1))

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
