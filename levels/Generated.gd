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
		floor(MAX_CELLS / 2) - FACTORY_CELLS - bots_in_need, extra_challenges),\
		0)
	var traps = round(extra_challenges * randf())
	bots_in_need += extra_challenges - traps
	var obstacles = floor(max((complexity - 1) * ((randi() % 8) + 1), 0))
	# Cap obstacles so we don't have more than our grid can handle
	obstacles = max(min(floor(MAX_CELLS / 2) - FACTORY_CELLS, obstacles), 0)
	
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

func get_empty_cells(grid: Array):
	var cells = []
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			if grid[y][x] == CELL_EMPTY:
				cells.append(Vector2(x, y))
	return cells

func copy_grid(grid: Array):
	var maze = grid.duplicate()
	for y in range(GRID_ROWS):
		maze[y] = grid[y].duplicate()
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
	
func is_cell_blocked(grid: Array, pos: Vector2):
	if pos.x < 0 or pos.x >= GRID_COLUMNS or pos.y < 0 or pos.y >= GRID_ROWS:
		# out of bounds is blocked
		return true
	match grid[pos.y][pos.x]:
		CELL_ROCK, MAZE_CELL_BLOCKED:
			return true
	return false
		
func check_path(start: Vector2, dest: Vector2):
	if is_cell_blocked(grid, start):
		return false
	# Copy the grid for maze solving
	var maze = grid_to_maze(copy_grid(grid))
	# Set the start and destination on it
	maze[start.y][start.x] = MAZE_CELL_START
	maze[dest.y][dest.x] = MAZE_CELL_END
	# Use clockwise max solving to determine if we have a clear path to fx, fy
	# Start from north
	var vfront = Vector2(0, 1)
	var pos = start
	var moves = [start]
	var rotations = 0
	# Rotation Loop
	while true:
		# Advancement Loop
		while true:
			var next = pos + vfront
			if next == dest:
				# We made it to the factory entrance
				print("\nFound factory:")
				print_grid(maze, grid)
				return true
			if is_cell_blocked(maze, next):
				var vright = vfront.rotated(deg2rad(90)).round()
				var vbackright = vright.rotated(deg2rad(45)).round()
				var vback = vfront.rotated(deg2rad(180)).round()
				var vbackleft = vback.rotated(deg2rad(45)).round()
				var vleft = vfront.rotated(deg2rad(270)).round()
				# Here we can check for a few patterns and insert a block if 
				#  applicable to make sure our algorithm doesn't come back
				#
				#      ? X ?  |  ? X ?  |  ? X ?
				#      _ _ X  |  X _ X  |  _ _ _
				#      _ _ ?  |  ? _ ?  |  _ _ _
				#
				# In any orientation of the above 3x3 squares, we can block off
				#  the center square so we don't bother stepping on it again
				#  where ? don't matter, X indicates a blocker and _ an empty
				if is_cell_blocked(maze, pos + vleft):
					if is_cell_blocked(maze, pos + vright) or \
						not is_cell_blocked(maze, pos + vbackright):
						# Block and reverse
						maze[pos.y][pos.x] = MAZE_CELL_BLOCKED
						rotations = 0
						if moves.size() > 1:
							moves.pop_back()
							pos = moves[moves.size() - 1]
						else:
							pos = start
				elif is_cell_blocked(maze, pos + vright):
					if !is_cell_blocked(maze, pos + vbackleft):
						# Block and reverse
						maze[pos.y][pos.x] = MAZE_CELL_BLOCKED
						rotations = 0
						if moves.size() > 1:
							moves.pop_back()
							pos = moves[moves.size() - 1]
						else:
							pos = start
				elif not is_cell_blocked(maze, pos + vbackright) and \
					not is_cell_blocked(maze, pos + vbackleft):
					# Block and reverse
					maze[pos.y][pos.x] = MAZE_CELL_BLOCKED
					rotations = 0
					if moves.size() > 1:
						moves.pop_back()
						pos = moves[moves.size() - 1]
					else:
						pos = start
				break # Loop to rotate
#			if maze[next.y][next.x] == MAZE_CELL_MARKER:
#				if rotations < 4:
#					# Treat as blocking until we try all directions from 
#					#  this cell
#					break # Loop to rotate
#				else:
#					# Allow traversal but mark the current cell as dead
#					maze[pos.y][pos.x] = MAZE_CELL_BLOCKED
			# Set a path marker and continue
			if next != start:
				maze[next.y][next.x] = MAZE_CELL_MARKER
			moves.append(next)
			pos = next
			# Reset rotations because we moved successfully
			rotations = 0
		# Rotate the direction
		rotations += 1
		vfront = vfront.rotated(deg2rad(90)).round()
		# Check if stuck
		# TODO: Actually check the blocks around it
		if rotations > 10 or moves.size() > GRID_COLUMNS * GRID_COLUMNS:
			# Could not find any new or previous traversable 
			break # Outer loop
		# Else can't move anymore so go back to top of loop to rotate
	print("\nFailed to find factory:")
	print_grid(maze, grid)
	return false

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
