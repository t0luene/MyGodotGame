extends Window

@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var hire_button = $DescriptionPanel/HireButton
@onready var interview_button = $DescriptionPanel/InterviewButton
@onready var sourcing_button = $SourcingButton
@onready var refresh_button = $RefreshButton
@onready var interview_popup = preload("res://InterviewPopup.tscn").instantiate()
@onready var employee_card_scene = preload("res://EmployeeCard.tscn")
@onready var sourcing_popup = preload("res://Scenes/Shared/SourcingPopup.tscn").instantiate()

var hire_candidates: Array = []
var selected_emp: Employee = null

# ---------------------------
# Costs ⚡
# ---------------------------
const HIRE_COST_MONEY = 2
const REFRESH_COST_ENERGY = 1
const SOURCING_COST_ENERGY = 2

func _ready():
	add_child(sourcing_popup)
	sourcing_popup.hide()
	sourcing_button.connect("pressed", Callable(self, "_on_sourcing_pressed"))
	sourcing_popup.connect("role_selected", Callable(self, "_on_role_selected"))
	refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	add_child(interview_popup)
	interview_popup.hide()
	description_panel.visible = false
	hire_button.disabled = true

	# Get candidates from Global
	hire_candidates = Global.get_hire_candidates()
	spawn_cards()

	hire_button.connect("pressed", Callable(self, "_on_hire_pressed"))
	interview_button.connect("pressed", Callable(self, "_on_interview_pressed"))

	# Update labels
	_update_currency_labels()

# ---------------------------
# Spawn employee cards in the UI
# ---------------------------
func spawn_cards():
	for child in cards_container.get_children():
		child.queue_free()

	var total_slots = 6  # Always show 6 slots
	var current_candidates = hire_candidates.filter(func(emp): return not Global.hired_employees.has(emp))

	while current_candidates.size() < total_slots:
		current_candidates.append(null)

	for emp in current_candidates:
		var card = employee_card_scene.instantiate()
		if emp != null:
			card.get_node("NameLabel").text = emp.name
			card.get_node("RoleLabel").text = emp.role
			card.get_node("Avatar").texture = emp.avatar
			card.get_node("ProficiencyLabel").text = str(emp.proficiency)
			card.get_node("CostLabel").text = str(emp.cost)
			card.connect("pressed", Callable(self, "_on_card_pressed").bind(emp.id))
		else:
			card.get_node("NameLabel").text = ""
			card.get_node("RoleLabel").text = ""
			card.get_node("Avatar").texture = null
			card.get_node("ProficiencyLabel").text = ""
			card.get_node("CostLabel").text = ""
			card.disabled = true

		cards_container.add_child(card)

	# Disable hire button if already full or not enough money
	if selected_emp:
		hire_button.disabled = not (Global.can_hire_more() and Global.money >= HIRE_COST_MONEY)
	else:
		hire_button.disabled = true

	_update_currency_labels()

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
		hire_button.disabled = not (Global.can_hire_more() and Global.money >= HIRE_COST_MONEY)
	else:
		description_panel.visible = false
		hire_button.disabled = true

func _on_hire_pressed():
	if not selected_emp:
		return

	if Global.money < HIRE_COST_MONEY:
		print("Not enough money to hire!")
		return

	# Spend money
	Global.set_money(Global.money - HIRE_COST_MONEY)

	Global.hired_employees.append(selected_emp)
	print("Hired:", selected_emp.name, "Role:", selected_emp.role)

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

func _on_refresh_pressed():
	if not Global.spend_energy(REFRESH_COST_ENERGY):
		print("Not enough energy to refresh!")
		return

	hire_candidates = Global.refresh_hire_candidates()
	spawn_cards()
	description_panel.visible = false
	hire_button.disabled = true
	selected_emp = null
	_update_currency_labels()

func _on_sourcing_pressed():
	if not Global.spend_energy(SOURCING_COST_ENERGY):
		print("Not enough energy for sourcing!")
		return

	sourcing_popup.popup_centered()
	_update_currency_labels()

func _on_role_selected(role: String):
	print("Sourcing role selected:", role)
	hire_candidates = Global.refresh_hire_candidates_by_role(role)
	spawn_cards()
	description_panel.visible = false
	hire_button.disabled = true
	selected_emp = null
	_update_currency_labels()

# ---------------------------
# Helper: Update currency labels 💵🪫
# ---------------------------
func _update_currency_labels():
	# Update hire button
	if selected_emp:
		hire_button.disabled = not (Global.can_hire_more() and Global.money >= HIRE_COST_MONEY)
	else:
		hire_button.disabled = true

	# Update refresh button
	refresh_button.disabled = Global.energy < REFRESH_COST_ENERGY

	# Update sourcing button
	sourcing_button.disabled = Global.energy < SOURCING_COST_ENERGY
