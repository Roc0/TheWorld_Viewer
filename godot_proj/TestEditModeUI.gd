extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	resize()
	pass # Replace with function body.
	
func resize():
	var size := get_viewport().size
	anchor_right = 1
	margin_left = size.x - 150

func _notification(_what):
	if (_what == NOTIFICATION_RESIZED):
		resize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
