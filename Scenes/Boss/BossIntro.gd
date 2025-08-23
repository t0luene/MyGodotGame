extends Node2D

# --- Node references ---
@onready var trigger_area = $TriggerArea          # Quest1: walk to point
@onready var boss_npc = $BossNPC                  # Quest2: talk to boss
@onready var interact_button = $BossNPC/InteractButton
@onready var exit_to_hallway = $ExitToHallway     # Quest3 step1
@onready var spawn: Marker2D = $SpawnPoint

func _ready():
	# --- Connect signals ---
	trigger_area.body_entered.connect(_on_trigger_area_entered)
	boss_npc.body_entered.connect(_on_boss_area_entered)
	interact_button.pressed.connect(_on_boss_interact_pressed)
	exit_to_hallway.body_entered.connect(_on_exit_to_hallway_entered)

	interact_button.visible = false

	# --- Start first quest ---
	QuestManager.start_quest(0)

	# --- Add Player to this scene ---
	if Player:
		if Player.get_parent() != self:
			if Player.get_parent():
				Player.get_parent().remove_child(Player)
			add_child(Player)
		Player.global_position = spawn.global_position
		Player.visible = true
	else:
		push_error("⚠️ Player autoload not found — make sure Player.tscn is set in Autoload")

# --- Quest 1: walk to point ---
func _on_trigger_area_entered(body):
	if body == Player:
		QuestManager.complete_requirement(0, 0)
		trigger_area.queue_free()

# --- Quest 2: talk to boss ---
func _on_boss_area_entered(body):
	if body == Player:
		interact_button.visible = true

func _on_boss_interact_pressed():
	interact_button.visible = false
	var lines = [
		{"speaker": "Boss", "text": "Hello, player!"},
		{"speaker": "Player", "text": "Hello!"}
	]
	HUD.dialogue.start(lines)
	HUD.dialogue.dialogue_finished.connect(_on_boss_dialogue_finished)

func _on_boss_dialogue_finished():
	QuestManager.complete_requirement(1, 0)
	QuestManager.start_quest(1)

# --- Quest 3 Step 1: exit boss ---
func _on_exit_to_hallway_entered(body):
	if body == Player:
		QuestManager.player_exited_boss()
		if Engine.has_singleton("Game"):
			Engine.get_singleton("Game").load_floor("res://Scenes/Floors/Floor0.tscn")
		else:
			push_error("⚠️ Game singleton not found — cannot load Floor0")
