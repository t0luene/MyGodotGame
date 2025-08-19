extends Area2D

signal balance_started
signal balance_finished(success: bool)

# --- EXPORTS ---
@export var drift_speed: float = 10.0        # constant drift speed for scale
@export var fail_threshold: float = 50.0
@export var auto_move_speed: float = 150.0
@export var input_strength: float = 40.0     # how strong each button press is
@export var input_decay: float = 5.0
@export var fake_player_scene: PackedScene   # PlayerFake.tscn

# --- NODES ---
@onready var balance_button = $BalanceButton
@onready var path_follow = $PipePath/PipePathFollow
@onready var ui_bar = $"../UI_BalanceBar"

# --- STATE VARIABLES ---
var balancing: bool = false
var balance_value: float = 0.0
var input_velocity: float = 0.0
var player
var fake_player_instance: Node2D

# Drift direction: -1 = left, 1 = right
var drift_direction: int = 1

func _ready():
	balance_button.visible = false
	balance_button.pressed.connect(_on_balance_button_pressed)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	ui_bar.hide_bar()

func _on_body_entered(body):
	if body.name == "Player" and not balancing:
		player = body
		balance_button.visible = true
		balance_button.text = "Balance Across"

func _on_body_exited(body):
	if body.name == "Player":
		balance_button.visible = false

func _on_balance_button_pressed():
	if player:
		start_balance()

func _process(delta):
	if not balancing:
		return

	# --- HANDLE INPUT ---
	if Input.is_action_just_pressed("ui_left"):
		input_velocity -= input_strength
		drift_direction = -1
	elif Input.is_action_just_pressed("ui_right"):
		input_velocity += input_strength
		drift_direction = 1

	# Apply input force (decays over time)
	balance_value += input_velocity * delta
	input_velocity = lerp(input_velocity, 0.0, input_decay * delta)

	# --- CONSTANT DRIFT LIKE A SCALE ---
	balance_value += drift_speed * drift_direction * delta

	# --- AUTO-MOVE ALONG PIPE ---
	path_follow.progress += auto_move_speed * delta
	if fake_player_instance:
		fake_player_instance.global_position = path_follow.global_position

	# --- CLAMP BALANCE VALUE ---
	balance_value = clamp(balance_value, -fail_threshold, fail_threshold)

	# --- UPDATE UI BAR ---
	if ui_bar and ui_bar.bar:
		ui_bar.update_bar(balance_value, fail_threshold)

	# --- CHECK FAIL ---
	if abs(balance_value) >= fail_threshold:
		end_balance(false)

	# --- CHECK SUCCESS ---
	if path_follow.progress_ratio >= 1.0:
		end_balance(true)

func start_balance():
	balancing = true
	balance_value = 0.0
	drift_direction = 1  # always start drifting right
	ui_bar.show_bar()
	balance_button.visible = false
	emit_signal("balance_started")

	path_follow.progress = 0.0

	# --- Spawn fake player ---
	if fake_player_scene:
		fake_player_instance = fake_player_scene.instantiate()
		get_tree().current_scene.add_child(fake_player_instance)
		fake_player_instance.global_position = path_follow.global_position

		var anim_sprite = fake_player_instance.get_node("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("walk")
			anim_sprite.speed_scale = 0.5

	# Attach player
	if player:
		player.get_parent().remove_child(player)
		fake_player_instance.add_child(player)
		player.position = Vector2.ZERO
		var sprite = player.get_node("AnimatedSprite2D")
		if sprite:
			sprite.visible = false

func end_balance(success: bool):
	balancing = false
	ui_bar.hide_bar()
	emit_signal("balance_finished", success)

	# Remove fake player
	if fake_player_instance:
		if player and player.get_parent() == fake_player_instance:
			fake_player_instance.remove_child(player)
			get_tree().current_scene.add_child(player)
			player.global_position = fake_player_instance.global_position
		fake_player_instance.queue_free()
		fake_player_instance = null

	# Show real player again
	if player:
		var sprite = player.get_node("AnimatedSprite2D")
		if sprite:
			sprite.visible = true

	if not success:
		print("You fell!")  # replace with fail logic

func push_balance(direction: float):
	input_velocity += input_strength * direction
	drift_direction = sign(direction)
