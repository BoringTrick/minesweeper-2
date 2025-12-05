extends Node2D

@onready var mainGame = load("res://scenes/sweeperGame.tscn")
@onready var playPanel = $titleUI/playPanel
@onready var mainMenuVbox = $titleUI/VBoxContainer
@onready var difficultyLabel = $titleUI/playPanel/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/difficultyDetails
@onready var easyButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/easySelect
@onready var mediumButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/mediumSelect
@onready var hardButton = $titleUI/playPanel/VBoxContainer/MarginContainer/HBoxContainer/hardSelect

func updateLabel():
	difficultyLabel.text = "Grid Size: " + str(gameManager.xSize) + "x" + str(gameManager.ySize) + "\nMine Amount: " + str(gameManager.mineCount)

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
	transitionManager.load_scene(mainGame)
