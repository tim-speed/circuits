extends Node2D

export var current_level = 0

var turns_remaining = 0
var level

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(current_level)
	
func _input(event):
	if event.is_action_released("ui_accept"):
		one_turn_if_paused()

func load_level(level_num):
	var file = File.new()
	var file_path = "res://levels/Level"+String(level_num)+".tscn"
	if !file.file_exists(file_path):
		return
	
	current_level = level_num
	
	#Disconnect old level signals if it existed
	if level:
		$ProgrammerUI.disconnect("robot_requested", level, "request_deploy_robot")
		level.disconnect("robot_num_change", self, "set_bots_remaining")
		level.disconnect("request_pause", self, "pause")
		level.disconnect("request_turn", self, "one_turn_if_paused")

	# Make sure level is stopped while loading
	stop_level()
	var level_res = load(file_path)
	level = level_res.instance()
	turns_remaining = level.turns
	for c in $LevelContainer.get_children():
		$LevelContainer.remove_child(c)
	$LevelContainer.add_child(level)
	# Update / Reset UI
	$GameUI.turns = turns_remaining
	$ProgramTimer.wait_time = 1
	# Renable buttons
	$GameUI.reset_buttons()
	set_bots_remaining(level.num_robots, level.robots_in_need)
	
	level.connect("robot_num_change", self, "set_bots_remaining")
	level.connect("request_pause", self, "pause")
	level.connect("request_turn", self, "one_turn_if_paused")
	$ProgrammerUI.connect("robot_requested", level, "request_deploy_robot")

func one_turn_if_paused():
	if $ProgramTimer.is_stopped() and turns_remaining > 0:
		turns_remaining -= 1
		$GameUI.turns = turns_remaining
		get_tree().call_group("Robots", "run_turn")

func set_bots_remaining(num, damaged):
	if damaged == 0:
		$GameUI/NextLevel.disabled = false
		$GameUI/NextLevel.visible = true
	else:
		$GameUI/NextLevel.disabled = true
		$GameUI/NextLevel.visible = false
	$GameUI/DamagedBots/Count.text = String(damaged)
	$ProgrammerUI/BotCount.text = String(num)
	
func pause():
	$GameUI.pause()
	
func stop_level():
	$ProgramTimer.stop()
	$GameUI.disable_buttons()

func _on_ProgramTimer_timeout():
	# Update turns and timer, time itself autmatically tifcks robots... maybe chaange?
	if turns_remaining > 0:
		turns_remaining -= 1
	$GameUI.turns = turns_remaining
	if turns_remaining == 0:
		stop_level()

func _on_GameUI_fastforward():
	$ProgramTimer.wait_time = 0.5

func _on_GameUI_normalspeed():
	$ProgramTimer.wait_time = 1

func _on_GameUI_paused():
	$ProgramTimer.stop()
	
func _on_GameUI_playing():
	if turns_remaining > 1:
		$ProgramTimer.start()

func _on_GameUI_restart():
	load_level(current_level)

func _on_GameUI_next_level():
	load_level(current_level + 1)
