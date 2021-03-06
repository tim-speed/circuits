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
enum { MAZE_CELL_DEAD = -2, MAZE_CELL_MARKER = -1 }

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
	for _i in range(obstacles):
		var placing = true
		while placing:
			var ry = randi() % GRID_ROWS
			var rx = randi() % GRID_COLUMNS
			if grid[ry][rx] == CELL_EMPTY:
				var can_place = false
				for cy in range(3):
					var y = ry + cy - 1
					if y >= 0 and y < GRID_ROWS:
						for cx in range(3):
							var x = rx + cx - 1
							if x >= 0 and x < GRID_COLUMNS and not \
								(x == rx and y == ry):
								can_place = check_path_to_factory(x, y, \
									fex, fey)
				if can_place:
					grid[ry][rx] = CELL_ROCK
				break
	
	# Place traps
	# TODO: Intelligent trap placement
	
	# Refresh the map
	refresh_map()
	
func refresh_map():
	# Clear level
	for c in get_children():
		remove_child(c)
	
	# Add Entities to Level
	var factory_placed = false
	for y in range(GRID_ROWS):
		var row = grid[y]
		for x in range(GRID_COLUMNS):
			match (row[x]):
				CELL_BOT:
					add_entity(BrokenFriend, x, y)
				CELL_ROCK:
					add_entity(Rock, x, y)
				CELL_HOLE:
					add_entity(Hole, x, y)
				CELL_FACTORY:
					if not factory_placed:
						add_entity(Factory, x, y)
						factory_placed = true
	
	# Set level defaults to make it solvable based on difficulty
	# TODO: trap detection on path and total turn setting to make it solveable
	
	# Call setup_level on Level
	setup_level()

func add_entity(type, grid_x, grid_y):
	var e = type.instance()
	e.position = Vector2(grid_x * CELL_PIXELS, grid_y * CELL_PIXELS)
	add_child(e)

enum { DIR_NORTH = 0, DIR_EAST, DIR_SOUTH, DIR_WEST }
	
func check_path_to_factory(x, y, fx, fy):
	if grid[y][x] != CELL_EMPTY:
		return false
	# Copy the grid for maze solving
	var maze = grid.duplicate()
	for y in range(GRID_ROWS):
		maze[y] = maze[y].duplicate()
	# Use clockwise max solving to determine if we have a clear path to fx, fy
	var dir = -1
	var curx = x
	var cury = y
	var rotations = 0
	while true:
		# Rotate the direction
		dir += 1
		rotations += 1
		if dir > DIR_WEST:
			dir = DIR_NORTH
		# Follow the direction until the end
		var xmod = 0
		var ymod = 0
		match dir:
			DIR_NORTH:
				ymod = 1
			DIR_EAST:
				xmod = 1
			DIR_SOUTH:
				ymod = -1
			DIR_WEST:
				xmod = -1
		var nextx = curx
		var nexty = cury
		var can_move = true
		while can_move:
			nextx += xmod
			nexty += ymod
			if nextx == fx and nexty == fy:
				# We made it to the factory entrance
				return true
			if nextx < 0 or nexty < 0 or nextx >= GRID_COLUMNS or \
				nexty >= GRID_ROWS:
				# Can't move
				break # Loop
			match maze[nexty][nextx]:
				MAZE_CELL_DEAD, CELL_FACTORY, CELL_ROCK:
					# Obstacle
					can_move = false
				MAZE_CELL_MARKER:
					if rotations < 4:
						# Treat as blocking until we try all directions from 
						#  this cell
						can_move = false
					else:
						# Allow traversal but mark the current cell as dead
						maze[cury][curx] = MAZE_CELL_DEAD
						continue # Match default case
				_:
					# Set a path marker and continue
					maze[nexty][nextx] = MAZE_CELL_MARKER
					curx = nextx
					cury = nexty
					# Reset rotations because we moved successfully
					rotations = 0
		if rotations >= 8:
			# Could not find any new or previous traversable 
			break # Outer loop
		# Else can't move anymore so go back to top of loop to rotate
	return false
