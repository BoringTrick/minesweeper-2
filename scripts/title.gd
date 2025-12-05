extends Node2D

@onready var mainGame = load("res://scenes/sweeperGame.tscn")

func _on_open_play_menu_pressed():
	transitionManager.load_scene(mainGame)
