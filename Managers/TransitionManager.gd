# This script is an autoload, that can be accessed from any other script!

extends CanvasLayer

@onready var transitionAnim = $transitionAnim
@onready var dissolveRect = $dissolveRect

# Scene Transition, can be changed from the inspector
enum state {FADE, NONE}
@export var transitionType : state

func _ready():
	dissolveRect.hide() # Hide the dissolve rect

# can call  by doing SceneTransition.load_scene(target_scene)
# will load the specified scene with the current transition
func load_scene(targetScene: PackedScene):
	gameManager.gameState = "transition"
	# stop current music before we transition
	audioManager.stopMusic()
	match transitionType:
		state.FADE:
			transition_animation("fade", targetScene)
		state.NONE:
			transition_animation("none", targetScene)

# This function handles the transition animation and plays
# the current one
func transition_animation(animName: String, scene: PackedScene):
	if animName == "none":
		get_tree().change_scene_to_packed(scene)
	else:
		transitionAnim.play(animName)
		dissolveRect.show()
		await transitionAnim.animation_finished
		get_tree().change_scene_to_packed(scene)
		transitionAnim.play_backwards(animName)
		await transitionAnim.animation_finished
		dissolveRect.hide()
