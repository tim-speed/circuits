extends Node2D

export var current_level = 0

var turns_remaining = 0
var level

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(current_level)

func load_level(level_num):
	#Disconnect old level signals if it existed
	if level:
		$ProgrammerUI.disconnect("robot_requested", level, "request_deploy_robot")
		level.disconnect("robot_deployed", self, "set_bots_remaining")

	# Make sure level is stopped while loading
	stop_level()
	var level_res = load("res://levels/Level"+String(level_num)+".tscn")
	level = level_res.instance()
	turns_remaining = level.turns
	for c in $LevelContainer.get_children():
		$LevelContainer.remove_child(c)
	$LevelContainer.add_child(level)
	# Update / Reset UI
	$ControlUI.turns = turns_remaining
	$ProgramTimer.wait_time = 1
	# Renable buttons
	$ControlUI.reset_buttons()
	set_bots_remaining(level.num_robots)
	
	level.connect("robot_deployed", self, "set_bots_remaining")
	$ProgrammerUI.connect("robot_requested", level, "request_deploy_robot")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_bots_remaining(num):
	$ProgrammerUI/BotCount.text = String(num)
	
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
