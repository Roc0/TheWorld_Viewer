tool

extends Spatial

var GDNTheWorldMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer_d.gdns")
#var GDNTheWorldMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer.gdns").new()
var GDNTheWorldMain_instance : Node = null

var tw_constants = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("./util/logger.gd")

var GDNTheWorldGlobals : Node = null
var GDNTheWorldViewer : Spatial = null
var _logger = HT_Logger.get_for(self)
var _init_done : bool = false

export var _status : String = ""

func init() -> bool:
	log_debug("init")
	if _init_done:
		return false
	else:
		GDN_main().init(self)
		set_debug_enabled(_logger.is_verbose())
		GDN_globals().connect_to_server()
		log_debug(str("server connected"))
		var result = GDN_globals().connect("tw_status_changed", self, "_on_tw_status_changed") == 0
		log_debug(str("signal tw_status_changed connected (result=", result, ")"))
		printTerrainDimensions()
		_init_done = true
		return true

func pre_deinit():
	log_debug("pre_deinit")
	GDN_main().pre_deinit()
	
func can_deinit() -> bool:
	log_debug("can_deinit")
	return GDN_main().can_deinit()

func deinit():
	log_debug("deinit")
	if _init_done:
		GDN_globals().disconnect("tw_status_changed", self, "_on_tw_status_changed")
		GDN_globals().disconnect_from_server()
		GDN_main().deinit()
		_init_done = false

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	_status = tw_constants.status_to_string(new_client_status)
	var old_client_status_str : String = tw_constants.status_to_string(old_client_status)
	var new_client_status_str : String = tw_constants.status_to_string(new_client_status)
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))

func _init():
	log_debug("_init")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	log_debug("_ready")
	var GDNMain = GDN_main()
	if Engine.editor_hint:
		#delete_children()
		init()
	else:
		#delete_children()
		init()
		
func _enter_tree():
	log_debug("_enter_tree")
	
func _exit_tree():
	log_debug("_exit_tree")
	
	if _init_done:
		deinit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#log_debug("_process")
	
	#if Engine.editor_hint:
	#	var clientstatus : int = get_clientstatus()
	#	_status = tw_constants.status_to_string(clientstatus)
	pass
	
func GDN_main():
	#if GDNTheWorldMain == null:
	#	GDNTheWorldMain = GDNTheWorldMain.new()
	#return GDNTheWorldMain
	if GDNTheWorldMain_instance == null:
		if Engine.editor_hint:
			var scene : SceneTree = get_tree()
			if scene == null:
				return null
			GDNTheWorldMain_instance = get_tree().get_edited_scene_root().find_node("GDN_TheWorld_Main", true, false)
		else:
			var scene : SceneTree = get_tree()
			if scene == null:
				return null
			var node : Node = scene.get_root()
			GDNTheWorldMain_instance = get_tree().get_root().find_node("GDN_TheWorld_Main", true, false)
		#GDNTheWorldMain_instance = GDNTheWorldMain.new()
	return GDNTheWorldMain_instance

func GDN_globals():
	if GDNTheWorldGlobals == null:
		var main = GDN_main()
		if main == null:
			return null
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

func get_clientstatus() -> int:
	if _init_done:
		var status : int = GDN_globals().get_status()
		#log_debug(str("status=",status))
		return status
	else:
		return tw_constants.clientstatus_uninitialized

func printTerrainDimensions() -> void:
	var num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	var bitmap_resolution = GDN_globals().get_bitmap_resolution()
	log_debug("Bitmap resolution = " + str(bitmap_resolution) + " + 1")
	num_vertices_per_chunk_side = GDN_globals().get_num_vertices_per_chunk_side()
	log_debug("Num vertices per chunk side = " + str(num_vertices_per_chunk_side) + " + 1")
	var lod_max_depth = GDN_globals().get_lod_max_depth()
	var num_lods = GDN_globals().get_num_lods()
	log_debug("Lod max depth = " + str(lod_max_depth) + " - Num lods = " + str(num_lods))
	for lod in range(num_lods):
		var chunks := get_chunks_per_bitmap_side(lod)
		var grid_step : float = GDN_globals().get_grid_step_in_wu(lod)
		var verticesPerSide = chunks * num_vertices_per_chunk_side
		var s = str("lod (",lod,") - Num chunks per bitmap side = ",chunks," - Grid step in WUs = ",grid_step," - Num vertices per side = ",verticesPerSide," + 1 - Size of the side in WUs = ",verticesPerSide * grid_step)
		log_debug(s)

func get_chunks_per_bitmap_side(var lod : int) -> int:
	return GDN_globals().get_chunks_per_bitmap_side(lod)

func delete_children():
	for n in get_children():
		n.owner = null
		remove_child(n)
		n.queue_free()

func set_editor_interface(editor_interface : EditorInterface):
	GDN_viewer().set_editor_interface(editor_interface)

func log_debug(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)
	
func debug_print(var context: String, var text : String, var godot_print : bool):
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		gdn_globals.debug_print(str(context,": ", text), godot_print)

func log_info(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)
	
func info_print(var context: String, var text : String, var godot_print : bool):
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		gdn_globals.info_print(str(context,": ", text), godot_print)

func log_error(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)
	
func error_print(var context: String, var text : String, var godot_print : bool):
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		gdn_globals.error_print(str(context,": ", text), godot_print)
