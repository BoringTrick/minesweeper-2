extends Node2D

@onready var numberLayer = $minesNumbersLayer
@onready var coverLayer = $minesCoverLayer

#useful resources:
# https://forum.godotengine.org/t/how-to-declare-2d-arrays-matrices-in-gdscript/38638/5
# https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972
# https://www.geeksforgeeks.org/cpp/cpp-implementation-minesweeper-game/

var x_size = 10
var y_size = 10
var mineCount = 17
var cells  = x_size * y_size

# used for the tiles around a tile calculation in various contexts
var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
var dy = [-1, 0, 1, -1, 1, -1, 0, 1]

var gridArray = []

func isValid(row, col):
	return (row >= 0) and (row < x_size) and (col >= 0) and (col < y_size)

func revealNeighbors(row, col,):
	for d in range(0, 8, 1):
		var newRow = row + dx[d]
		var newCol = col + dy[d]
		if (isValid(newRow, newCol)):
			if coverLayer.get_cell_atlas_coords(Vector2i(newRow, newCol)) != Vector2i(-1,-1):
				coverLayer.erase_cell(Vector2i(newRow, newCol))
				if gridArray[(newCol * x_size) + newRow] == 0:
					revealNeighbors(newRow, newCol)

func populateMines():
	var mineX = randi() % (x_size)
	var mineY = randi() % (y_size)
	var idx = (mineY * x_size) + mineX
	if gridArray[idx] == -1:
		populateMines()
	else:
		gridArray[idx] = -1

func _ready():
	for i in cells:
		gridArray.append(0)
		
	for i in mineCount:
		populateMines()
	
	for y in y_size:
		for x in x_size:
			if gridArray[(y * x_size) + x] != -1:
				var mineAmount = 0
				for d in range(0, 8, 1):
					var newRow = x + dx[d]
					var newCol = y + dy[d]
					if (isValid(newRow, newCol)):
						if gridArray[(newCol * x_size) + newRow] == -1:
							mineAmount = mineAmount + 1
				gridArray[(y * x_size) + x] = mineAmount
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(mineAmount, 0), 0)
			else:
				numberLayer.set_cell(Vector2i(x, y), 0, Vector2i(2, 1), 0)
			coverLayer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1), 0)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Get the global mouse position
		var globalMousePos = get_global_mouse_position()
		
		# Convert the global mouse position to the local coordinate system of the TileMapLayer
		var localMousePos = coverLayer.to_local(globalMousePos)
		
		# Get the tile coordinates in the grid
		var clickedTile = coverLayer.local_to_map(localMousePos)
		
		if isValid(clickedTile.x, clickedTile.y) and coverLayer.get_cell_atlas_coords(clickedTile) != Vector2i(-1,-1):
			coverLayer.erase_cell(clickedTile)
			if gridArray[(clickedTile.y * x_size) + clickedTile.x] == 0:
				revealNeighbors(clickedTile.x, clickedTile.y)
		
		print("Global mouse position:", globalMousePos)
		print("Local mouse position:", localMousePos)
		print("Tile coordinates:", clickedTile)
