extends Node

var debug_enabled : bool = true
var GDNTheWorldViewer = preload("res://native/GDN_TheWorld_Viewer.gdns").new()

var num_vertices_per_chunk_side : int
var bitmap_resolution : int
var lod_max_depth : int
var num_lods : int

var _result : bool

#const QUAD_SIZE := 2								# coordinate spaziali
#const CHUNK_QUAD_COUNT := 50
#const CHUNK_SIZE = QUAD_SIZE * CHUNK_QUAD_COUNT		# coordinate spaziali

func _ready():
	#var _result = connect("tree_exiting", self, "exitFunct",[])
	assert(connect("tree_exiting", self, "exitFunct",[]) == 0)
	GDNTheWorldViewer.set_debug_enabled(Globals.debug_enabled)
	debug_print("Debug Enabled!")
	
	bitmap_resolution = GDNTheWorldViewer.globals().get_bitmap_resolution()
	debug_print("Bitmap resolution = " + str(bitmap_resolution) + " + 1")
	num_vertices_per_chunk_side = GDNTheWorldViewer.globals().get_num_vertices_per_chunk_side()
	debug_print("Num vertices per chunk side = " + str(num_vertices_per_chunk_side) + " + 1")
	lod_max_depth = GDNTheWorldViewer.globals().get_lod_max_depth()
	num_lods = GDNTheWorldViewer.globals().get_num_lods()
	debug_print("Lod max depth = " + str(lod_max_depth) + " - Num lods = " + str(num_lods))
	
	for lod in range(num_lods):
		var chunks := get_chunks_per_bitmap_side(lod)
		var grid_step : float = GDNTheWorldViewer.globals().get_grid_step_in_wu(lod)
		var verticesPerSide = chunks * num_vertices_per_chunk_side
		GDNTheWorldViewer.debug_print("lod (" + str(lod) + ") - Num chunks per bitmap side = " + str(chunks) + " - Grid step in WUs = " + str(grid_step) + " - Num vertices per side = " + str(verticesPerSide) + " + 1 - Size of the side in WUs = " + str(verticesPerSide * grid_step))

	var w = get_tree().get_root().find_node("World", true, false)
	#_result = GDNTheWorldViewer.init(w, 1195425.176295 + 100, 5465512.560295 +100, 0)
	_result = GDNTheWorldViewer.init(w, 1195425.176295, 5465512.560295, 0)
	
func GDN():
	return GDNTheWorldViewer

func debug_print(var text : String):
	GDNTheWorldViewer.debug_print(text)

func get_chunks_per_bitmap_side(var lod : int) -> int:
	return GDNTheWorldViewer.globals().get_chunks_per_bitmap_side(lod)

func get_grid_step_in_wu(var lod : int) -> float:
	return GDNTheWorldViewer.globals().get_grid_step_in_wu(lod)

func exitFunct():
	GDNTheWorldViewer.debug_print(self.name + ": exitFunct!")
	GDNTheWorldViewer.destroy()
	GDNTheWorldViewer.free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
