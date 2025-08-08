extends Control  # or Node2D, depending on your scene

@onready var static_employee = $StaticEmployee
@onready var convo_ui = $EmployeeConversation
@onready var player = $Player
@onready var pause_timer = $PauseTimer

# Dialogue tree data structure
var dialogue_tree = {
	"Q1": {
		"question": "Hey boss, Can I get a Promotion?",
		"animation": "idle",  # instead of "idle_ground"
		"answers": [
			{"text": "No lol, Get back to work", "next": "Q2a", "anim": "idle_ground"},
			{"text": "Ill think about it.", "next": "Q2b", "anim": "idle_lookatcamera"}
		]
	},
	"Q2a": {
		"question": "Oh..... :(",
		"animation": "idle_ground",
		"answers": [
			{"text": "You are not that far. Keep working hard!", "next": null, "anim": "idle_lookatcamera"},
			{"text": "Stop wasting my time.", "next": null, "anim": "idle_ground"}
		]
	},
	"Q2b": {
		"question": "Well.. Could I take a small vacation next week then?",
		"animation": "idle",
		"answers": [
			{"text": "We are all working *very* hard here.", "next": null, "anim": "idle_ground"},
			{"text": "After we release this game.. maybe.", "next": null, "anim": "idle_lookatcamera"}
		]
	}
}

var current_node_key = "Q1"

func _ready():
	static_employee.conversation_started.connect(_on_conversation_started)
	convo_ui.visible = false

func _on_conversation_started(data: Dictionary) -> void:
	player.can_move = false
	current_node_key = "Q1"
	load_current_node()

	if not convo_ui.is_connected("choice_made", Callable(self, "_on_conversation_result")):
		convo_ui.choice_made.connect(Callable(self, "_on_conversation_result"))

func load_current_node():
	var node = dialogue_tree[current_node_key]
	static_employee.anim.play(node["animation"])  # play question animation
	var answers = node["answers"]
	convo_ui.show_conversation(node["question"], answers[0]["text"], answers[1]["text"])



func _on_conversation_result(result: String) -> void:
	print("Player chose: ", result)

	var node = dialogue_tree[current_node_key]
	for answer in node["answers"]:
		if answer["text"] == result:
			static_employee.anim.play(answer["anim"])  # play animation reaction

			if answer["next"] != null:
				current_node_key = answer["next"]
				convo_ui.show_waiting()  # Hide buttons and show "..."
				pause_timer.start()
				pause_timer.timeout.connect(_on_pause_timer_timeout)
			else:
				convo_ui.hide_conversation()
				player.can_move = true
			break

func _on_pause_timer_timeout() -> void:
	load_current_node()
	# Disconnect the signal so it doesn't fire multiple times
	pause_timer.timeout.disconnect(_on_pause_timer_timeout)
