extends Node

@onready var sfxPlayer = $sfxStreamPlayer
@onready var musicPlayer = $musicStreamPlayer
@onready var uiPlayer = $uiStreamPlayer

# queue to hold the next track that should play
var musicQueue = [AudioStreamOggVorbis.load_from_file("res://Assets/Music/preBoardTEMP.ogg"), 0, 1.0]

# play an audiostreamwav that gets passed in with the specified parameters
func playSFX(audio, volume = 0.0, pitch = 1.0):
	if audio.is_class("AudioStreamWAV"):
		var sfxClone = sfxPlayer.duplicate()
		sfxClone.stream = audio
		sfxClone.volume_db = volume
		sfxClone.pitch_scale = pitch
		self.add_child(sfxClone)
		sfxClone.play()
		await sfxClone.finished
		sfxClone.queue_free()

# load music into the music queue to be played next
func queueMusic(audio, volume = 0.0, pitch = 1.0):
	audio = resolveMusicObject(audio)
	musicQueue[0] = audio
	musicQueue[1] = volume
	musicQueue[2] = pitch

# play whatever's in the music queue with its parameters
# also stops current music first
func playMusic():
	musicPlayer.stop()
	musicPlayer.stream = musicQueue[0]
	musicPlayer.volume_db = musicQueue[1]
	musicPlayer.pitch_scale = musicQueue[2]
	musicPlayer.play()

# stops the current music
func stopMusic():
	musicPlayer.stop()

# resolves music names to audio stream objects, will allow
# for artist and track names in the future too
func resolveMusicObject(musicName):
	# fallback music
	var musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/preBoardTEMP.ogg")
	match musicName:
		"preBoard":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/preBoardTEMP.ogg")
		"title":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/titleTEMP.ogg")
		"win":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/winTEMP.ogg")
		"loss":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/lossTEMP.ogg")
		"board":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/boardTEMP.ogg")
		"timed":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/timedTEMP.ogg")
		"enemies":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/enemiesTEMP.ogg")
		"enemiesExtreme":
			musicObject = AudioStreamOggVorbis.load_from_file("res://Assets/Music/enemiesExtremeTEMP.ogg")
	return musicObject

# fix the magic godot bug where DESPITE MY OGG FILE BEING SET
# TO LOOP IT WONT LOOP???? HELLO???????
func _on_music_stream_player_finished():
	musicPlayer.play()
