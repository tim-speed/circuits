extends TileMap
class_name Level

export var turns = 40
export var num_robots = 1

signal robot_num_change
signal request_pause
signal request_turn

enum { EMPTY = -1, ACTOR, OBSTACLE, OBJECT }

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

func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	
	var cell_target_type = get_cellv(cell_target)
	match cell_target_type:
		EMPTY:
			if world_to_map(factory.position) == cell_target:
				go_home(pawn)
			return update_pawn_postion(pawn, cell_start, cell_target)
		OBJECT:
			if !pawn.can_pick_up():
				return
			var object_pawn = get_cell_pawn(cell_target)
			var did_pickup = pawn.pick_up(object_pawn.item_name)
				
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
	set_cellv(cell_start, EMPTY)
	return map_to_world(cell_target)
