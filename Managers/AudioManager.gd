extends Node

@onready var sfxPlayer = $sfxStreamPlayer
@onready var musicPlayer = $musicStreamPlayer
@onready var uiPlayer = $uiStreamPlayer

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
