extends Window

@onready var answer_label = $AnswerLabel
@onready var q1 = $VBoxContainer/Question1Button
@onready var q2 = $VBoxContainer/Question2Button
@onready var q3 = $VBoxContainer/Question3Button

var current_employee = {}
var typing_speed := 0.01 # seconds per character

func _ready():
	q1.connect("pressed", Callable(self, "_on_question_1"))
	q2.connect("pressed", Callable(self, "_on_question_2"))
	q3.connect("pressed", Callable(self, "_on_question_3"))
	connect("close_requested", Callable(self, "_on_close_requested"))

func set_employee(emp: Dictionary):
	current_employee = emp
	answer_label.text = ""  # Clear previous text

func _on_question_1():
	_show_answer(current_employee.get("name", "They") + " says: I climb to higher ground, make eye contact, and assert dominance. Vacuums fear me.")

func _on_question_2():
	_show_answer(current_employee.get("name", "They") + " says: I vanish. Into the void. You won’t see me for 3 hours minimum.")

func _on_question_3():
	_show_answer(current_employee.get("name", "They") + " says: I love belly rubs, I can show you where is my fav part.")

func _on_close_requested():
	hide()

# --- Typewriter effect ---
func _show_answer(full_text: String) -> void:
	answer_label.text = ""
	# Launch the typewriter effect as a coroutine
	_start_typing(full_text)

func _start_typing(full_text: String) -> void:
	# Use a coroutine-style loop with await for a smooth effect
	answer_label.text = ""
	for i in range(full_text.length()):
		answer_label.text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout
