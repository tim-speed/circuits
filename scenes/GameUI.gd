extends Control

signal playing
signal paused
signal fastforward
signal normalspeed
signal restart

var playing = false
var fast_forwarding = false
export var turns = 30

func reset_buttons():
	$Play.disabled = false
	$Play/PlayPoly.visible = true
	$Play/PausePoly.visible = false
	playing = false
	$FastForward.disabled = false
	$FastForward/FFPoly.visible = true
	$FastForward/NormalPoly.visible = false
	fast_forwarding = false
	
func disable_buttons():
	$Play.disabled = true
	$FastForward.disabled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Turns/Count.text = String(turns)
	
func pause():
	$Play/PlayPoly.visible = true
	$Play/PausePoly.visible = false
	playing = false
	print("Paused")
	emit_signal("paused")

func _on_Play_pressed():
	if playing:
		pause()
	else:
		$Play/PlayPoly.visible = false
		$Play/PausePoly.visible = true
		playing = true
		print("Playing")
		emit_signal("playing")

func _on_Restart_pressed():
	print("Restart")
	emit_signal("restart")

func _on_FastForward_pressed():
	if fast_forwarding:
		$FastForward/FFPoly.visible = true
		$FastForward/NormalPoly.visible = false
		fast_forwarding = false
		print("NormalSpeed")
		emit_signal("normalspeed")
	else:
		$FastForward/FFPoly.visible = false
		$FastForward/NormalPoly.visible = true
		fast_forwarding = true
		print("FastForward")
		emit_signal("fastforward")
