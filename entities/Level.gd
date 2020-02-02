extends TileMap
class_name Level

const MIN_CELL_X = 0
const MIN_CELL_Y = 0
const MAX_CELL_X = 21
const MAX_CELL_Y = 17

export var turns = 40
export var num_robots = 1

signal robot_num_change
signal request_pause
signal request_turn

enum { EMPTY = -1, ACTOR, OBSTACLE, OBJECT, FACTORY }

var Robot = preload("res://entities/Robot.tscn")

var factory

func _init():
	self.cell_quadrant_size = 32
	self.cell_size.x = 32
	self.cell_size.y = 32

func _ready():
	factory = self.get_node("Factory")
	for child in get_children():
		set_cellv(world_to_map(child.position), child.type)
		
func request_deploy_robot(program):
	if !(factory && num_robots > 0):
		return
	
	var robot = Robot.instance()
	robot.program = program
	
	robot.position = factory.position
	
	self.add_child(robot)
	
	num_robots -= 1
	
	emit_signal("request_turn")
	emit_signal("robot_num_change", num_robots)

func get_cell_pawn(coordinates):
	for node in get_children():
		if world_to_map(node.position) == coordinates:
			return node

func get_cell_info(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	
	if cell_target[0] < MIN_CELL_X or cell_target[0] >= MAX_CELL_X \
		or cell_target[1] < MIN_CELL_Y or cell_target[1] >= MAX_CELL_Y:
		return {
			"start": cell_start,
			"target": cell_target,
			"type": OBSTACLE
		}
	
	var cell_target_type = get_cellv(cell_target)
	return {
		"start": cell_start,
		"target": cell_target,
		"type": cell_target_type
	}

func request_move(pawn, direction):
	var cell_info = get_cell_info(pawn, direction)
	match cell_info.type:
		FACTORY:
			go_home(pawn)
			return update_pawn_postion(pawn, cell_info.start, cell_info.target)
		EMPTY:
			return update_pawn_postion(pawn, cell_info.start, cell_info.target)
		OBJECT:
			if !pawn.can_pick_up():
				return
			var object_pawn = get_cell_pawn(cell_info.target)
			var did_pickup = pawn.pick_up(object_pawn.item_name)
				
			object_pawn.queue_free()	
			return update_pawn_postion(pawn, cell_info.start, cell_info.target)

func can_move(pawn, direction):
	var cell_info = get_cell_info(pawn, direction)
	match cell_info.type:
		EMPTY:
			return true
		OBJECT:
			return pawn.can_pick_up()
		_:
			return false

func go_home(pawn):
	if pawn.held_item == "BrokenFriend":
		num_robots += 2
	else:
		num_robots += 1
	
	var robots = get_tree().get_nodes_in_group("Robots")
	
	if robots.size() <= 1:
		emit_signal("request_pause")
	
	pawn.queue_free()
	emit_signal("robot_num_change", num_robots)

func update_pawn_postion(pawn, cell_start, cell_target):
	set_cellv(cell_target, pawn.type)
	if get_cellv(cell_start) != FACTORY:
		set_cellv(cell_start, EMPTY)
	return map_to_world(cell_target)
