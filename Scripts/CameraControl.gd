extends Camera2D

const ZOOM_MAX = Vector2(0.1, 0.1)
const ZOOM_MIN = Vector2(2,2)

func _process(delta):
	if Input.is_action_just_released("zoomIn") and zoom < ZOOM_MIN :
		zoom *= Vector2(1.5,1.5)
		
	if Input.is_action_just_released("zoomOut") and zoom > ZOOM_MAX:
		zoom /= Vector2(1.5,1.5)
		
	if Input.is_action_pressed("panLeft"):
		offset.x -= 300 * delta
	if Input.is_action_pressed("panRight"):
		offset.x += 300 * delta
	if Input.is_action_pressed("panDown"):
		offset.y += 300 * delta
	if Input.is_action_pressed("panUp"):
		offset.y -= 300 * delta
