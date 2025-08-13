extends CharacterBody2D

@export var ghost_name: String = "Challenger Ghost"
@export var dialogue: String = "You shall not pass... unless you beat me in Rock Paper Scissors!"
@export var use_rps_challenge := true

@export var fade_start_distance := 250.0  # Fully invisible beyond this distance
@export var fade_end_distance := 50.0    # Fully visible at or below this distance
@export var spook_distance := 100.0

@onready var player = get_tree().get_current_scene().get_node("Player")
@onready var black_fade = get_tree().get_current_scene().get_node("Camera2D/UI/BlackFade") # Adjust to your scene path
@onready var spooked_text = get_tree().get_current_scene().get_node("Camera2D/UI/SpookedText") # Adjust to your scene path

var is_spooked := false
var time_accum = 0.0

signal talked_to(ghost_name: String, dialogue: String)
signal rps_result(success: bool, ghost_node: Node)
signal player_spooked()

func _ready():
	$DialogueLabel.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	$AnimatedSprite2D.play("idle")

	# Hide fade and text at start
	black_fade.visible = false
	spooked_text.visible = false

func _process(delta):
	_update_opacity()

	if is_spooked:
		return

	time_accum += delta
	if time_accum >= 1.0:
		time_accum = 0.0
		var dist = global_position.distance_to(player.global_position)
		if dist <= spook_distance:
			_trigger_spook()

func _trigger_spook():
	is_spooked = true
	print("👻 Ghost spooked the player!")

	# Ghost plays scared animation
	$AnimatedSprite2D.play("scared")

	# Stop player completely
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	# Play initial hop animation on player's AnimatedSprite2D
	var p_sprite = player.get_node("AnimatedSprite2D")
	p_sprite.play("hop")

	# Wait for hop animation to finish
	var hop_time = p_sprite.sprite_frames.get_frame_count("hop") / p_sprite.sprite_frames.get_animation_speed("hop")
	await get_tree().create_timer(hop_time).timeout

	# --- Turn player around to face away from ghost ---
	var dir = player.global_position.x - global_position.x
	var direction = Vector2(sign(dir), 0) # only horizontal movement

	if direction.x > 0:
		# Ghost is to the left → player runs right
		p_sprite.flip_h = false
	else:
		# Ghost is to the right → player runs left
		p_sprite.flip_h = true

	# Play scared run animation
	p_sprite.play("run")

	# Push player faster and farther
	var push_distance = 400.0  # was 200, doubled for longer run
	var run_time = 0.6         # was 1.0, shorter = faster
	var target_pos = player.global_position + direction * push_distance

	# Tween the player to pushed position quickly
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, run_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# After run ends, go straight to building scene instead of hopping again

	# Start fade & text while push happens
	_show_spook_message()

	emit_signal("player_spooked")

func _show_spook_message():
	black_fade.visible = true
	black_fade.modulate.a = 0.0
	spooked_text.text = "!!You are spooked!!\nYou cannot inspect floors on this day anymore"
	spooked_text.visible = true
	spooked_text.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(black_fade, "modulate:a", 1.0, 0.5)  # Fade black in 0.5s
	tween.tween_interval(2.0)                               # Hold black + text 2 seconds
	tween.tween_callback(Callable(self, "_return_to_building"))  # Then change scene


func _return_to_building():
	print("🔄 _return_to_building() called")
	get_tree().change_scene_to_file("res://Building.tscn")



func _on_player_push_complete():
	player.set_physics_process(true)

# --- opacity and dialogue methods below (unchanged) ---

func _update_opacity():
	var dist = global_position.distance_to(player.global_position)
	if dist > fade_start_distance:
		modulate.a = 0.0
	elif dist < fade_end_distance:
		modulate.a = 1.0
	else:
		var t = (fade_start_distance - dist) / (fade_start_distance - fade_end_distance)
		modulate.a = clamp(t, 0.0, 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🗣️ Talking to", ghost_name)
		$DialogueLabel.text = "%s:\n%s" % [ghost_name, dialogue]
		$DialogueLabel.visible = true
		emit_signal("talked_to", ghost_name, dialogue)

func _on_body_exited(body):
	if body.is_in_group("player"):
		$DialogueLabel.visible = false

func play_rps_with_choice(player_choice: String):
	var options = ["rock", "paper", "scissors"]
	var ghost_choice = options[randi() % 3]
	print("👤 Player chose: ", player_choice)
	print("👻 Ghost chose: ", ghost_choice)

	if player_choice == ghost_choice:
		return "tie"

	if (player_choice == "rock" and ghost_choice == "scissors") or \
	   (player_choice == "scissors" and ghost_choice == "paper") or \
	   (player_choice == "paper" and ghost_choice == "rock"):
		return "win"

	return "lose"

func _play_rps() -> bool:
	var options = ["rock", "paper", "scissors"]
	var player_choice = options[randi() % 3]
	var ghost_choice = options[randi() % 3]
	print("👤 Player chose: ", player_choice)
	print("👻 Ghost chose: ", ghost_choice)

	if player_choice == ghost_choice:
		return _play_rps() # retry on tie

	if (player_choice == "rock" and ghost_choice == "scissors") or \
	   (player_choice == "scissors" and ghost_choice == "paper") or \
	   (player_choice == "paper" and ghost_choice == "rock"):
		return true
	return false

func show_dialogue():
	print(dialogue)
