extends Area2D

@export var item_name: String = "Mysterious Key"
@export var floating_text_scene: PackedScene

signal picked_up(item_name)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Picked up", item_name)
		emit_signal("picked_up", item_name)

		if floating_text_scene:
			var popup = floating_text_scene.instantiate()
			popup.position = global_position
			var label_node = popup.get_node("Label")
			label_node.text = "🔹 Picked up: " + item_name
			get_tree().current_scene.add_child(popup)

		queue_free()
