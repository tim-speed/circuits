extends Panel

const max_programs = 6
const plist_spacing = 52

# Called when the node enters the scene tree for the first time.
func _ready():
	var ProgramUI = load("res://scenes/ProgramUI.tscn")
	for i in range(max_programs):
		var p = ProgramUI.instance()
		p.program_number = i
		p.rect_position.y = i * plist_spacing
		$ProgramList.add_child(p)
		p.connect("deploy", self, "deploy_bot")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func deploy_bot(program):
	print("Deploying With Program ", program)
