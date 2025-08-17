extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

func _ready():
	rect.color.a = 0.0  # start invisible
	# Make sure it's always on top
	layer = 100
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # <-- ignore mouse input


func fade_out(duration: float = 0.4) -> void:
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, duration)

func fade_in(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration)
