extends Control

var default_raw_program = [
	{
		type = "If",
		condition = {
			type = "IsAtCoordinates",
			options = {
				coordinates = Vector2(8, 4)
			}
		},
		children = [
			{
				type = "Move",
				options = {
					direction_name = "Right"
				}
			}
		],
		else_children = [
			{
				type = "Move",
				options = {
					direction_name = "Left"
				}
			}
		]
	},
]

var program_tree
var program_tree_root

func _ready():
	program_tree = $ProgramTree
	program_tree_root = program_tree.create_item()
	program_tree.set_hide_root(true)
	draw_program(default_raw_program, program_tree_root)

func draw_program(program_part, tree_item):
	for node in program_part:
		var tree_node = program_tree.create_item(tree_item)
		var text
		match node.type:
			"Move":
				text = "Move " + node.options.direction_name
			"If":
				text = "If " + node.condition.type
				if node.has("else_children"):
					var else_tree_node = program_tree.create_item(tree_item)
					else_tree_node.set_text(0, "Else")
					else_tree_node.set_metadata(0, node)
					draw_program(node.else_children, else_tree_node)
			"While":
				text = "While " + node.condition.type
				
		tree_node.set_text(0, text)
		tree_node.set_metadata(0, node)
		if node.has("children"):
			draw_program(node.children, tree_node)
	
