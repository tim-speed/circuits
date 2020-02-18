extends Level

const GRID_COLUMNS = 21
const GRID_ROWS = 17
const MAX_CELLS = GRID_COLUMNS * GRID_ROWS
const FACTORY_HEIGHT = 3
const FACTORY_WIDTH = 4
const FACTORY_CELLS = FACTORY_WIDTH * FACTORY_HEIGHT

enum { EASY = 1, MEDIUM, HARD, DEEPBLUE }
enum { CELL_EMPTY = 0, CELL_FACTORY = 1, CELL_BOT = 2, CELL_ROCK = 3, 
	CELL_HOLE = 4 }
enum { MAZE_CELL_START = -4, MAZE_CELL_END = -3, MAZE_CELL_BLOCKED = -2, 
	MAZE_CELL_MARKER = -1, MAZE_CELL_EMPTY = 0 }

export var difficulty = EASY
export var complexity = 1

var Factory = preload("res://entities/Factory.tscn")
var Hole = preload("res://entities/Hole.tscn")
var Rock = preload("res://entities/Rock.tscn")

var grid = []

func _ready():
	# Randomize, without this the code will generate the same level at start
	randomize()
	
	if grid.size() == 0:
		generate()
	else:
		refresh_map()

func generate():
	# Define empty grid to populate
	grid = []
	grid.resize(GRID_ROWS)
	for y in range(GRID_ROWS):
		var row = []
		row.resize(GRID_COLUMNS)
		for x in range(GRID_COLUMNS):
			row[x] = CELL_EMPTY
		grid[y] = row
	
	complexity = min(max(complexity, 1), 100)
	difficulty = min(max(difficulty, EASY), DEEPBLUE)
	var bots_in_need = complexity
	var extra_challenges = round(complexity * 0.25 * difficulty)
	# Cap extra challenges so we don't have more than our grid can handle
	extra_challenges = max(min(\
		floor(MAX_CELLS / 2.0) - FACTORY_CELLS - bots_in_need, \
		extra_challenges), 0)
	var traps = round(extra_challenges * randf())
	bots_in_need += extra_challenges - traps
	var obstacles = floor(max((complexity - 1) * ((randi() % 8) + 1), 0))
	# Cap obstacles so we don't have more than our grid can handle
	obstacles = max(min(floor(MAX_CELLS / 2.0) - FACTORY_CELLS, obstacles), 0)
	
	print("Placing ", bots_in_need, " bots, ", obstacles, " rocks, ", \
		traps, " holes")
	
	# Place factory
	# Y coordinate gets cut 1 short of the total grid so robots have room
	# to enter and exit the factory from the bottom
	var fx = max(randi() % (GRID_COLUMNS + 1 - FACTORY_WIDTH), 0)
	var fy = max(randi() % (GRID_ROWS - FACTORY_HEIGHT), 0)
	# Vars to store the entrance coords
	# TODO: This should happen in the loop, but we need to be able to access 
	#  Factory's type_map.
	var fex = fx + 1
	var fey = fy + 2
	for y in range(FACTORY_HEIGHT):
		for x in range(FACTORY_WIDTH):
			grid[fy + y][fx + x] = CELL_FACTORY
	
	# Place broken bots randomly in empty cells
	for _i in range(bots_in_need):
		while true:
			var ry = randi() % GRID_ROWS
			var rx = randi() % GRID_COLUMNS
			if grid[ry][rx] == CELL_EMPTY:
				grid[ry][rx] = CELL_BOT
				break
	
	# Place obstacles in empty cells, checking that they don't block pathing 
	#  to factory for empty and bot cells around them
	# TODO: Add a more intelligent method as well that places them according to
	#  the difficulty setting, like in more challenging places.
	var empty_cells = get_empty_cells(grid)
	obstacles = min(obstacles, empty_cells.size())
	print("Empty cells while placing obstacles: ", empty_cells.size())
	for _i in range(obstacles):
		while empty_cells.size() > 0:
			var rand_cell_i = randi() % empty_cells.size()
			var rand_cell = empty_cells[rand_cell_i]
			if check_path(rand_cell, Vector2(fex, fey)):
				grid[rand_cell.y][rand_cell.x] = CELL_ROCK
			empty_cells.remove(rand_cell_i)
	
	# Place traps
	# TODO: Intelligent trap placement
	
	# Refresh the map
	refresh_map()
	
