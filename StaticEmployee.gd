extends Node2D

signal conversation_started(data: Dictionary)

@export var dialogue_text := "Hey boss, Can I get a Promotion?"
@export var option_a := "No lol, Get back to work"
@export var option_b := "Ill think about it."
@onready var anim := $AnimatedSprite2D  # or AnimationPlayer if you're using that

@onready var area = $Area2D
@onready var question_mark = $QuestionMark

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		question_mark.visible = false
		area.monitoring = false  # Prevent retrigger
		emit_signal("conversation_started", {
			"text": dialogue_text,
			"choices": [option_a, option_b]
		})
