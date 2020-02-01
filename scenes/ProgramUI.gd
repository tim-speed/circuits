extends Panel


export var program_number = 0

signal deploy

# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.text = "Program " + String(program_number)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	emit_signal("deploy", program_number)
