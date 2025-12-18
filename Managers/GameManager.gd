extends CanvasLayer

# global variables used for the game 
var difficulty = "Easy"
var gamemode = "Classic"
var xSize = 9
var ySize = 9
var mineCount = 10
var tilesLeft = 0
var minesClicked = 0
var previousState = "none"
var gameState = "title"
var gameEndWhenMineHit = true
var hideGameTimer = false
var timedStartTime = 15
var timedTimeLossOnMineHit = -10
var timedMaxTimeAllowed = 25
@onready var mainGame = load("res://Scenes/SweeperGame.tscn")
@onready var titleScreen = load("res://Scenes/Title.tscn")

# signals used across the game and gamemodes
@warning_ignore("unused_signal")
signal chaserMoved
@warning_ignore("unused_signal")
signal clickEvent
@warning_ignore("unused_signal")
signal gameOver
@warning_ignore("unused_signal")
signal tileRevealed
signal gameStateChanged

# updates the internal game state
func updateState(newState):
	previousState = gameState
	gameState = newState
	emit_signal("gameStateChanged")

# toggles the pause menu on or off. Used to have it's own state but it created
# bugs if the state got outside the menu
func togglePause():
	if $pauseMenu.visible == false:
		$pauseMenu.show()
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		$pauseMenu.hide()

# handle opening the pause menu here
func _process(_delta):
	if Input.is_action_just_pressed("pause") and ((gameState != "title" and gameState != "transition" and gameState != "won" and gameState != "ended")  or $pauseMenu.visible == true):
		togglePause()

# on button pressed functions, most are self explanitory
func _on_unpause_pressed():
	togglePause()

func _on_reset_board_pressed():
	togglePause()
	transitionManager.transitionType = transitionManager.state.NONE
	transitionManager.load_scene(mainGame)

func _on_main_menu_pressed():
	togglePause()
	transitionManager.transitionType = transitionManager.state.FADE
	transitionManager.load_scene(titleScreen)
