extends TileMapLayer

@onready var camera = $"../camera"

# title screen board size (probably dont touch this)
var xSize = 50
var ySize = 50
var mineCount = 500

# used for the tiles around a tile calculation in various contexts
var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
var dy = [-1, 0, 1, -1, 1, -1, 0, 1]

# backend array that stores mines and numbers
var gridArray = []

# returns true if the input row and column are inside the board size
func isValid(row, col):
	return (row >= 0) and (row < xSize) and (col >= 0) and (col < ySize)

# function which adds a mine to the array (mines are ID -1)
# will recurse if there's already a mine
func addMine():
	var mineX = randi() % (xSize)
	var mineY = randi() % (ySize)
	if gridArray[(mineY * xSize) + mineX] == -1:
		addMine()
	else:
		gridArray[(mineY * xSize) + mineX] = -1

# generates board and clears all 0s
func _ready():
	# fill the array with nothing to start
	for i in (xSize * ySize):
		gridArray.append(0)
	
	# add mineCount amount of mines to the field
	for i in mineCount:
		addMine()
	
	# this loop generates the minefield and covers it on the same layer
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
				# give the index an ID equal to mineAmount
				gridArray[(y * xSize) + x] = mineAmount
			# set all tiles to cover sprite
			set_cell(Vector2i(x, y), 0, Vector2i(0, 1), 0)
	
	# this loop goes over the array again and uncovers all 0s
	for y in ySize:
		for x in xSize:
			if gridArray[(y * xSize) + x] == 0:
				set_cell(Vector2i(x, y), 0, Vector2i(0, 0), 0)
				for d in range(0, 8, 1):
					var newRow = x + dx[d]
					var newCol = y + dy[d]
					if (isValid(newRow, newCol)):
						# set the sprite to its underlying number
						set_cell(Vector2i(newRow, newCol), 0, Vector2i(gridArray[(newCol * xSize) + newRow], 0), 0)
						
	# 12, 7: the very corner of the screen
	camera.offset = Vector2((24 * (16 * 3)), ((14 * (16 * 3)) - 12))
