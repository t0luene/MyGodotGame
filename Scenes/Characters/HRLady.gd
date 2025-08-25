extends CharacterBody2D

@export var npc_name: String = "HR Lady"
@export var npc_portrait: Texture2D

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if not animated_sprite:
		push_error("AnimatedSprite2D not found!")
	else:
		animated_sprite.play("idle")  # default idle animation

# Optional: play an animation on some event
func play_animation(anim_name: String):
	if animated_sprite:
		animated_sprite.play(anim_name)
