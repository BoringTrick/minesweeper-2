extends Node2D

@onready var numberLayer = $minesNumbersLayer
@onready var minesCoverLayer = $minesCoverLayer

#useful resources:
# https://forum.godotengine.org/t/how-to-declare-2d-arrays-matrices-in-gdscript/38638/5
# https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972
# https://www.geeksforgeeks.org/cpp/cpp-implementation-minesweeper-game/

var x_size = 10
var y_size = 10
var mineCount = 17
var cells  = x_size * y_size

var gridArray = []

func isValid(row, col):
	return (row >= 0) and (row < x_size) and (col >= 0) and (col < y_size)

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
				var dx = [-1, -1, -1, 0, 0, 1, 1, 1]
				var dy = [-1, 0, 1, -1, 1, -1, 0, 1]
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
