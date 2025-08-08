extends Control

signal choice_made(result: String)

@onready var dialogue_label = $Panel/VBoxContainer/DialogueLabel
@onready var choice_a_button = $Panel/VBoxContainer/ChoiceAButton
@onready var choice_b_button = $Panel/VBoxContainer/ChoiceBButton

func _ready():
	choice_a_button.pressed.connect(_on_choice_a_pressed)
	choice_b_button.pressed.connect(_on_choice_b_pressed)
	visible = false  # Start hidden

func set_dialog(text: String) -> void:
	dialogue_label.text = text

func set_choices(option_a: String, option_b: String) -> void:
	choice_a_button.text = option_a
	choice_b_button.text = option_b

func show_conversation(text: String, option_a: String, option_b: String) -> void:
	set_dialog(text)
	set_choices(option_a, option_b)
	choice_a_button.visible = true   # Make sure buttons are visible again
	choice_b_button.visible = true
	visible = true

func hide_conversation() -> void:
	visible = false

func _on_choice_a_pressed():
	choice_made.emit(choice_a_button.text)  # emit actual button text

func _on_choice_b_pressed():
	choice_made.emit(choice_b_button.text)  # emit actual button text
	
func show_waiting() -> void:
	dialogue_label.text = "..."
	choice_a_button.visible = false
	choice_b_button.visible = false
	visible = true
