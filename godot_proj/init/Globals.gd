extends Node

var debug_enabled : bool = true
var GDNTheWorldMain = preload("res://native/GDN_TheWorld_Viewer.gdns").new()

var num_vertices_per_chunk_side : int
var bitmap_resolution : int
var lod_max_depth : int
var num_lods : int

var _result : bool


func _ready():
	assert(connect("tree_exiting", self, "exitFunct",[]) == 0)
	
	var m = get_tree().get_root().find_node("Main", true, false)
	var w = get_tree().get_root().find_node("TheWorld_Main", true, false)
	GDN_main().init(m, w)

	GDN_globals().set_debug_enabled(Globals.debug_enabled)
	debug_print("Debug Enabled!")

	num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	
	bitmap_resolution = GDN_globals().get_bitmap_resolution()
	debug_print("Bitmap resolution = " + str(bitmap_resolution) + " + 1")
	num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	debug_print("Num vertices per chunk side = " + str(num_vertices_per_chunk_side) + " + 1")
	lod_max_depth = GDN_globals().get_lod_max_depth()
	num_lods = GDN_globals().get_num_lods()
	debug_print("Lod max depth = " + str(lod_max_depth) + " - Num lods = " + str(num_lods))
	
	for lod in range(num_lods):
		var chunks := get_chunks_per_bitmap_side(lod)
		var grid_step : float = GDN_globals().get_grid_step_in_wu(lod)
		var verticesPerSide = chunks * num_vertices_per_chunk_side
		debug_print("lod (" + str(lod) + ") - Num chunks per bitmap side = " + str(chunks) + " - Grid step in WUs = " + str(grid_step) + " - Num vertices per side = " + str(verticesPerSide) + " + 1 - Size of the side in WUs = " + str(verticesPerSide * grid_step))

	GDN_viewer().set_initial_world_viewer_pos(1195425.176295 + 100, 5465512.560295 +100, 0)

func GDN_main():
	return GDNTheWorldMain

func GDN_globals():
	return GDN_main().globals(true)

func GDN_viewer():
	return GDN_globals().viewer(true)

func debug_print(var text : String):
	GDN_globals().debug_print(text)

func get_chunks_per_bitmap_side(var lod : int) -> int:
	return GDN_globals().get_chunks_per_bitmap_side(lod)

func get_grid_step_in_wu(var lod : int) -> float:
	return GDN_globals().get_grid_step_in_wu(lod)

func exitFunct():
	GDN_main().deinit()


func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		quit_app()

func quit_app() -> void:
	debug_print ("Quitting ...")
	get_tree().quit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
