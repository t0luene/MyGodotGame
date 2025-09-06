extends Popup

@onready var answer_label = $AnswerLabel
@onready var q1 = $VBoxContainer/Question1Button
@onready var q2 = $VBoxContainer/Question2Button
@onready var q3 = $VBoxContainer/Question3Button

var current_employee: Employee = null
var typing_speed := 0.01 # seconds per character

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	q1.connect("pressed", Callable(self, "_on_question_1"))
	q2.connect("pressed", Callable(self, "_on_question_2"))
	q3.connect("pressed", Callable(self, "_on_question_3"))
	connect("close_requested", Callable(self, "_on_close_requested"))
	
func _on_close_requested():
	queue_free()
	
func set_employee(emp: Employee):
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	current_employee = emp
	answer_label.text = ""  # Clear previous text

func _on_question_1():
	if not current_employee:
		return
	_show_answer(current_employee.name + " says: I climb to higher ground, make eye contact, and assert dominance. Vacuums fear me.")

func _on_question_2():
	if not current_employee:
		return
	_show_answer(current_employee.name + " says: I vanish. Into the void. You won’t see me for 3 hours minimum.")

func _on_question_3():
	if not current_employee:
		return
	_show_answer(current_employee.name + " says: I love belly rubs, I can show you where is my fav part.")


# --- Typewriter effect ---
func _show_answer(full_text: String) -> void:
	answer_label.text = ""
	_start_typing(full_text)

func _start_typing(full_text: String) -> void:
	answer_label.text = ""
	for i in range(full_text.length()):
		answer_label.text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout
