extends Control

@onready var base = $Base
@onready var stick = $Stick

@export var radius: float = 100.0
var drag_pos: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var base_center: Vector2 = Vector2.ZERO

func _ready():
	# Calculate center of the base TextureRect in local coords
	base_center = base.position  # since you've manually centered the base
	stick.position = base_center

func _gui_input(event: InputEvent) -> void:
	# Touch or Mouse
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var local_pos = get_local_mouse_position()
			drag_pos = (local_pos - base_center).limit_length(radius)
			stick.position = base_center + drag_pos
			direction = drag_pos / radius
		else:
			_reset_stick()

	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0):
		var local_pos = get_local_mouse_position()
		drag_pos = (local_pos - base_center).limit_length(radius)
		stick.position = base_center + drag_pos
		direction = drag_pos / radius



func _reset_stick():
	stick.position = base_center
	drag_pos = Vector2.ZERO
	direction = Vector2.ZERO
