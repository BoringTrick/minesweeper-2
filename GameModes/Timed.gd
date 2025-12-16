extends CanvasLayer

@onready var timerLabel = $timerLabel
@onready var timer = $timer

var timerQueue = 0
var timeLeft = gameManager.timedStartTime

func _ready():
	if !gameManager.is_connected("gameStateChanged", onGameStateChange):
		gameManager.gameStateChanged.connect(onGameStateChange)
	if !gameManager.is_connected("tileRevealed", tileRevealed):
		gameManager.tileRevealed.connect(tileRevealed)
	gameManager.gameEndWhenMineHit = false
	gameManager.hideGameTimer = true
	timer.wait_time = gameManager.timedStartTime
	timerLabel.text = "%02d.%02d" % [int($timer.wait_time) % 60, fmod($timer.wait_time, 1) * 100]

func _process(_delta):
	# timer queue: if multiple timer events happen at
	# the same time they all get processed at once
	# this code also handles the text that appears under the timer
	if timerQueue != 0 and gameManager.gameState == "playing":
		var timeLossGameEnd = false
		# cap the time if it's over the max time allowed, end game if timer goes below 0
		if (timer.time_left + timerQueue) <= 0:
			timeLossGameEnd = true
		elif (timer.time_left + timerQueue) > gameManager.timedMaxTimeAllowed:
			var amountToCapWith = (timer.time_left + timerQueue) - gameManager.timedMaxTimeAllowed
			timerQueue = int(floor(timerQueue - amountToCapWith))
		var bonusText = $bonusText.duplicate()
		$".".add_child(bonusText)
		if timerQueue > 0:
			bonusText.text = "+" + str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.GREEN)
		elif timerQueue == 0:
			bonusText.text = "+" + str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.WHITE)
		else:
			bonusText.text = str(timerQueue)
			bonusText.add_theme_color_override("font_color", Color.RED)
		bonusText.show()
		# use tweens to animate the text appearing under the timer
		var tween = get_tree().create_tween()
		tween.tween_property(bonusText, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1.5)
		tween.parallel().tween_property(bonusText, "position", Vector2(bonusText.position.x, (bonusText.position.y + 35)), 1.5)
		tween.tween_callback(bonusText.queue_free)
		if timeLossGameEnd == false:
			timer.start(timer.time_left + timerQueue)
		else:
			timer.stop()
			# doing this because the signal runs before the countdown code lol
			timeLeft = timer.time_left
			timerLabel.text = "%02d.%02d" % [int(timeLeft) % 60, fmod(timeLeft, 1) * 100]
			timer.emit_signal("timeout")
		timerQueue = 0
	
	# countdown timer
	if gameManager.gameState == "playing":
		timeLeft = timer.time_left
		timerLabel.text = "%02d.%02d" % [int(timeLeft) % 60, fmod(timeLeft, 1) * 100]

func endScreenText(context):
	var endText = ""
	match context:
		"won":
			endText += "\nTime Remaining: %02d.%02d" % [int(timeLeft) % 60, fmod(timeLeft, 1) * 100]
		"common":
			endText += "\nMines Hit: " + str(gameManager.minesClicked)
	return endText

# --SIGNALS_--
func _on_timer_timeout():
	# i dont know if a bug where having 0.01 on timer when timer ends exists,
	# but i want to be proactive with this
	timeLeft = timer.time_left
	timerLabel.text = "%02d.%02d" % [int(timeLeft) % 60, fmod(timeLeft, 1) * 100]
	gameManager.emit_signal("gameOver", Vector2i(-1, -1))

func onGameStateChange():
	if gameManager.gameState == "ended" or gameManager.gameState == "won":
		timer.stop()
	elif gameManager.gameState == "playing":
		timer.start(timeLeft)

func tileRevealed(number, context):
	if number == -1:
		timerQueue += gameManager.timedTimeLossOnMineHit
	else:
		if context == "normalReveal":
			timerQueue += number
