extends Node2D

var type = 0

var program = [
	{
		type = "Gate",
		condition = {
			type = "IsAtCoordinates",
			options = {
				coordinates = Vector2(8, 4)
			}
		},
		else_position = 3
	},
	{
		type = "Task",
		task = "Wander"
	},
	{
		type = "GoTo",
		position = 0
	},
	{
		type = "Task",
		task = "Move",
		options = {
			direction_name = "Right"
		}
	},
	{
		type = "GoTo",
		position = 0
	},
];

var program_position = 0

var Grid

var held_item

func _ready():
	Grid = get_parent()

func run_turn():
	var task_node = get_task_node()
	if !task_node:
		return
	var current_task = task_node.task
	
	match current_task:
		"Move":
			move_in_direction(task_node.options.direction_name)
		"Wander":
			wander()
		"Wait":
			pass

func get_task_node():
	if program.empty():
		return
	
	var program_node
	var processing = true
	while processing:
		if program_position >= program.size():
			program_position = 0
			
		program_node = program[program_position]
		
		match program_node.type:
			"Task":
				processing = false
			"Gate":
				var passed = process_conditional_node(program_node.condition)
				if passed:
					program_position += 1
				else:
					program_position = program_node.else_position
			"GoTo":
				program_position = program_node.position
	
	program_position += 1
	return program_node

func process_conditional_node(node):
	match node.type:
		"IsAtCoordinates":
			return is_at_coordinates(node.options.coordinates)
		"HasItem":
			return has_item(node.options.item_name)
		"CanMoveInDirection":
			return can_move_in_direction(node.options.direction_name)
	return false

func is_at_coordinates(coordinates):
	var grid_position = Grid.world_to_map(position)
	return (grid_position - coordinates).length() < 1
	
func has_item(item_name):
	return (!item_name && held_item) || (item_name && (item_name == held_item))
	
func can_move_in_direction(direction_name):
	var direction
	match direction_name:
		"Up": direction = Vector2(0, -1)
		"Down": direction = Vector2(0, 1)
		"Left": direction = Vector2(-1, 0)
		"Right": direction = Vector2(1, 0)
	
	return Grid.can_move(direction);

func wander():
	var directionInt = randi() % 4
	match directionInt:
		0: move(Vector2(0, -1))
		1: move(Vector2(0, 1))
		2: move(Vector2(-1, 0))
		3: move(Vector2(1, 0))

func move_in_direction(direction_name):
	match direction_name:
		"Up": move(Vector2(0, -1))
		"Down": move(Vector2(0, 1))
		"Left": move(Vector2(-1, 0))
		"Right": move(Vector2(1, 0))
	
func move(direction):
	var target_position = Grid.request_move(self, direction)
	if target_position:
		position = target_position
