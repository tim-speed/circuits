extends Node2D

var turns_remaining = 40
var current_level = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(current_level)

func load_level(level_num):
	# Make sure level is stopped while loading
	stop_level()
	# TODO: Load level into scene and set turns from level meta
	turns_remaining = 40
	# Update / Reset UI
	$ControlUI.turns = turns_remaining
	$ProgramTimer.wait_time = 1
	# Renable buttons
	$ControlUI.reset_buttons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func stop_level():
	$ProgramTimer.stop()
	$ControlUI.disable_buttons()

func _on_ProgramTimer_timeout():
	# Update turns and timer, time itself autmatically tifcks robots... maybe chaange?
	if turns_remaining > 0:
		turns_remaining -= 1
	$ControlUI.turns = turns_remaining
	if turns_remaining == 0:
		stop_level()

func _on_ControlUI_fastforward():
	$ProgramTimer.wait_time = 0.5

func _on_ControlUI_normalspeed():
	$ProgramTimer.wait_time = 1

func _on_ControlUI_paused():
	$ProgramTimer.stop()
	
func _on_ControlUI_playing():
	if turns_remaining > 1:
		$ProgramTimer.start()

func _on_ControlUI_restart():
	load_level(current_level)
