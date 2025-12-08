extends Node2D

@onready var playPanel = $titleUI/playPanel
@onready var mainMenuVbox = $titleUI/VBoxContainer
@onready var difficultyLabel = $titleUI/playPanel/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/difficultyDetails
@onready var easyButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/easySelect
@onready var mediumButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/mediumSelect
@onready var hardButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/hardSelect
@onready var gamemodeDetails = $titleUI/playPanel/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer2/gamemodeDetails
@onready var versionLabel = $titleUI/version

# updates the grid size + mine count label when called
func updateLabel():
	difficultyLabel.text = "Grid Size: " + str(gameManager.xSize) + "x" + str(gameManager.ySize) + "\nMine Amount: " + str(gameManager.mineCount)
	# extra details if it's timed mode
	if gameManager.gamemode == "Timed":
		difficultyLabel.text += "\nTime Limit: %02d:%02d.%02d" % [floor(float(gameManager.mineCount * gameManager.timedMineStartSec) / 60), int(gameManager.mineCount * gameManager.timedMineStartSec) % 60, fmod(gameManager.mineCount * gameManager.timedMineStartSec, 1) * 100]

# when button pressed functions, most are self explanitory
func _on_open_play_menu_pressed():
	playPanel.show()
	mainMenuVbox.hide()

func _on_exit_menu_pressed():
	playPanel.hide()
	mainMenuVbox.show()

func _on_easy_select_pressed():
	gameManager.difficulty = "Easy"
	gameManager.xSize = 9
	gameManager.ySize = 9
	gameManager.mineCount = 10
	updateLabel()

func _on_medium_select_pressed():
	gameManager.difficulty = "Medium"
	gameManager.xSize = 16
	gameManager.ySize = 16
	gameManager.mineCount = 40
	updateLabel()

func _on_hard_select_pressed():
	gameManager.difficulty = "Hard"
	gameManager.xSize = 30
	gameManager.ySize = 16
	gameManager.mineCount = 99
	updateLabel()

func _on_start_game_pressed():
	transitionManager.load_scene(gameManager.mainGame)

func _on_gamemode_item_selected(index):
	match index:
		0:
			gameManager.gamemode = "Classic"
			gamemodeDetails.text = "Classic minesweeper\ngameplay! Flag tiles,\ncheck the numbers,\ndont click a mine!"
		1:
			gameManager.gamemode = "Timed"
			gamemodeDetails.text = "Normal minesweeper,\nbut under a time limit!\nCan you beat the board\nbefore the time is up?"
		2:
			gameManager.gamemode = "Enemies"
			gamemodeDetails.text = "The chasers are here"
	updateLabel()

# auto set the difficulty + gamemode on scene load to prevent glitches
func _ready():
	versionLabel.text = ProjectSettings.get_setting("application/config/version")
	gameManager.updateState("title")
	gameManager.difficulty = "Easy"
	gameManager.xSize = 9
	gameManager.ySize = 9
	gameManager.mineCount = 10
	gameManager.gamemode = "Classic"
	updateLabel()
