extends Node2D

@onready var label: Label = $Label  # This gets the child Label node

func _ready():
	label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(self.queue_free)
