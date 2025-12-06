extends CanvasLayer

# global variables used for the game 
var difficulty = "Easy"
var gamemode = "Classic"
var xSize = 9
var ySize = 9
var mineCount = 10
var previousState = "none"
var gameState = "title"
@onready var mainGame = load("res://Scenes/SweeperGame.tscn")
@onready var titleScreen = load("res://Scenes/Title.tscn")

func updateState(newState):
	previousState = gameState
	gameState = newState

# toggles the pause menu on or off. Used to have it's own state but it created
# bugs if the state got outside the menu
func togglePause():
	if $pauseMenu.visible == false:
		$pauseMenu.show()
		get_tree().paused = true
	else:
		get_tree().paused = false
		$pauseMenu.hide()

func _on_unpause_pressed():
	togglePause()

func _process(_delta):
	if Input.is_action_just_pressed("pause") and ((gameState != "title" and gameState != "transition")  or $pauseMenu.visible == true):
		togglePause()

func _on_reset_board_pressed():
	togglePause()
	transitionManager.transitionType = transitionManager.state.NONE
	transitionManager.load_scene(mainGame)

func _on_main_menu_pressed():
	togglePause()
	transitionManager.transitionType = transitionManager.state.FADE
	transitionManager.load_scene(titleScreen)
