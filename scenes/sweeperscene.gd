extends Node2D

@onready var numberLayer = $minesNumbersLayer
@onready var coverLayer = $minesCoverLayer
@onready var camera = $minesNumbersLayer/Camera2D

# useful resources:
# https://forum.godotengine.org/t/how-to-declare-2d-arrays-matrices-in-gdscript/38638/5
# https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972
# https://www.geeksforgeeks.org/cpp/cpp-implementation-minesweeper-game/

# config for the board, gamemodes/difficulties may edit this
var xSize = 10
var ySize = 10
var mineCount = 17
var gameState = "setup"

# used for the tiles around a tile calculation in various contexts
var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
var dy = [-1, 0, 1, -1, 1, -1, 0, 1]

# backend array that stores mines and numbers
var gridArray = []

# returns true if the input row and column are inside the board size
func isValid(row, col):
	return (row >= 0) and (row < xSize) and (col >= 0) and (col < ySize)

# recursive function which reveals the neighbors of a tile
# if the neighbor is a 0, recurse and reveal its neighbors
func revealNeighbors(row, col,):
	for d in range(0, 8, 1):
		# the row and col checked use the dx and dy arrays 
		# to check all 8 touching tiles via addition
		var newRow = row + dx[d]
		var newCol = col + dy[d]
		if (isValid(newRow, newCol)):
			# if the cover tile isn't empty (very important, infinite loop if not here)
			if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) != Vector2i(-1,-1):
				coverLayer.erase_cell(Vector2i(newRow, newCol))
				if gridArray[(newCol * xSize) + newRow] == 0:
					revealNeighbors(newRow, newCol)

# function which adds a mine to the array (mines are ID -1)
func addMine():
	var mineX = randi() % (xSize)
	var mineY = randi() % (ySize)
	if gridArray[(mineY * xSize) + mineX] == -1:
		addMine()
	else:
		gridArray[(mineY * xSize) + mineX] = -1

# set the game to the game over state and show all mines + incorrect flags
func gameOver(incorrectTile):
	gameState = "ended"
	numberLayer.set_cell(incorrectTile, 0, Vector2i(3, 1), 0)
	for y in ySize:
		for x in xSize:
			if Vector2i(x, y) != incorrectTile and gridArray[(y * xSize) + x] == -1 and coverLayer.get_cell_atlas_coords(Vector2i(x, y)) != Vector2i(1,1):
				coverLayer.erase_cell(Vector2i(x, y))
			elif gridArray[(y * xSize) + x] != -1 and coverLayer.get_cell_atlas_coords(Vector2i(x, y)) == Vector2i(1,1):
				coverLayer.set_cell(Vector2i(x, y), 0, Vector2i(4, 1), 0)

# setup the minefield when script loads
func _ready():
	# fill out the array with 0s to start
	for i in (xSize * ySize):
		gridArray.append(0)
	
	# add mineCount amount of mines to the field
	for i in mineCount:
		addMine()
	
	# this loop generates the visible minefield and covers it
	for y in ySize:
		for x in xSize:
			# count the mines in neighboring tiles if the tile isn't a mine
			if gridArray[(y * xSize) + x] != -1:
				var mineAmount = 0
				for d in range(0, 8, 1):
					var newRow = x + dx[d]
					var newCol = y + dy[d]
					if (isValid(newRow, newCol)):
						if gridArray[(newCol * xSize) + newRow] == -1:
							mineAmount = mineAmount + 1
				# give the index an ID equal to mineAmount and set the tile's sprite
				gridArray[(y * xSize) + x] = mineAmount
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(mineAmount, 0), 0)
			else:
				# if its a mine, just set the tile sprite to a mine
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(2, 1), 0)
			# add a cover cell ontop of the tile
			coverLayer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1), 0)
	
	# centers the camera on the board
	# do NOT ask me why *48 works. I couldn't answer why.
	var usedRect: Rect2i = numberLayer.get_used_rect()
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
	
	gameState = "playing"

# handle input events (revealing tiles, flagging/unflagging)
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		if gameState == "playing":
			# get the global mouse position
			var globalMousePos = get_global_mouse_position()
			# convert the global mouse position to local coordinates for the tileMapLayer
			var localMousePos = coverLayer.to_local(globalMousePos)
			# get the tile coordinates in the grid
			var clickedTile = coverLayer.local_to_map(localMousePos)
			
			# handles uncovering and flagging tiles
			if isValid(clickedTile.x, clickedTile.y) and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(-1,-1):
				if event.button_index == MOUSE_BUTTON_LEFT and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
					coverLayer.erase_cell(clickedTile)
					if gridArray[(clickedTile.y * xSize) + clickedTile.x] == 0:
						revealNeighbors(clickedTile.x, clickedTile.y)
					elif gridArray[(clickedTile.y * xSize) + clickedTile.x] == -1:
						gameOver(clickedTile)
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					if coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
						coverLayer.set_cell(clickedTile, 0, Vector2i(1, 1), 0)
					else:
						coverLayer.set_cell(clickedTile, 0, Vector2i(0, 1), 0)
			#print("Global mouse position:", globalMousePos)
			#print("Local mouse position:", localMousePos)
			#print("Tile coordinates:", clickedTile)
