extends Timer

func _ready():
	connect("timeout", self, "_run_progam_turn")

func _run_progam_turn():
	get_tree().call_group("Robots", "run_turn")
	pass
