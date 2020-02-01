extends Control

var parse_error

var seperatorRegex = RegEx.new()
var intRegex = RegEx.new()
var directionRegex = RegEx.new()

func _ready():
	print_debug("011".to_int())
	print_debug("abc^&".to_int())
	seperatorRegex.compile("(?<match>[0-9a-zA-Z]+)\\s*")
	intRegex.compile("^[0-9]+$")
	directionRegex.compile("^(Up)|(Down)|(Left)|(Right)$")
	parse("""
		If HasBrokenFriend
			Move Up
		Else
			Move Down
		EndIf
	""")

func parse(text):
	parse_error = null
	var parts = []
	for result in seperatorRegex.search_all(text):
		parts.push_back(result.get_string("match"))
	
	var program = []
	
	while parts.size():
		var node = parse_node(parts)
		print_debug(node)
		if !node:
			return
		program.push_back(node)

func parse_node(parts):
	var part = parts.pop_front() 
	print_debug(part)
	var node
	match part:
		"If":
			node = parse_if(parts)
		"Else":
			node = { type = "Else" }
		"EndIf":
			node = { type = "EndIf" }
		"While":
			node = parse_while(parts)
		"EndWhile":
			node = { type = "EndWhile" }
		"Move":
			node = parse_move(parts)
		_:
			send_parse_error(part + "is not a valid keyword")
		
	if !node:
		if !parse_error:
			send_parse_error("Unknown parse error at " + part)
		return
	return node
	
func parse_if(parts):
	var node = {
		type = "If",
	}
	
	var condition = parse_condition(parts)
	
	if !condition:
		return
	
	node.condition = condition
	
	var is_inside = true
	var is_in_else = false
	
	var children = []
	var else_children = []
	
	while is_inside:
		var child_node = parse_node(parts)
		if !child_node:
			return
		
		match child_node.type:
			"Else":
				is_in_else = true
			"EndIf":
				is_inside = false
			"EndWhile":
				send_parse_error("EndWhile must follow While")
				return
			_:
				if is_in_else:
					else_children.push_back(child_node)
				else:
					children.push_back(child_node)
					
	node.children = children
	if else_children.size():
		node.else_children = else_children
	
	return node

func parse_while(parts):
	var node = {
		type = "While",
	}
	
	var condition = parse_condition(parts)
	
	if !condition:
		return
	
	node.condition = condition
	
	var is_inside = true
	
	var children = []
	
	while is_inside:
		var child_node = parse_node(parts)
		if !child_node:
			return
		
		match child_node.type:
			"Else":
				send_parse_error("Else must follow If")
				return
			"EndIf":
				send_parse_error("EndIf must follow If")
				return
			"EndWhile":
				is_inside = false
			_:
				children.push_back(child_node)
					
	node.children = children
	
	return node
	
func parse_condition(parts):
	var condition_type = parts.pop_front()
	
	match condition_type:
		"HasBrokenFriend":
			return {
				type = "HasBrokenFriend"
			}
		"IsAtCoordinates":
			return parse_condition_iac(parts)
		_:
			send_parse_error(condition_type + "is not a valid condition")
			return

func parse_condition_iac(parts):
	var x_string = parts.pop_front()
	if !intRegex.search(x_string):
		send_parse_error("IsAtCoordinates must be followed by an x and y intiger")
		return
	var y_string = parts.pop_front()
	if !intRegex.search(y_string):
		send_parse_error("IsAtCoordinates must be followed by an x and y intiger")
		return
	var vec = Vector2(x_string.to_int(), y_string.to_int())
	return {
		type = "IsAtCoordinates",
		options = {
			coordinates = vec
		}
	}
	
func parse_move(parts):
	var direction = parts.pop_front()
	if !directionRegex.search(direction):
		send_parse_error("Move must be followed by Up, Down, Left, or Right")
		return
	return {
		type = "Move",
		options = {
			direction = direction
		}
	}

func send_parse_error(error_msg):
	parse_error = error_msg
	
	
	
