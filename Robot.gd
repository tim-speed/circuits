extends Area2D

var program = [
	{
		type = "Gate",
		condition = {
			type = "IsNearLocation",
			options = {
				location = Vector2(400, 400)
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
		task = "MoveTowardsLocation",
		options = {
			location = Vector2(400, 400)
		}
	},
	{
		type = "GoTo",
		position = 0
	},
];

var program_position = 0;

export var speed = 16;

func run_turn():
	var task_node = get_task_node()
	if !task_node:
		return
	var current_task = task_node.task
	
	match current_task:
		"Wander":
			wander()
		"Wait":
			return

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
				var passed = process_conditional_node(program_node)
				if passed:
					program_position += 1
				else:
					program_position = program_node.else_position
			"GoTo":
				program_position = program_node.position
	
	program_position += 1
	return program_node

func process_conditional_node(node):
	return true

func wander():
	var direction = randi() % 4
	var velocity = Vector2()
	match direction:
		0:
			velocity.x = 1
		1:
			velocity.x = -1
		2:
			velocity.y = 1
		3:
			velocity.y = -1

	position += velocity * speed
