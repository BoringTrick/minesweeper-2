# This script is an autoload, that can be accessed from any other script!

extends CanvasLayer

@onready var transitionAnim = $transitionAnim
@onready var dissolveRect = $dissolveRect

# Scene Transition can be changed from the inspector
enum state {FADE, NONE}
@export var transitionType : state

func _ready():
	dissolveRect.hide() # Hide the dissolve rect

# You can call this function from any script by doing SceneTransition.load_scene(target_scene)
func load_scene(targetScene: PackedScene):
	match transitionType:
		state.FADE:
			transition_animation("fade", targetScene)
		state.NONE:
			transition_animation("none", targetScene)

# This function handles the transition animation
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
