extends Control

@onready var avatar_texture_rect: TextureRect = $TextureRect

func set_avatar(texture: Texture2D) -> void:
	if avatar_texture_rect:
		avatar_texture_rect.texture = texture
	else:
		push_error("avatar_texture_rect is null. Check your scene setup.")
