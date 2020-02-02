extends Control

var compiled_program
var parse_error

var seperatorRegex = RegEx.new()
var intRegex = RegEx.new()
var directionRegex = RegEx.new()

signal cancel
signal save

func _ready():
	seperatorRegex.compile("(?<match>[0-9a-zA-Z]+)\\s*")
	intRegex.compile("^[0-9]+$")
	directionRegex.compile("^(Up)|(Down)|(Left)|(Right)$")
	
	$SaveButton.connect("pressed", self, "save")
	$CancelButton.connect("pressed", self, "cancel")

func cancel():
	emit_signal("cancel")

func save():
	var text = $ProgramEditor.text
	var parser_output = parse(text)
	if parser_output:
		compiled_program = compile(parser_output)
		print_debug(compiled_program)
		emit_signal("save", compiled_program, text)

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
						type = "GoTo"
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
				var goto = {
					type = "GoTo",
					position = inner_index - 1
				}
				
				var compiled_children = compile(node.children, inner_index)
				
				inner_index += compiled_children.size() + 1
				
				compiled_output.push_back(gate)
				
				for c in compiled_children:
					compiled_output.push_back(c)
					
				compiled_output.push_back(goto)
				
				gate.else_position = inner_index
					
			"Move":
				compiled_output.push_back({
					type = "Task",
					task = "Move",
					options = node.options
				})
			"SetVar":
				compiled_output.push_back({
					type = "SetVar",
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
		"SetVar":
			node = parse_set_var(parts)
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
		"IsVarEqual":
			return parse_condition_ive(parts)
		"IsAtCoordinates":
			return parse_condition_iac(parts)
		"CanMoveInDirection":
			return parse_condition_cmid(parts)
		"IsAboveY":
			return parse_condition_ixo(parts, "North")
		"IsBelowY":
			return parse_condition_ixo(parts, "South")
		"IsRightOfX":
			return parse_condition_ixo(parts, "East")
		"IsLeftOfX":
			return parse_condition_ixo(parts, "West")
		_:
			send_parse_error(condition_type + "is not a valid condition")
			return

func parse_condition_ive(parts):
	var name = parts.pop_front()
	var value_string = parts.pop_front()
	
	return {
		type = "IsVarEqual",
		options = {
			name = name,
			value = value_string
		}
	}

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

func parse_condition_ixo(parts, compass_direction):
	var v_string = parts.pop_front()
	if !intRegex.search(v_string):
		send_parse_error("Is" + compass_direction + "Of" + " must be followed by an intiger")
		return

	return {
		type = "IsCompassOf",
		options = {
			compass_direction = compass_direction,
			v = v_string.to_int()
		}
	}

func parse_condition_cmid(parts):
	var direction = parts.pop_front()
	if !directionRegex.search(direction):
		send_parse_error("Move must be followed by Up, Down, Left, or Right")
		return
		
	return {
		type = "CanMoveInDirection",
		options = {
			direction_name = direction
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
			direction_name = direction
		}
	}

func parse_set_var(parts):
	var name = parts.pop_front()
	var value = parts.pop_front()
	
	return {
		type = "SetVar",
		options = {
			name = name,
			value = value
		}
	}

func send_parse_error(error_msg):
	parse_error = error_msg
	
	
	
