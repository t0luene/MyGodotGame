# Employee.gd
extends Resource
class_name Employee

@export var id: int
@export var name: String = "Unknown"
@export var role: String = "Unknown"
@export var avatar: Texture2D
@export var proficiency: int = 0
@export var cost: int = 0
@export var bio: String = ""
@export var is_busy: bool = false

func is_available() -> bool:
	return not is_busy
