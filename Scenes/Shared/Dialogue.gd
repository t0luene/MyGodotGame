extends Control

signal dialogue_finished
signal choice_selected(action: String)

var lines: Array = []
var current_index: int = 0

# Safe lookups with get_node_or_null
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var portrait: TextureRect = get_node_or_null("Portrait")
@onready var text_label: Label = get_node_or_null("VBoxContainer/TextLabel")
@onready var next_button: Button = get_node_or_null("VBoxContainer/NextButton")
@onready var choices_container: VBoxContainer = get_node_or_null("ChoicesContainer")
@onready var choice1_button: Button = get_node_or_null("ChoicesContainer/Choice1Button")
@onready var choice2_button: Button = get_node_or_null("ChoicesContainer/Choice2Button")
@onready var line_sound_player: AudioStreamPlayer = $AcSpeach1


var choice1_action: String = ""
var choice2_action: String = ""

func _ready():
	visible = false

	if choice1_button and not choice1_button.is_connected("pressed", Callable(self, "_on_choice_1_button_pressed")):
		choice1_button.pressed.connect(_on_choice_1_button_pressed)
	if choice2_button and not choice2_button.is_connected("pressed", Callable(self, "_on_choice_2_button_pressed")):
		choice2_button.pressed.connect(_on_choice_2_button_pressed)
	if next_button and not next_button.is_connected("pressed", Callable(self, "_on_next_pressed")):
		next_button.pressed.connect(_on_next_pressed)


func start(dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_index = 0
	visible = true
	_show_line()


func _show_line() -> void:
	if current_index >= lines.size():
		_end_dialogue()
		return

	var line: Dictionary = lines[current_index]

	if line.get("type", "") == "choice":
		# Choice line
		if text_label: text_label.visible = false
		if name_label: name_label.visible = false
		if next_button: next_button.visible = false
		if choices_container: show_choices(line["options"])
	else:
		# Normal dialogue
		if text_label:
			text_label.visible = true
			text_label.text = line.get("text", "")
		if name_label:
			name_label.visible = true
			name_label.text = line.get("speaker", "")
		if next_button: next_button.visible = true
		if choices_container: choices_container.visible = false
		if portrait: portrait.texture = line.get("portrait", null)
		
		# Play dialogue sound
		if line_sound_player:
			line_sound_player.play()

func _on_next_pressed() -> void:
	current_index += 1
	_show_line()


func _end_dialogue() -> void:
	if text_label: text_label.text = ""
	if name_label: name_label.text = ""
	if portrait: portrait.texture = null
	visible = false
	emit_signal("dialogue_finished")


# --- Choices ---
func show_choices(options: Array) -> void:
	if not choices_container:
		return
	choices_container.visible = true
	if choice1_button:
		choice1_button.text = options[0]["text"]
	if choice2_button:
		choice2_button.text = options[1]["text"]
	choice1_action = options[0]["action"]
	choice2_action = options[1]["action"]


func _on_choice_1_button_pressed() -> void:
	_on_choice_pressed(choice1_action)


func _on_choice_2_button_pressed() -> void:
	_on_choice_pressed(choice2_action)


func _on_choice_pressed(action: String) -> void:
	if choices_container:
		choices_container.visible = false
	print("DEBUG: Choice pressed with action: ", action)
	emit_signal("choice_selected", action)

	current_index += 1
	_show_line()
