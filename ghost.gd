extends Area2D

@export var ghost_name: String = "Challenger Ghost"
@export var dialogue: String = "You shall not pass... unless you beat me in Rock Paper Scissors!"
@export var use_rps_challenge := true


signal talked_to(ghost_name: String, dialogue: String)
signal rps_result(success: bool, ghost_node: Node)

func _ready():
	$DialogueLabel.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🗣️ Talking to", ghost_name)
		$DialogueLabel.text = "%s:\n%s" % [ghost_name, dialogue]
		$DialogueLabel.visible = true
		emit_signal("talked_to", ghost_name, dialogue)
		# Do NOT emit rps_result here — wait for player input via RPSPopup

func play_rps_with_choice(player_choice: String):
	var options = ["rock", "paper", "scissors"]
	var ghost_choice = options[randi() % 3]
	print("👤 Player chose: ", player_choice)
	print("👻 Ghost chose: ", ghost_choice)

	if player_choice == ghost_choice:
		# Tie - You can handle ties outside or here
		return "tie"

	# Player win conditions
	if (player_choice == "rock" and ghost_choice == "scissors") or \
	   (player_choice == "scissors" and ghost_choice == "paper") or \
	   (player_choice == "paper" and ghost_choice == "rock"):
		return "win"

	return "lose"




func _on_body_exited(body):
	if body.is_in_group("player"):
		$DialogueLabel.visible = false

# Random RPS result: true if player wins, false if loses
func _play_rps() -> bool:
	var options = ["rock", "paper", "scissors"]
	var player = options[randi() % 3]
	var ghost = options[randi() % 3]
	print("👤 Player chose: ", player)
	print("👻 Ghost chose: ", ghost)

	if player == ghost:
		return _play_rps() # redo on tie

	# Player win conditions
	if (player == "rock" and ghost == "scissors") or \
	   (player == "scissors" and ghost == "paper") or \
	   (player == "paper" and ghost == "rock"):
		return true
	return false

func show_dialogue():
	# Implement UI popup here, or send signal to UI manager
	print(dialogue)
