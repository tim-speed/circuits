extends Control

const max_programs = 6
const plist_spacing = 52

var programs = {}

signal robot_requested

var ProgramUI = preload("res://scenes/ProgramUI.tscn")

var editing_program

func _ready():
	$Editor.connect("cancel", self, "close_editor")
	$Editor.connect("save", self, "save_program")
	
	for i in range(max_programs):
		var p = ProgramUI.instance()

		var program_num = i + 1
		var deploy_btn = p.get_node("DeployButton")
		deploy_btn.text = "Program " + String(program_num)
		
		$ProgramList.add_child(p)
		p.rect_position.y += i * plist_spacing
		deploy_btn.connect("pressed", self, "deploy_bot", [program_num])
		deploy_btn.set_disabled(true)
		p.get_node("EditButton").connect("pressed", self, "edit_program", [program_num])
		

func edit_program(program_num):
	editing_program = program_num
	print_debug("Editing Program ", program_num)
	$Editor/Label.text = "Program " + String(program_num)
	
	if programs.has(program_num):
		$Editor/ProgramEditor.text = programs[program_num].text
	else:
		$Editor/ProgramEditor.text = ""
		
	$Editor/ProgramEditor.grab_focus()
	$Editor.visible = true
	
func save_program(compiled, text):
	programs[editing_program] = {
		compiled = compiled,
		text = text
	}
	var p = $ProgramList.get_child(editing_program - 1)
	p.get_node("DeployButton").set_disabled(false)
	close_editor()

func close_editor():
	editing_program = null
	$Editor.visible = false
	
func deploy_bot(program_num):
	print_debug("Requesting Robot With Program ", program_num)
	if programs.has(program_num):
		emit_signal("robot_requested", programs[program_num].compiled)
	
