extends Control

@onready var dialogue_node: Control = get_tree().get_current_scene().get_node("HUD/CanvasLayer/Dialogue")
@onready var exit_to_hallway: Area2D = $ExitToHallway
@onready var checklist_ui: Control = get_tree().get_current_scene().get_node("HUD/CanvasLayer/CheckListUI")

var quest_completed := false

func _ready():
	exit_to_hallway.body_entered.connect(_on_exit_entered)
	Fade.fade_in(0.5)

	if not quest_completed:
		_start_conversation()

func _start_conversation():
	var lines = [
		{"text": "Welcome to the company!", "speaker": "Boss"},
		{"text": "Congrats on completing your first tasks.", "speaker": "Boss"}
	]
	dialogue_node.dialogue_finished.connect(_on_conversation_finished)
	dialogue_node.start(lines)

func _on_conversation_finished():
	QuestManager.complete_quest("hired")
	quest_completed = true

	if checklist_ui:
		checklist_ui.rebuild()

func _on_exit_entered(body):
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	get_parent().get_parent().load_room("Scenes/Rooms/Hallway0.tscn")