func refresh_map():
	# Clear level
	for c in get_children():
		remove_child(c)
		
	var bots_placed = 0
	var rocks_placed = 0
	var holes_placed = 0
	
	# Add Entities to Level
	var factory_placed = false
	for y in range(GRID_ROWS):
		var row = grid[y]
		for x in range(GRID_COLUMNS):
			match (row[x]):
				CELL_BOT:
					bots_placed += 1
					add_entity(BrokenFriend, x, y)
				CELL_ROCK:
					rocks_placed += 1
					add_entity(Rock, x, y)
				CELL_HOLE:
					holes_placed += 1
					add_entity(Hole, x, y)
				CELL_FACTORY:
					if not factory_placed:
						add_entity(Factory, x, y)
						factory_placed = true
	
	print("Placed ", bots_placed, " bots, ", rocks_placed, " rocks, ", \
		holes_placed, " holes")
	
	# Set level defaults to make it solvable based on difficulty
	# TODO: trap detection on path and total turn setting to make it solveable
	
	# Call setup_level on Level
	setup_level()

func add_entity(type, grid_x, grid_y):
	var e = type.instance()
	e.position = Vector2(grid_x * CELL_PIXELS, grid_y * CELL_PIXELS)
	add_child(e)

func get_empty_cells(g: Array):
	var cells = []
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			if g[y][x] == CELL_EMPTY:
				cells.append(Vector2(x, y))
	return cells

func copy_grid(g: Array):
	var maze = g.duplicate()
	for y in range(GRID_ROWS):
		maze[y] = g[y].duplicate()
	return maze
	
func grid_to_maze(maze: Array):
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			match maze[y][x]:
				CELL_FACTORY, CELL_ROCK:
					maze[y][x] = MAZE_CELL_BLOCKED
				_:
					maze[y][x] = MAZE_CELL_EMPTY
	return maze
	
func is_cell_blocked(g: Array, pos: Vector2):
	if pos.x < 0 or pos.x >= GRID_COLUMNS or pos.y < 0 or pos.y >= GRID_ROWS:
		# out of bounds is blocked
		return true
	match g[pos.y][pos.x]:
		CELL_ROCK, MAZE_CELL_BLOCKED:
			return true
	return false

func grid_pos_id(pos: Vector2):
	return pos.x + 1 + (pos.y * GRID_COLUMNS)

func id_grid_pos(id: int):
	var i = id - 1
	return Vector2(i % GRID_COLUMNS, floor(i / float(GRID_COLUMNS)))
		
func check_path(start: Vector2, dest: Vector2):
	if is_cell_blocked(grid, start) or is_cell_blocked(grid, dest):
		return false
	# Copy the grid for maze solving
	var maze = grid_to_maze(copy_grid(grid))
	# Set the start and destination on it
	maze[start.y][start.x] = MAZE_CELL_START
	maze[dest.y][dest.x] = MAZE_CELL_END
	
	var path = AStar2D.new()
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			var pos = Vector2(x, y)
			var i = grid_pos_id(pos)
			if is_cell_blocked(maze, pos):
				continue
			path.add_point(i, pos)
			# Connect to neighbours if able
			# Left
			if !is_cell_blocked(maze, Vector2(x - 1, y)):
				path.connect_points(i, i - 1)
			# Above
			if !is_cell_blocked(maze, Vector2(x, y - 1)):
				path.connect_points(i, i - GRID_COLUMNS)
			# The connecting is bidirectional so we only ever need to look back
	
	var start_id = grid_pos_id(start)
	var dest_id = grid_pos_id(dest)
	var p = path.get_id_path(start_id, dest_id)
	
	# DEBUG PRINTING
	for pp in p:
		var v = id_grid_pos(pp)
		if v != start && v != dest:
			maze[v.y][v.x] = MAZE_CELL_MARKER
	
	# if p.size() == 0:
	print("\nPATH DEBUG:")
	print_grid(maze, grid)
	
	return p.size() > 1

func cell_to_char(cellv: int):
	match cellv:
		CELL_EMPTY:
			return "_"
		CELL_BOT:
			return "b"
		CELL_FACTORY:
			return "F"
		CELL_HOLE:
			return "o"
		CELL_ROCK:
			return "#"
		MAZE_CELL_MARKER:
			return "*"
		MAZE_CELL_BLOCKED:
			return "X"
	return "?"
	
func print_grid(g1: Array, g2: Array):
	var borderline = "-".repeat((GRID_COLUMNS * 3) + 3)
	print(borderline)
	for y in range(GRID_ROWS):
		var line = "|"
		for x in range(GRID_COLUMNS):
			line += " " + cell_to_char(g1[y][x]) + cell_to_char(g2[y][x])
		print(line + " |")
	print(borderline)
