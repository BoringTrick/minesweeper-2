extends TileMapLayer

var x_size = 1
var y_size = 20
var mineCount = 8
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
				self.set_cell(Vector2i(x, y), 0, Vector2i(mineAmount, 0), 0)
			else:
				self.set_cell(Vector2i(x, y), 0, Vector2i(2, 1), 0)
