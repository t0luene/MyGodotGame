extends Window

@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var hire_button = $DescriptionPanel/HireButton
@onready var interview_button = $DescriptionPanel/InterviewButton
@onready var interview_popup = preload("res://InterviewPopup.tscn").instantiate()
@onready var employee_card_scene = preload("res://EmployeeCard.tscn")

var hire_candidates: Array = []
var selected_emp: Employee = null

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	add_child(interview_popup)
	interview_popup.hide()
	description_panel.visible = false
	hire_button.disabled = true

	# ✅ Get candidates from Global (won’t regenerate if already generated today)
	hire_candidates = Global.get_hire_candidates()
	spawn_cards()

	hire_button.connect("pressed", Callable(self, "_on_hire_pressed"))
	interview_button.connect("pressed", Callable(self, "_on_interview_pressed"))


# ----------------------------
# Spawn employee cards in the UI
# ----------------------------
func spawn_cards():
	for child in cards_container.get_children():
		child.queue_free()

	for emp in hire_candidates:
		# Skip if already hired
		if Global.hired_employees.has(emp):
			continue

		var card = employee_card_scene.instantiate()
		card.get_node("NameLabel").text = emp.name
		card.get_node("RoleLabel").text = emp.role
		card.get_node("Avatar").texture = emp.avatar
		card.get_node("ProficiencyLabel").text = str(emp.proficiency)
		card.get_node("CostLabel").text = str(emp.cost)

		card.connect("pressed", Callable(self, "_on_card_pressed").bind(emp.id))
		cards_container.add_child(card)

func _on_card_pressed(emp_id: int) -> void:
	selected_emp = null
	for emp in hire_candidates:
		if emp.id == emp_id:
			selected_emp = emp
			break

	if selected_emp:
		description_panel.visible = true
		desc_name_label.text = selected_emp.name
		desc_bio_label.text = selected_emp.bio
		hire_button.disabled = false


func _on_hire_pressed():
	if not selected_emp:
		return

	Global.hired_employees.append(selected_emp)
	print("Hired:", selected_emp.name, "Role:", selected_emp.role)

	# Remove from local candidates
	hire_candidates = hire_candidates.filter(func(e): return e != selected_emp)
	spawn_cards()
	description_panel.visible = false
	hire_button.disabled = true
	selected_emp = null

func _on_interview_pressed():
	if not selected_emp:
		return
	interview_popup.set_employee(selected_emp)
	interview_popup.popup_centered()

func _on_close_requested():
	queue_free()
