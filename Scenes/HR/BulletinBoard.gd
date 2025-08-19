extends Control

@onready var comments_container = $ScrollContainer/CommentsContainer
@onready var comment_item_scene = preload("res://CommentItem.tscn")

@onready var emoji_menu = $EmojiMenu
var selected_comment_index := -1

var comments_data = [
	{ 
		"name": "Alice",
		"text": "Great idea: Monthly team lunches to boost morale!",
		"avatar": preload("res://Assets/Avatars/emp1.png"),
		"reaction": ""
	},
	{ 
		"name": "Bob",
		"text": "We should upgrade the office chairs for better ergonomics.",
		"avatar": preload("res://Assets/Avatars/emp2.png"),
		"reaction": ""
	},
	{ 
		"name": "Cleo",
		"text": "Does anyone want to join my weekend paintball game?",
		"avatar": preload("res://Assets/Avatars/emp3.png"),
		"reaction": ""
	},
	{ 
		"name": "David",
		"text": "Mandatory yoga sessions are a waste of time.",
		"avatar": preload("res://Assets/Avatars/emp4.png"),
		"reaction": ""
	},
	{ 
		"name": "Eva",
		"text": "Can we please ban personal political discussions at work?",
		"avatar": preload("res://Assets/Avatars/emp5.png"),
		"reaction": ""
	},
	{ 
		"name": "Frank",
		"text": "I found a kitten in the parking lot today! So cute! 🐱",
		"avatar": preload("res://Assets/Avatars/emp6.png"),
		"reaction": ""
	}
]


func _ready():
	emoji_menu.clear()
	emoji_menu.add_item("👍")
	emoji_menu.add_item("👎")
	emoji_menu.add_item("😡")
	emoji_menu.id_pressed.connect(Callable(self, "_on_emoji_selected"))

	_load_comments()


func _load_comments() -> void:
	# Clear old comments
	for child in comments_container.get_children():
		child.queue_free()

	for i in range(comments_data.size()):
		var c = comments_data[i]
		var item = comment_item_scene.instantiate()

		# Match your node structure
		var name_label = item.get_node("VBoxContainer/NameLabel")
		var comment_label = item.get_node("VBoxContainer/CommentLabel")
		var avatar_node = item.get_node("Avatar")

		name_label.text = c.get("name", "Unknown")
		comment_label.text = c.get("text", "")

		if avatar_node is TextureRect:
			avatar_node.texture = c.get("avatar", null)

		comments_container.add_child(item)
		var reaction_btn = item.get_node("ReactionButton") # adjust path if needed

		if reaction_btn:
			var reaction = c.get("reaction", "")
			reaction_btn.text = reaction if reaction != "" else "➕"
			reaction_btn.pressed.connect(Callable(self, "_on_reaction_pressed").bind(i))


func _on_reaction_pressed(comment_index: int) -> void:
	selected_comment_index = comment_index

	# Button and its global position
	var button = comments_container.get_child(comment_index).get_node("ReactionButton")
	var button_global_pos = button.get_global_position()

	# Convert global position to the emoji_menu parent's local coordinates
	var parent_control = emoji_menu.get_parent() as Control
	var parent_global_pos = parent_control.get_global_position()
	var local_pos = button_global_pos - parent_global_pos

	# Offset to the right of the button so the popup doesn't overlap
	var offset = Vector2(button.size.x, 0)  # ✅ use size in Godot 4

	emoji_menu.position = local_pos + offset  # ✅ position instead of rect_position in Godot 4
	emoji_menu.popup()


func _on_emoji_selected(id: int) -> void:
	if selected_comment_index == -1:
		return

	var emoji = emoji_menu.get_item_text(id)
	comments_data[selected_comment_index]["reaction"] = emoji
	_load_comments()
	selected_comment_index = -1
