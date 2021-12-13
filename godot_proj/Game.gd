extends Node2D

var game_end = false

func _process(_delta):
	if game_end == false:
		var spots = $Spots.get_child_count()
		for i in $Spots.get_children():
			if i.occupied:
				spots -= 1
		if spots == 0:
			$AcceptDialog.popup()
			game_end = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AcceptDialog_confirmed():
	get_tree().reload_current_scene()
