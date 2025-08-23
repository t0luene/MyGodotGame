extends CharacterBody2D

@export var npc_name: String = "HR Lady"
@export var npc_portrait: Texture2D
@export var quest_floor: String = "floor0"
@export var quest_id: String = "talk_to_hr"
@export var interaction_range: float = 150

@onready var dialogue_node: Control = $"../CanvasLayer/Dialogue"
@onready var interact_button: Button = $"../CanvasLayer/InteractButton"
@onready var player_node: CharacterBody2D = get_node("/root/Game/Player") # adjust path if Player is global/autoload

var finished: bool = false
var current_line_index: int = 0

var dialogue_sequence: Array = [
	{"text": "Hello. I am the HR lady, please sign the documents.", "speaker": "HR Lady"},
	{"text": "Oh ok.", "speaker": "Player"},
	{"text": "I'll be seeing you.", "speaker": "HR Lady"}
]

func _ready():
	if interact_button:
		interact_button.visible = false
		interact_button.pressed.connect(_on_interact_pressed)
	else:
		push_warning("InteractButton not found in this room!")

func _process(_delta):
	if not player_node:
		return

	var distance = global_position.distance_to(player_node.global_position)
	interact_button.visible = distance <= interaction_range and not finished and not dialogue_node.visible

	var viewport = get_viewport()
	var screen_pos = viewport.get_camera_2d().unproject_position(global_position)
	interact_button.rect_position = screen_pos + Vector2(-interact_button.rect_size.x/2, -50)

func _on_interact_pressed():
	if finished or dialogue_node.visible:
		return
	current_line_index = 0
	_show_next_line()

func _show_next_line():
	if current_line_index >= dialogue_sequence.size():
		finished = true
		QuestManager.complete_quest(quest_id)
		var checklist_ui = get_tree().get_current_scene().get_node("HUD/CanvasLayer/CheckListUI")
		if checklist_ui:
			checklist_ui.rebuild()
		return

	var line = dialogue_sequence[current_line_index]
	if not line.has("portrait"):
		line["portrait"] = npc_portrait

	dialogue_node.start([line])

	# Connect dialogue finished signal
	if dialogue_node.is_connected("dialogue_finished", Callable(self, "_on_line_finished")):
		dialogue_node.disconnect("dialogue_finished", Callable(self, "_on_line_finished"))
	dialogue_node.connect("dialogue_finished", Callable(self, "_on_line_finished"))

func _on_line_finished():
	current_line_index += 1
	_show_next_line()
