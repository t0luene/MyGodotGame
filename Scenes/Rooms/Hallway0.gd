extends Node2D

@onready var entrance1: Area2D = $Entrance1
@onready var entrance2: Area2D = $Entrance2
@onready var checklist_trigger: Area2D = $ChecklistTrigger
@onready var elevator_trigger: Area2D = $ElevatorTrigger
@onready var player_spawn: Marker2D = $PlayerSpawn

var floor_node: Node = null

func _ready():
	# Move Player into this scene
	if Player.get_parent() != self:
		if Player.get_parent():
			Player.get_parent().remove_child(Player)
		add_child(Player)
	Player.global_position = player_spawn.global_position
	Player.visible = true

	# Reference Floor0 for load_room
	floor_node = get_parent()

	# Connect triggers
	entrance1.body_entered.connect(_on_entrance1_entered)
	entrance2.body_entered.connect(_on_entrance2_entered)
	checklist_trigger.body_entered.connect(_on_checklist_trigger)
	elevator_trigger.body_entered.connect(_on_elevator_triggered)

# Checklist trigger
func _on_checklist_trigger(body):
	if body != Player:
		return
	QuestManager.complete_quest("hallway0")

# Room entrances
func _on_entrance1_entered(body):
	if body != Player:
		return
	if floor_node and floor_node.has_method("load_room"):
		floor_node.load_room("res://Scenes/HR/HR.tscn")

func _on_entrance2_entered(body):
	if body != Player:
		return
	if floor_node and floor_node.has_method("load_room"):
		floor_node.load_room("res://Scenes/Boss/Boss.tscn")

# Elevator
func _on_elevator_triggered(body):
	if body != Player:
		return
	if has_node("/root/Fade"):
		Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")
