extends Control

signal dialogue_finished

var lines: Array = []
var current_index: int = 0

@onready var label: Label = $Label
@onready var next_button: Button = $NextButton

func start(dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_index = 0
	visible = true

	var callable_pressed := Callable(self, "_on_next_pressed")
	if not next_button.is_connected("pressed", callable_pressed):
		next_button.pressed.connect(callable_pressed)

	_show_line()

func _show_line() -> void:
	if current_index < lines.size():
		label.text = lines[current_index]
	else:
		_end_dialogue()

func _on_next_pressed() -> void:
	current_index += 1
	_show_line()

func _end_dialogue() -> void:
	label.text = ""
	visible = false

	var callable_pressed := Callable(self, "_on_next_pressed")
	if next_button.is_connected("pressed", callable_pressed):
		next_button.pressed.disconnect(callable_pressed)

	emit_signal("dialogue_finished")
