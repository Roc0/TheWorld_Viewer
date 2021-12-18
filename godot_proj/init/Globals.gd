extends Node

var debug_enabled : bool = true
var GDNTheWorldViewer = preload("res://native/GDN_TheWorld_Viewer.gdns").new()

#const QUAD_SIZE := 2								# coordinate spaziali
#const CHUNK_QUAD_COUNT := 50
#const CHUNK_SIZE = QUAD_SIZE * CHUNK_QUAD_COUNT		# coordinate spaziali

func _ready():
	var _result = connect("tree_exiting", self, "exitFunct",[])
	GDNTheWorldViewer.set_debug_enabled(Globals.debug_enabled)
	GDNTheWorldViewer.debug_print("Debug Enabled!")
	GDNTheWorldViewer.debug_print( "Chunk size = " + str(GDNTheWorldViewer.globals().chunk_size()))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func exitFunct():
	GDNTheWorldViewer.debug_print(self.name + ": exitFunct!")
	GDNTheWorldViewer.destroy()
	GDNTheWorldViewer.free()
