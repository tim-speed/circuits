extends AnimatedSprite

var type = 0

var program = [
#	{
#		type = "Task",
#		task = "Move",
#		options = {
#			direction_name = "Down"
#		}
#	},
#	{
#		type = "Task",
#		task = "Move",
#		options = {
#			direction_name = "Right"
#		}
#	},
];

var program_position = 0

var Grid

var held_item

var robo_vars = {}

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
			"SetVar":
				robo_vars[program_node.options.name] = program_node.options.value
				program_position += 1
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
		"IsVarEqual":
			return is_var_equal(node.options.name, node.options.value)
		"IsAtCoordinates":
			return is_at_coordinates(node.options.coordinates)
		"IsCompassOf":
			return is_compass_of(
				node.options.v, node.options.compass_direction
			)
		"HasBrokenFriend":
			return has_item("BrokenFriend")
		"HasItem":
			return has_item(node.options.item_name)
		"CanMoveInDirection":
			return can_move_in_direction(node.options.direction_name)
	return false

func is_var_equal(name, value):
	if !robo_vars.has(name):
		return false
	
	return robo_vars[name] == value
	
func is_at_coordinates(coordinates):
	var grid_position = Grid.world_to_map(position)
	return (grid_position - coordinates).length() < 1
	
func is_compass_of(value, compass_direction):
	var grid_position = Grid.world_to_map(position)
	match compass_direction:
		"North":
			return grid_position.y < value
		"South":
			return grid_position.y > value
		"East":
			return grid_position.x > value
		"West":
			return grid_position.x < value
	
func has_item(item_name):
	return (!item_name && held_item) || (item_name && (item_name == held_item))
	
func can_pick_up():
	return !held_item

func pick_up(item_name):
	held_item = item_name
	
func can_move_in_direction(direction_name):
	var direction
	match direction_name:
		"Up": direction = Vector2(0, -1)
		"Down": direction = Vector2(0, 1)
		"Left": direction = Vector2(-1, 0)
		"Right": direction = Vector2(1, 0)
	
	return Grid.can_move(self, direction);

func wander():
	var directionInt = randi() % 4
	match directionInt:
		0: move(Vector2(0, -1))
		1: move(Vector2(0, 1))
		2: move(Vector2(-1, 0))
		3: move(Vector2(1, 0))

func move_in_direction(direction_name):
	match direction_name:
		"Up": 
			self.animation = "MoveUp"
			move(Vector2(0, -1))
		"Down": 
			self.animation = "MoveDown"
			move(Vector2(0, 1))
		"Left":
			self.animation = "MoveLeft" 
			move(Vector2(-1, 0))
		"Right":
			self.animation = "MoveRight"
			move(Vector2(1, 0))
	
func move(direction):
	var target_position = Grid.request_move(self, direction)
	if target_position:
		position = target_position
