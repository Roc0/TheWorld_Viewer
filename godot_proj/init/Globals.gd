extends Node

var debug_enabled : bool = true

#var player

const QUAD_SIZE := 2								# coordinate spaziali
const CHUNK_QUAD_COUNT := 50
const CHUNK_SIZE = QUAD_SIZE * CHUNK_QUAD_COUNT		# coordinate spaziali

func _ready():
	pass
	#player = get_tree().get_root().find_node("Player", true, false)
