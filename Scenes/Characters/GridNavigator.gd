extends CharacterBody2D

@export var npc_name: String = "Grid Navigator"
@export var npc_portrait: Texture2D
@export var quest_floor: String = "floor-2"
@export var quest_id: String = "talk_grid_navigator"
@export var interaction_range: float = 150

# References to autoloaded HUD and Player
@onready var dialogue_node: Control = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
@onready var interact_button: Button = get_node_or_null("/root/HUD/CanvasLayer/InteractButton")
@onready var player_node: CharacterBody2D = get_node_or_null("/root/Game/Player")

var current_line_index: int = 0
var finished: bool = false

var dialogue_sequence: Array = [
	{"speaker": "Maint Lead", "text": "Hello, welcome to Maintenance. Can you help me with the floor?"},
	{"speaker": "Player", "text": "Of course! What do you need?"},
	{"speaker": "Maint Lead", "text": "Please inspect the rooms carefully. Thanks!"}
]

func _ready():
	# Hide interact button and connect
	if interact_button:
		interact_button.visible = false
		if not interact_button.is_connected("pressed", Callable(self, "_on_interact_pressed")):
			interact_button.pressed.connect(_on_interact_pressed)
	else:
		push_warning("InteractButton not found in HUD!")

func _process(_delta):
	if not player_node or not interact_button or not dialogue_node:
		return

	# Show button only if player is close and dialogue not started
	var distance = global_position.distance_to(player_node.global_position)
	interact_button.visible = distance <= interaction_range and not finished and not dialogue_node.visible

	# Position button above NPC
	if interact_button.visible:
		var screen_pos = get_viewport().get_camera_2d().unproject_position(global_position)
		interact_button.position = screen_pos + Vector2(-interact_button.size.x / 2, -50)

func _on_interact_pressed():
	if finished or dialogue_node.visible:
		return
	current_line_index = 0
	_show_next_line()

func _show_next_line():
	if current_line_index >= dialogue_sequence.size():
		# Dialogue finished
		finished = true
		if QuestManager.current_quest_id == 4:
			QuestManager.complete_requirement(4, 5)  # Quest4, requirement index for "talk_maint_lead"
		
		# Rebuild checklist
		if HUD.has_node("CanvasLayer/CheckListUI"):
			HUD.get_node("CanvasLayer/CheckListUI").rebuild()
		return

	# Get current line and add portrait if missing
	var line = dialogue_sequence[current_line_index]
	if not line.has("portrait"):
		line["portrait"] = npc_portrait

	# Start dialogue
	dialogue_node.start([line])

	# Reconnect signal safely
	if dialogue_node.is_connected("dialogue_finished", Callable(self, "_on_line_finished")):
		dialogue_node.disconnect("dialogue_finished", Callable(self, "_on_line_finished"))
	dialogue_node.connect("dialogue_finished", Callable(self, "_on_line_finished"))

func _on_line_finished():
	current_line_index += 1
	_show_next_line()
