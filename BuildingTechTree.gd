extends Control

var btp := 3  # Building Tech Points

var nodes = {
	"node1": false,
	"node2": false,
	"node3": false,
}
var node_descriptions = {
	"node1": "Increases building capacity.",
	"node2": "Unlocks advanced training rooms.",
	"node3": "Boosts employee efficiency.",
}

var prerequisites = {
	"node1": [],
	"node2": ["node1"],
	"node3": ["node2"],
}

func _ready():
	update_btp_label()
	update_nodes_ui()

	$Node1Button.pressed.connect(Callable(self, "_on_Node1Button_pressed"))
	$Node2Button.pressed.connect(Callable(self, "_on_Node2Button_pressed"))
	$Node3Button.pressed.connect(Callable(self, "_on_Node3Button_pressed"))

	# Hover signals
	$Node1Button.mouse_entered.connect(Callable(self, "_on_node_button_hovered").bind("node1"))
	$Node2Button.mouse_entered.connect(Callable(self, "_on_node_button_hovered").bind("node2"))
	$Node3Button.mouse_entered.connect(Callable(self, "_on_node_button_hovered").bind("node3"))

	$Node1Button.mouse_exited.connect(Callable(self, "_on_node_button_unhovered"))
	$Node2Button.mouse_exited.connect(Callable(self, "_on_node_button_unhovered"))
	$Node3Button.mouse_exited.connect(Callable(self, "_on_node_button_unhovered"))


func _on_node_button_hovered(node_name: String):
	var desc = node_descriptions.get(node_name, "No description available.")
	$HoverInfoLabel.text = desc
	$HoverInfoLabel.visible = true

func _on_node_button_unhovered():
	$HoverInfoLabel.visible = false



func _on_Node1Button_pressed():
	buy_node("node1")

func _on_Node2Button_pressed():
	buy_node("node2")

func _on_Node3Button_pressed():
	buy_node("node3")

func can_buy_node(node_name: String) -> bool:
	if nodes[node_name]:
		return false
	for prereq in prerequisites[node_name]:
		if not nodes.get(prereq, false):
			return false
	if btp <= 0:
		return false
	return true

func buy_node(node_name: String) -> void:
	if can_buy_node(node_name):
		nodes[node_name] = true
		btp -= 1
		update_btp_label()
		update_nodes_ui()
		print("Purchased ", node_name, ", BTP left:", btp)
	else:
		print("Cannot purchase ", node_name)

func update_btp_label():
	$BTPLabel.text = "Tech Points: %d" % btp

func update_nodes_ui():
	for node_name in nodes.keys():
		var button_name = "%sButton" % node_name.capitalize()
		var button = get_node_or_null(button_name)
		if button == null:
			push_error("Button node not found: %s" % button_name)
			continue

		if nodes[node_name]:
			button.text = "ACTIVE"
			button.modulate = Color(0, 1, 0)  # green
			button.disabled = false  # keep enabled so text shows clearly
		elif can_buy_node(node_name):
			button.text = "+"
			button.modulate = Color(1, 1, 1)  # white
			button.disabled = false
		else:
			button.text = "+"
			button.modulate = Color(1, 0.5, 0.5)  # red tint
			button.disabled = true  # disable locked buttons

func _process(delta):
	if $HoverInfoLabel .visible:
		var mouse_pos = get_viewport().get_mouse_position()
		$HoverInfoLabel .position = mouse_pos + Vector2(16, 16)
