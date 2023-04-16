tool

extends Spatial

var GDNTheWorldMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer_d.gdns").new()
#var GDNTheWorldMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer.gdns").new()

const HT_Logger = preload("./util/logger.gd")

var GDNTheWorldGlobals : Node = null
var GDNTheWorldViewer : Spatial = null
var _logger = HT_Logger.get_for(self)
var init_done : bool = false


func init() -> bool:
	if init_done:
		return false
	else:
		GDN_main().init(self)
		GDN_globals().connect_to_server()
		printTerrainDimensions()
		init_done = true
		return true

func pre_deinit():
	GDN_main().pre_deinit()
	
func can_deinit() -> bool:
	return GDN_main().can_deinit()

func deinit():
	GDN_globals().disconnect_from_server()
	GDN_main().deinit()
	init_done = false

func _init():
	_logger.debug("TWViewer: _init")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_logger.debug("TWViewer: _ready")
	if GDNTheWorldMain == null:
		GDNTheWorldMain = GDNTheWorldMain.new()

func _enter_tree():
	_logger.debug("TWViewer: _enter_tree")
	
func _exit_tree():
	_logger.debug("TWViewer: _exit_tree")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func GDN_main():
	if GDNTheWorldMain == null:
		GDNTheWorldMain = GDNTheWorldMain.new()
	return GDNTheWorldMain

func GDN_globals():
	if GDNTheWorldGlobals == null:
		GDNTheWorldGlobals = GDN_main().globals(true)
	return GDNTheWorldGlobals

func GDN_viewer():
	if GDNTheWorldViewer == null:
		GDNTheWorldViewer = GDN_globals().viewer(true)
	return GDNTheWorldViewer

func get_self() -> Spatial:
	return self

func set_debug_enabled(debug_mode : bool):
	GDN_globals().set_debug_enabled(debug_mode)

func debug_print(var text : String):
	GDN_globals().debug_print(text)

func get_clientstatus() -> int:
	return GDN_globals().get_status()

func printTerrainDimensions() -> void:
	var num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	var bitmap_resolution = GDN_globals().get_bitmap_resolution()
	debug_print("Bitmap resolution = " + str(bitmap_resolution) + " + 1")
	num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	debug_print("Num vertices per chunk side = " + str(num_vertices_per_chunk_side) + " + 1")
	var lod_max_depth = GDN_globals().get_lod_max_depth()
	var num_lods = GDN_globals().get_num_lods()
	debug_print("Lod max depth = " + str(lod_max_depth) + " - Num lods = " + str(num_lods))
	for lod in range(num_lods):
		var chunks := get_chunks_per_bitmap_side(lod)
		var grid_step : float = GDN_globals().get_grid_step_in_wu(lod)
		var verticesPerSide = chunks * num_vertices_per_chunk_side
		debug_print("lod (" + str(lod) + ") - Num chunks per bitmap side = " + str(chunks) + " - Grid step in WUs = " + str(grid_step) + " - Num vertices per side = " + str(verticesPerSide) + " + 1 - Size of the side in WUs = " + str(verticesPerSide * grid_step))

func get_chunks_per_bitmap_side(var lod : int) -> int:
	return GDN_globals().get_chunks_per_bitmap_side(lod)
