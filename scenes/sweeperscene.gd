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
	# loop 8 times
	for d in range(0, 8, 1):
		# the row and col checked use the dx and dy arrays 
		# to check all 8 touching tiles via addition
		var newRow = row + dx[d]
		var newCol = col + dy[d]
		# if its a valid tile...
		if (isValid(newRow, newCol)):
			# if the cover tile isn't empty.. (very important, infinite loop if not here)
			if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) != Vector2i(-1,-1):
				# erase the tile, check if its a 0, and recurse if true
				coverLayer.erase_cell(Vector2i(newRow, newCol))
				if gridArray[(newCol * xSize) + newRow] == 0:
					revealNeighbors(newRow, newCol)

# function which add a mine to the array
func addMine():
	# choose a random tile within the array size
	var mineX = randi() % (xSize)
	var mineY = randi() % (ySize)
	# if the chosen tile is already a mine, recurse the function
	if gridArray[(mineY * xSize) + mineX] == -1:
		addMine()
	else:
		# add a mine (mines are ID -1) if there isn't one
		gridArray[(mineY * xSize) + mineX] = -1

# setup the minefield when script loads
func _ready():
	# fill out the array with 0s to start
	for i in (xSize * ySize):
		gridArray.append(0)
	
	# add mineCount amount of mines to the field
	for i in mineCount:
		addMine()
	
	# this loop generates the visible minefield
	# loop over every entry in the array, rows then columns
	for y in ySize:
		for x in xSize:
			# if the array item isn't a mine..
			if gridArray[(y * xSize) + x] != -1:
				# count how many mines are in neighboring tiles
				var mineAmount = 0
				# loop 8 times
				for d in range(0, 8, 1):
					var newRow = x + dx[d]
					var newCol = y + dy[d]
					# if the calculated neighbor tile is valid
					if (isValid(newRow, newCol)):
						# if it has a mine, add 1 to mineAmount
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
	# wip camera centering code which doesn't work well, fixing soon
	var used_rect: Rect2i = numberLayer.get_used_rect()
	var top_left: Vector2i = to_global(numberLayer.map_to_local(Vector2i(used_rect.position.x,used_rect.position.y)))
	var bottom_right: Vector2i = to_global(numberLayer.map_to_local(Vector2i(used_rect.position.x+used_rect.size.x,used_rect.position.y+used_rect.size.y)))
	
	camera.offset = Vector2((top_left.x+bottom_right.x)/2.0,(top_left.y+bottom_right.y)/2.0) + Vector2(150,150)

# handle input events
func _unhandled_input(event):
	# check if its a mouse button event, its a press, and its the left or right mouse button
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		# get the global mouse position
		var globalMousePos = get_global_mouse_position()
		# convert the global mouse position to local coordinates for the tileMapLayer
		var localMousePos = coverLayer.to_local(globalMousePos)
		# get the tile coordinates in the grid
		var clickedTile = coverLayer.local_to_map(localMousePos)
		
		# handles uncovering and flagging tiles
		# if the clicked tile is within the board range, and it's not revealed yet
		if isValid(clickedTile.x, clickedTile.y) and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(-1,-1):
			# if its a left mouse click and you HAVEN'T clicked a flag
			if event.button_index == MOUSE_BUTTON_LEFT and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
				# uncover the tile and reveal neighbors if it's a 0
				coverLayer.erase_cell(clickedTile)
				if gridArray[(clickedTile.y * xSize) + clickedTile.x] == 0:
					revealNeighbors(clickedTile.x, clickedTile.y)
			# if its a right mouse click
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# if theres not a flag, flag the tile. If there is a flag, unflag the tile
				if coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(1,1):
					coverLayer.set_cell(clickedTile, 0, Vector2i(1, 1), 0)
				else:
					coverLayer.set_cell(clickedTile, 0, Vector2i(0, 1), 0)
		#print("Global mouse position:", globalMousePos)
		#print("Local mouse position:", localMousePos)
		#print("Tile coordinates:", clickedTile)
