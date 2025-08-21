extends CharacterBody2D

@export var crew_name: String = "Worker"

# Dialogue sequence: back-and-forth conversation
var dialogue_sequence: Array = [
	{"text": "Hello. I am crew member, are you new around here?", "speaker": "crew"},
	{"text": "Yes", "speaker": "player"},
	{"text": "Well, nice to meet you... I guess", "speaker": "crew"}
]

@onready var interact_button: Button = $InteractButton
@onready var dialogue_node: Control = $"../CanvasLayer/Dialogue"

var current_line_index: int = 0

func _ready():
	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_pressed)

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 50:
		interact_button.visible = true
	else:
		interact_button.visible = false

func _on_interact_pressed():
	if dialogue_node and not dialogue_node.visible:
		current_line_index = 0
		_show_next_line()

func _show_next_line():
	if current_line_index >= dialogue_sequence.size():
		# Dialogue finished
		Global.mark_completed("floor-1", "talk_to_crew")
		return

	var line = dialogue_sequence[current_line_index]
	dialogue_node.start([line["text"]])

	# Disconnect old connection if it exists
	if dialogue_node.is_connected("dialogue_finished", Callable(self, "_on_line_finished")):
		dialogue_node.disconnect("dialogue_finished", Callable(self, "_on_line_finished"))

	# Connect for next line
	dialogue_node.connect("dialogue_finished", Callable(self, "_on_line_finished"))

func _on_line_finished():
	current_line_index += 1
	_show_next_line()
