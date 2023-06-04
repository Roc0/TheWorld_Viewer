@tool
extends Button

var _info_panel_visibility_changed : bool = false

@export var _info_panel_visible : bool: set = _set_info_panel_visible
func _set_info_panel_visible(info_panel_visible : bool):
	_info_panel_visible = info_panel_visible
	_info_panel_visibility_changed = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _enter_tree():
	pressed.connect(clicked)

func clicked():
	print("You clicked me!")
	
