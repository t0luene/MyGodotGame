extends Button

signal card_selected(emp_id: int)

@onready var avatar: TextureRect = $Avatar
@onready var name_label: Label = $NameLabel
@onready var role_label: Label = $RoleLabel
@onready var proficiency_label: Label = $ProficiencyLabel
@onready var cost_label: Label = $CostLabel

var employee: Employee = null

func set_employee(emp: Employee) -> void:
	employee = emp
	if employee == null:
		print("EmployeeCard: set_employee received null")
		return
	
	name_label.text = employee.name
	role_label.text = employee.role
	proficiency_label.text = str(employee.proficiency)
	cost_label.text = str(employee.cost)
	avatar.texture = employee.avatar

func _pressed() -> void:
	if employee:
		print("[EmployeeCard] Button pressed for emp_id:", employee.id)
		card_selected.emit(employee.id)
	else:
		print("[EmployeeCard] Button pressed but employee is null")
