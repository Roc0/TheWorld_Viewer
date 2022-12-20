extends Node

const status_error = -1
const status_uninitialized = 0
const status_initialized = 1
const status_connected_to_server = 2
const status_session_initialized = 3

var debug_enabled : bool = true
var debug_enable_set : bool = false
var GDNTheWorldMain = preload("res://native/GDN_TheWorld_Viewer.gdns").new()
var GDNTheWorldGlobals : Node = null
var GDNTheWorldViewer : Node = null

var num_vertices_per_chunk_side : int
var bitmap_resolution : int
var lod_max_depth : int
var num_lods : int
var _result : bool
var world_initialized : bool = false
var main_node : Node
var world_main_node : Spatial

func _ready():
	assert(connect("tree_exiting", self, "exit_funct",[]) == 0)
	OS.set_window_maximized(true)
	
	main_node = get_tree().get_root().find_node("Main", true, false)
	world_main_node = get_tree().get_root().find_node("TheWorld_Main", true, false)
	GDN_main().init(main_node, world_main_node)
	GDN_globals().connect_to_server()

	#GDN_globals().set_debug_enabled(Globals.debug_enabled)
	#debug_print("Debug Enabled!")

	printTerrainDimensions()
	
func _notification(_what):
	if (_what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var status : int = Globals.get_status()
	if status == Globals.status_session_initialized && !debug_enable_set:
		debug_enable_set = true
		GDN_globals().set_debug_enabled(debug_enabled)
		
	if status != Globals.status_session_initialized:
		pass

	if not world_initialized:
		initialize_world()
		world_initialized = true

func initialize_world() -> void:
	world_main_node.enter_world()
	
func unitialize_world() -> void:
	world_main_node.exit_world()

func GDN_main():
	return GDNTheWorldMain

func GDN_globals():
	if GDNTheWorldGlobals == null:
		GDNTheWorldGlobals = GDN_main().globals(true)
	return GDNTheWorldGlobals

func GDN_viewer():
	if GDNTheWorldViewer == null:
		GDNTheWorldViewer = GDN_globals().viewer(true)
	return GDNTheWorldViewer

func get_status() -> int:
	return GDN_globals().get_status()

func debug_print(var text : String):
	GDN_globals().debug_print(text)

func get_chunks_per_bitmap_side(var lod : int) -> int:
	return GDN_globals().get_chunks_per_bitmap_side(lod)

func get_grid_step_in_wu(var lod : int) -> float:
	return GDN_globals().get_grid_step_in_wu(lod)

func exit_funct():
	debug_print ("Quitting...")
	#unitialize_world()
	GDN_globals().disconnect_from_server()
	GDN_main().deinit()
	
func printTerrainDimensions() -> void:
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
		
