extends TileMap
class_name Level

const CELL_PIXELS = 32
const MIN_CELL_X = 0
const MIN_CELL_Y = 0
const MAX_CELL_X = 21
const MAX_CELL_Y = 17

export var turns = 40
export var num_robots = 1
var robots_in_need = 0 # Counted from scene, leave local

signal robot_num_change
signal request_pause
signal request_turn

enum { EMPTY = -1, ACTOR, OBSTACLE, OBJECT, FACTORY, TRAP }

var Robot = preload("res://entities/Robot.tscn")
var BrokenFriend = preload("res://entities/BrokenFriend.tscn")

# TODO: Support multiple factories
var factory

func _init():
	self.cell_quadrant_size = CELL_PIXELS
	self.cell_size.x = CELL_PIXELS
	self.cell_size.y = CELL_PIXELS

func _ready():
	factory = self.get_node("Factory")
	for child in get_children():
		if child.get("type_map") != null:
			# Type Map for objects larger than 1 cell.. move to its own func?
			var origin = world_to_map(child.position)
			var y = 0
			for row in child.type_map:
				var x = 0
				for cell in row:
					set_cellv(Vector2(origin.x + x, origin.y + y), cell)
					x += 1
				y += 1
		else:
			set_cellv(world_to_map(child.position), child.type)
			if child.type == OBJECT and child.item_name == "BrokenFriend":
				robots_in_need += 1
	emit_signal("robot_num_change", num_robots, robots_in_need)
		
func request_deploy_robot(program):
	if !(factory && num_robots > 0):
		return
	
	var robot = Robot.instance()
	robot.program = program
	
	robot.position = Vector2(factory.position.x + CELL_PIXELS, \
		factory.position.y + (2 * CELL_PIXELS))
	
	self.add_child(robot)
	
	num_robots -= 1
	
	emit_signal("request_turn")
	emit_signal("robot_num_change", num_robots, robots_in_need)

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
			set_cellv(cell_info.start, EMPTY)
			go_home(pawn)
			return map_to_world(cell_info.target)
		TRAP:
			return activate_trap(pawn, cell_info)
		EMPTY:
			return update_pawn_postion(pawn, cell_info.start, cell_info.target)
		OBJECT:
			if !pawn.can_pick_up():
				return
			var object_pawn = get_cell_pawn(cell_info.target)
			var did_pickup = pawn.pick_up(object_pawn.item_name)
				
			object_pawn.queue_free() # Remove from parent
			return update_pawn_postion(pawn, cell_info.start, cell_info.target)

func activate_trap(pawn, cell_info):
	if get_cellv(cell_info.start) == ACTOR:
		set_cellv(cell_info.start, EMPTY)
	# Remove robot and trap and place dead robot at trap
	var trap = get_cell_pawn(cell_info.target)
	trap.queue_free() # Remove from parent
	pawn.queue_free() # Remove from parent
	var friend = BrokenFriend.instance()
	var pos = map_to_world(cell_info.target)
	friend.position = pos
	self.add_child(friend)
	set_cellv(cell_info.target, OBJECT)
	robots_in_need += 1
	emit_signal("robot_num_change", num_robots, robots_in_need)
	return pos

func can_move(pawn, direction):
	var cell_info = get_cell_info(pawn, direction)
	match cell_info.type:
		EMPTY, TRAP:
			return true
		OBJECT:
			return pawn.can_pick_up()
		_:
			return false

func go_home(pawn):
	if pawn.held_item == "BrokenFriend":
		num_robots += 2
		robots_in_need -= 1
	else:
		num_robots += 1
	
	var robots = get_tree().get_nodes_in_group("Robots")
	
	if robots.size() <= 1:
		emit_signal("request_pause")
	
	pawn.queue_free() # Remove from parent
	emit_signal("robot_num_change", num_robots, robots_in_need)

func update_pawn_postion(pawn, cell_start, cell_target):
	var cell_type = get_cellv(cell_start)
	
	if cell_type != FACTORY and cell_type != OBSTACLE:
		set_cellv(cell_start, EMPTY)
	set_cellv(cell_target, pawn.type)
	
	return map_to_world(cell_target)
