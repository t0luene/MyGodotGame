extends Control

@export var node_scene: PackedScene = preload("res://Node.tscn")
@export var horizontal_spacing: int = 200
@export var vertical_spacing: int = 120

var btp := 5  # tech points

# Tree data structure
var tree_data = {
	"node1": { "children": ["node2a", "node2b"], "prerequisites": [], "description": "Start node" },
	"node2a": { "children": ["node3"], "prerequisites": ["node1"], "description": "Branch 2a" },
	"node2b": { "children": [], "prerequisites": ["node1"], "description": "Branch 2b" },
	"node3": { "children": ["node4a", "node4b"], "prerequisites": ["node2a"], "description": "Middle node" },
	"node4a": { "children": [], "prerequisites": ["node3"], "description": "Branch 4a" },
	"node4b": { "children": [], "prerequisites": ["node3"], "description": "Branch 4b" },
}

# Track unlocked nodes
var unlocked_nodes = {}

# Store button instances by node name
var node_buttons = {}

func _ready():
	# Clear previous children just in case
	for child in get_children():
		child.queue_free()

	# Layout the tech tree buttons and draw connections
	layout_tree()
	update_ui()

func layout_tree():
	var depths = {}  # node_name -> depth
	var layers = {}  # depth -> array of node_names

	var queue = []
	queue.append({"node": "node1", "depth": 0})
	depths["node1"] = 0

	while queue.size() > 0:
		var current = queue.pop_front()
		var node_name = current["node"]
		var depth = current["depth"]

		if not layers.has(depth):
			layers[depth] = []
		layers[depth].append(node_name)

		for child in tree_data[node_name]["children"]:
			if not depths.has(child) or depths[child] < depth + 1:
				depths[child] = depth + 1
				queue.append({"node": child, "depth": depth + 1})

	# Instantiate buttons and position them by depth and index
	for depth in layers.keys():
		var nodes_in_layer = layers[depth]
		for i in range(nodes_in_layer.size()):
			var node_name = nodes_in_layer[i]
			var button_instance = node_scene.instantiate()
			add_child(button_instance)

			# Position button: horizontal by depth, vertical by index
			var x = depth * horizontal_spacing
			var y = i * vertical_spacing
			button_instance.position = Vector2(x, y)

			button_instance.name = node_name
			var btn = button_instance.get_node("Button")
			btn.text = node_name.capitalize()

			# Disconnect if already connected to avoid duplicates (safe)
			var callable = Callable(self, "_on_node_pressed")
			if btn.is_connected("pressed", callable):
				btn.disconnect("pressed", callable)

			# Connect pressed signal with node name bound
			btn.pressed.connect(Callable(self, "_on_node_pressed").bind(node_name))

			node_buttons[node_name] = button_instance

func _on_node_pressed(node_name: String) -> void:
	if can_unlock(node_name):
		unlocked_nodes[node_name] = true
		btp -= 1
		update_ui()
		print("Unlocked %s! Remaining BTP: %d" % [node_name, btp])
	else:
		print("Cannot unlock %s yet." % node_name)

func can_unlock(node_name: String) -> bool:
	if unlocked_nodes.has(node_name):
		return false
	if btp <= 0:
		return false
	for prereq in tree_data[node_name]["prerequisites"]:
		if not unlocked_nodes.has(prereq):
			return false
	return true

func update_ui():
	for node_name in node_buttons.keys():
		var btn = node_buttons[node_name].get_node("Button")
		if unlocked_nodes.has(node_name):
			btn.text = "%s\n(Active)" % node_name.capitalize()
			btn.disabled = true
			btn.modulate = Color(0, 1, 0)  # green
		elif can_unlock(node_name):
			btn.text = "%s\n(Unlock)" % node_name.capitalize()
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)  # white
		else:
			btn.text = "%s\n(Locked)" % node_name.capitalize()
			btn.disabled = true
			btn.modulate = Color(0.7, 0.7, 0.7)  # grayish

	update_btp_label()
	update_connections()

func update_btp_label():
	if has_node("BTPLabel"):
		$BTPLabel.text = "Tech Points: %d" % btp

func update_connections():
	# Remove old lines
	for child in get_children():
		if child is Line2D:
			child.queue_free()

	# Draw lines from parent to children
	for node_name in tree_data.keys():
		var children = tree_data[node_name]["children"]
		var from_btn = node_buttons.get(node_name, null)
		if from_btn == null:
			continue
		for child_name in children:
			var to_btn = node_buttons.get(child_name, null)
			if to_btn == null:
				continue

			var line = Line2D.new()
			add_child(line)
			line.width = 3

			# Check if connection is active (both nodes unlocked)
			if unlocked_nodes.has(node_name) and unlocked_nodes.has(child_name):
				line.default_color = Color(0, 1, 0, 0.8)  # green with some transparency
			else:
				line.default_color = Color(1, 1, 1, 0.7)  # default white with transparency

			var btn_node_from = from_btn.get_node("Button")
			var from_pos = from_btn.position + btn_node_from.get_size() / 2

			var btn_node_to = to_btn.get_node("Button")
			var to_pos = to_btn.position + btn_node_to.get_size() / 2

			line.points = [from_pos, to_pos]
