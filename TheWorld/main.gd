extends Node3D

var world_main_control : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_main_control = get_tree().get_root().find_child("TheWorld_Main_Control", true, false)
	if world_main_control.visible != visible:
		world_main_control.visible = visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _notification(what: int):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		world_main_control.visible = visible
		print("Visibility changed ", visible)
