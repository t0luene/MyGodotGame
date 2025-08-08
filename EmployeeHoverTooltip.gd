extends Control

@onready var avatar_texture_rect = $Panel/VBoxContainer/AvatarTextureRect
@onready var name_label = $Panel/VBoxContainer/NameLabel
@onready var role_label = $Panel/VBoxContainer/RoleLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel

func update_info(name: String, role: String, description: String, avatar_texture: Texture):
	name_label.text = name
	role_label.text = role
	description_label.text = description
	avatar_texture_rect.texture = avatar_texture

func show_tooltip():
	self.visible = true

func hide_tooltip():
	self.visible = false
