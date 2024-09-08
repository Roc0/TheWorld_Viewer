@tool
extends PanelContainer

var moused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var callable_mouse_entered = Callable(self, "mouse_entered")
	var callable_mouse_exited = Callable(self, "mouse_exited")
	connect('mouse_entered', callable_mouse_entered)
	connect('mouse_exited', callable_mouse_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _input(event):        # not _gui_event()
#	if moused and event is InputEventMouse:
#		accept_event()
		
func mouse_entered():
	moused=true

func mouse_exited():
	moused=false
