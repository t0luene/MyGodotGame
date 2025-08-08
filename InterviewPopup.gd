extends Window

@onready var answer_label = $VBoxContainer/AnswerLabel
@onready var q1 = $VBoxContainer/Question1Button
@onready var q2 = $VBoxContainer/Question2Button
@onready var q3 = $VBoxContainer/Question3Button

var current_employee = {}

func _ready():
	q1.connect("pressed", Callable(self, "_on_question_1"))
	q2.connect("pressed", Callable(self, "_on_question_2"))
	q3.connect("pressed", Callable(self, "_on_question_3"))
	connect("close_requested", Callable(self, "_on_close_requested"))


func set_employee(emp: Dictionary):
	current_employee = emp
	answer_label.text = ""  # Clear previous text

func _on_question_1():
	answer_label.text = current_employee.get("name", "They") + " says: I climb to higher ground, make eye contact, and assert dominance. Vacuums fear me."

func _on_question_2():
	answer_label.text = current_employee.get("name", "They") + " says: I vanish. Into the void. You won’t see me for 3 hours minimum."

func _on_question_3():
	answer_label.text = current_employee.get("name", "They") + " says: I schedule my naps around the vacuum schedule. It’s called boundaries"

func _on_close_requested():
	hide()  # Or do other cleanup here
