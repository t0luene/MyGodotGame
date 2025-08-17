extends Area2D

@export var target_scene: String  # the path to the scene, e.g. "res://Floor3.tscn"
var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.name != "Player":
		return

	triggered = true
	# Call your GameRoot to switch scenes
	get_tree().root.get_node("GameRoot").switch_scene(target_scene)
