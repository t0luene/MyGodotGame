extends TileMap

enum FogState { OPAQUE = 0, FADED = 1, CLEAR = 2 }

@export var reveal_radius := 2

var fog_states = {}

func _ready(): 
	if has_node("Camera2D"):
		$Camera2D.make_current()

	_init_fog()

func _init_fog():
	var used_cells = get_used_cells(0)
	print("Used cells count:", used_cells.size())
	for cell_pos in used_cells:
		fog_states[cell_pos] = FogState.OPAQUE
		set_cell(int(FogState.OPAQUE), cell_pos)
		print("Painting Opaque fog at:", cell_pos)

func update_fog(player_global_pos: Vector2):
	var local_pos = to_local(player_global_pos)
	var player_tile = local_to_map(local_pos)
	print("Updating fog around player tile:", player_tile)

	for cell_pos in fog_states.keys():
		var dist = cell_pos.distance_to(player_tile)
		if dist <= reveal_radius:
			if fog_states[cell_pos] != FogState.CLEAR:
				fog_states[cell_pos] = FogState.CLEAR
				set_cell(int(FogState.CLEAR), cell_pos)
				print("Set CLEAR fog at:", cell_pos)
		else:
			if fog_states[cell_pos] == FogState.CLEAR:
				fog_states[cell_pos] = FogState.FADED
				set_cell(int(FogState.FADED), cell_pos)
				print("Set FADED fog at:", cell_pos)
