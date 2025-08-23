extends CharacterBody2D

@export var npc_name: String = "NPC Name"
@export var npc_portrait: Texture2D
@export var quest_floor: String = ""
@export var quest_id: String = ""
@onready var interact_button: Button = $InteractButton
@onready var dialogue_node: Control = $"../CanvasLayer/Dialogue"

var current_line_index: int = 0
var finished: bool = false
var dialogue_sequence: Array = [
	{"text": "Hello!", "speaker": "NPC Name"},
	{"text": "Hi there!", "speaker": "Player"}
]

func _ready():
	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_pressed)

func _process(_delta):
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player_node = player_nodes[0]
		if global_position.distance_to(player_node.global_position) < 50 and not finished:
			interact_button.visible = true
		else:
			interact_button.visible = false
	else:
		interact_button.visible = false

func _on_interact_pressed():
	if not dialogue_node.visible and not finished:
		current_line_index = 0
		_show_next_line()

func _show_next_line():
	if current_line_index >= dialogue_sequence.size():
		if quest_floor != "" and quest_id != "":
			Global.mark_completed(quest_floor, quest_id)
		finished = true
		return

	var line = dialogue_sequence[current_line_index]

	# Assign portrait at runtime
	if not line.has("portrait"):
		if line.get("speaker") == "Player":
			var player_nodes = get_tree().get_nodes_in_group("player")
			if player_nodes.size() > 0:
				line["portrait"] = player_nodes[0].player_portrait
			else:
				line["portrait"] = null
		else:
			line["portrait"] = npc_portrait
	dialogue_node.start([line])

	if dialogue_node.is_connected("dialogue_finished", Callable(self, "_on_line_finished")):
		dialogue_node.disconnect("dialogue_finished", Callable(self, "_on_line_finished"))
	dialogue_node.connect("dialogue_finished", Callable(self, "_on_line_finished"))

func _on_line_finished():
	current_line_index += 1
	_show_next_line()
