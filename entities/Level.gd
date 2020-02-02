extends TileMap
class_name Level

export var turns = 40
export var num_robots = 1

signal robot_deployed

enum { EMPTY = -1, ACTOR, OBSTACLE, OBJECT }

var Robot = preload("res://entities/Robot.tscn")

func _init():
	self.cell_quadrant_size = 32
	self.cell_size.x = 32
	self.cell_size.y = 32

func _ready():
	for child in get_children():
		set_cellv(world_to_map(child.position), child.type)
		
func request_deploy_robot(program):
	var factory = self.get_node("Factory")
	if !(factory && num_robots > 0):
		return
	
	var robot = Robot.instance()
	robot.program = program
	
	robot.position = factory.position
	
	self.add_child(robot)
	
	num_robots -= 1
	
	emit_signal("robot_deployed", num_robots)
	

func get_cell_pawn(coordinates):
	for node in get_children():
		if world_to_map(node.position) == coordinates:
			return node

func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	
	var cell_target_type = get_cellv(cell_target)
	match cell_target_type:
		EMPTY:
			return update_pawn_postion(pawn, cell_start, cell_target)
		OBJECT:
			var object_pawn = get_cell_pawn(cell_target)
			pawn.pick_up(object_pawn.item_name)
			object_pawn.queue_free()
			return update_pawn_postion(pawn, cell_start, cell_target)
			
func can_move(pawn, direction):
	var cell_start = world_to_map(pawn.postion)
	var cell_target = cell_start + direction
	
	var cell_target_type = get_cellv(cell_target)
	match cell_target_type:
		EMPTY:
			return true
		OBJECT:
			return true
		_:
			return false
			
func update_pawn_postion(pawn, cell_start, cell_target):
	set_cellv(cell_target, pawn.type)
	set_cellv(cell_start, EMPTY)
	return map_to_world(cell_target)
