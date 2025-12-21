extends Node2D

@onready var playPanel = $titleUI/playPanel
@onready var mainMenuVbox = $titleUI/VBoxContainer
@onready var difficultyLabel = $titleUI/playPanel/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/difficultyDetails
@onready var easyButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/easySelect
@onready var mediumButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/mediumSelect
@onready var hardButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/hardSelect
@onready var gamemodeDetails = $titleUI/playPanel/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer2/gamemodeDetails
@onready var versionLabel = $titleUI/version
@onready var controlsPanel = $titleUI/controlsPanel

# secret extreme difficulty
var timesHardClicked = 0

# updates the labels for the menu when called
func updateLabel():
	# extreme difficulty: activate it if requirements met
	if timesHardClicked >= 5:
		hardButton.text = "Extreme"
		gameManager.difficulty = "Extreme"
		gameManager.xSize = 30
		gameManager.ySize = 30
		gameManager.mineCount = 225
		gameManager.timedStartTime = 10
		gameManager.timedMaxTimeAllowed = 20
		gameManager.timedTimeLossOnMineHit = -15
	else:
		hardButton.text = "Hard"
		gameManager.timedStartTime = 15
		gameManager.timedMaxTimeAllowed = 25
		gameManager.timedTimeLossOnMineHit = -10
	difficultyLabel.text = "Grid Size: " + str(gameManager.xSize) + "x" + str(gameManager.ySize) + "\nMine Amount: " + str(gameManager.mineCount)
	# extra details for the gamemodes
	match gameManager.gamemode:
		"Classic":
			gamemodeDetails.text = "Classic minesweeper\ngameplay! Flag tiles,\ncheck the numbers,\ndont click a mine!"
		"Timed":
			gamemodeDetails.text = "Minesweeper under a\ntime limit! Directly\nrevealed numbers give\ntime equal to their\nnumber, mines give\n" + str(gameManager.timedTimeLossOnMineHit) + "s. Don't let time run\nout!"
			difficultyLabel.text += "\nStart Time: " + str(gameManager.timedStartTime) + "s"
			difficultyLabel.text += "\nMax Time: " + str(gameManager.timedMaxTimeAllowed) + "s"
		"Enemies":
			gamemodeDetails.text = "Minesweeper with\nenemies! If one hits your\nmouse, the game ends.\nEach one has a unique\ngimmick, and harder\ndifficulties spawn harder\nenemies!"
			if gameManager.difficulty == "Easy":
				difficultyLabel.text += "\nTier 1 Enemies"
			elif gameManager.difficulty == "Medium":
				difficultyLabel.text += "\nTier 1 and 2\nEnemies"
			elif gameManager.difficulty == "Hard":
				difficultyLabel.text += "\nTier 1, 2, and 3\nEnemies"
			elif gameManager.difficulty == "Extreme":
				difficultyLabel.text += "\nAll Enemies present!"
		"Debug":
			gamemodeDetails.text = "test gamemode :)"

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
	timesHardClicked = 0
	updateLabel()

func _on_medium_select_pressed():
	gameManager.difficulty = "Medium"
	gameManager.xSize = 16
	gameManager.ySize = 16
	gameManager.mineCount = 40
	timesHardClicked = 0
	updateLabel()

func _on_hard_select_pressed():
	gameManager.difficulty = "Hard"
	gameManager.xSize = 30
	gameManager.ySize = 16
	gameManager.mineCount = 99
	# secret extreme difficulty accessible via clicking hard 5 times
	timesHardClicked += 1
	updateLabel()

func _on_start_game_pressed():
	transitionManager.load_scene(gameManager.mainGame)

func _on_gamemode_item_selected(index):
	match index:
		0:
			gameManager.gamemode = "Classic"
		1:
			gameManager.gamemode = "Timed"
		2:
			gameManager.gamemode = "Enemies"
		3:
			gameManager.gamemode = "Debug"
	updateLabel()

# open the controls menu
func _on_controls_pressed():
	mainMenuVbox.hide()
	controlsPanel.show()

func _on_exit_menu_controls_pressed():
	controlsPanel.hide()
	mainMenuVbox.show()

# quit game button
func _on_quit_pressed():
	get_tree().quit()

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
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	audioManager.queueMusic("title")
	audioManager.playMusic()
