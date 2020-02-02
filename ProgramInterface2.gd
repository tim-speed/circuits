extends Control

var compiled_program
var parse_error

var seperatorRegex = RegEx.new()
var intRegex = RegEx.new()
var directionRegex = RegEx.new()

func _ready():
	seperatorRegex.compile("(?<match>[0-9a-zA-Z]+)\\s*")
	intRegex.compile("^[0-9]+$")
	directionRegex.compile("^(Up)|(Down)|(Left)|(Right)$")
	
	$SaveButton.connect("pressed", self, "save")
	
func save():
	var text = $ProgramEditor.text
	var parser_output = parse(text)
	if parser_output:
		compiled_program = compile(parser_output)
		print_debug(compiled_program)

func compile(parser_output, index = 0):
	var compiled_output = []
	
	var inner_index = index
	while true:
		inner_index += 1
		
		var node = parser_output.pop_front()
		
		if !node:
			break
		
		match node.type:
			"If":
				var gate = {
					type = "Gate",
					condition = node.condition
				}
				var compiled_children = compile(node.children, inner_index)
				
				inner_index += compiled_children.size()
				
				compiled_output.push_back(gate)
				
				for c in compiled_children:
					compiled_output.push_back(c)
				
				if node.else_children.size():
					inner_index += 1
					
					gate.else_position = inner_index
					
					var goto = {
						type = "Goto"
					}
					compiled_output.push_back(goto)
					
					var compiled_else_children = compile(node.else_children, inner_index)
					
					inner_index += compiled_else_children.size()
					
					for c in compiled_else_children:
						compiled_output.push_back(c)
					
					goto.position = inner_index
				else:
					gate.else_position = inner_index
					
			"While":
				var gate = {
					type = "Gate",
					condition = node.condition
				}
				var compiled_children = compile(node.children, inner_index)
				
				inner_index += compiled_children.size()
				
				compiled_output.push_back(gate)
				
				for c in compiled_children:
					compiled_output.push_back(c)
				
				gate.else_position = inner_index
					
			"Move":
				compiled_output.push_back({
					type = "Task",
					task = "Move",
					options = node.options
				})
			_:
				break
		
				
	return compiled_output

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
		
	return program

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
	
	
	
