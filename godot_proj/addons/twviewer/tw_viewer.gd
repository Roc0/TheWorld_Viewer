tool

extends Spatial

var TWViewerGDNMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer_d.gdns")
#var TWViewerGDNMain = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer.gdns")
var TWViewerGDNMain_instance : Node = null

var tw_constants = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("./util/logger.gd")

var GDNTheWorldGlobals : Node = null
var GDNTheWorldViewer : Spatial = null
var _logger = HT_Logger.get_for(self)
var _init_done : bool = false
var _is_ready : bool = false
var _transform_changed : bool = false
var _visibility_changed : bool = false

var _status : String = ""

enum debug_mode {DEFAULT = 0, ENABLED=1, DISABLED=2}
export(debug_mode) var _debug_mode : int = 0 setget _set_debug_mode
func _set_debug_mode(p_debug_mode : int):
	_debug_mode = p_debug_mode
	log_debug(str("debug mode: ", _debug_mode))
	set_debug_mode(_debug_mode)

const MAX_DEPTH_QUAD=3
export var _depth_quad := 3 setget _set_depth_quad, _get_depth_quad
func _set_depth_quad(depth_quad : int):
	if depth_quad >= 0 && depth_quad <= MAX_DEPTH_QUAD:
		_depth_quad = depth_quad
	var viewer = GDN_viewer()
	if viewer == null:
		print("GDN_viewer() null")
	else:
		viewer.set_depth_quad(_depth_quad)
		log_debug(str("depth quad: ", _depth_quad))
func _get_depth_quad() -> int:
	#var viewer = GDN_viewer()
	#if viewer == null:
	#	print("GDN_viewer() null")
	#else:
	#	_depth_quad = viewer.get_depth_quad()
	return _depth_quad

const MAX_CACHE_QUAD=2
export var _cache_quad : int = 1 setget _set_cache_quad, _get_cache_quad
func _set_cache_quad(cache_quad : int):
	if cache_quad >= 0 && cache_quad <= MAX_CACHE_QUAD:
		_cache_quad = cache_quad
	var viewer = GDN_viewer()
	if viewer == null:
		print("GDN_viewer() null")
	else:
		viewer.set_cache_quad(_cache_quad)
		log_debug(str("cache quad: ", _cache_quad))
func _get_cache_quad() -> int:
#	var viewer = GDN_viewer()
#	if viewer == null:
#		print("GDN_viewer() null")
#	else:
#		_cache_quad = viewer.get_cache_quad()
	return _cache_quad

func _init():
	_logger.debug("_init")
	name = tw_constants.tw_viewer_node_name
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_logger.debug("_ready")
	if Engine.editor_hint:
		_depth_quad = 1
		_cache_quad = 1
	var GDNMain : Node = GDN_main()
	if GDNMain == null:
		GDNMain = TWViewerGDNMain.new()
		GDNMain.name = tw_constants.tw_gdn_main_node_name
		add_child(GDNMain)
	if Engine.editor_hint:
		#delete_children()
		init()
	else:
		#delete_children()
		init()
	_is_ready = true
	var e := get_tree().get_root().connect("size_changed", self, "resizing")
	log_debug(str("connect size_changed result=", e))
	set_notify_transform(true)
	var viewer = GDN_viewer()
	if viewer == null:
		log_debug("GDN_viewer null")
	else:
		viewer.global_transform = global_transform
		viewer.visible = is_visible_in_tree()
		log_debug("global_transform changed")
	log_debug("_ready done")
		
func _enter_tree():
	_logger.debug("_enter_tree")
	
func _exit_tree():
	log_debug("_exit_tree")
	_is_ready = false	
	if _init_done:
		deinit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#log_debug("_process")
	
	if _transform_changed && GDN_viewer() != null:
		GDN_viewer().global_transform = global_transform
		log_debug(str("_process: global transform changed: ", global_transform))
		_transform_changed = false
	
	if _visibility_changed && GDN_viewer() != null:
		GDN_viewer().visible = is_visible_in_tree()
		log_debug(str("_process: visibility changed: ", is_visible_in_tree()))
		_visibility_changed = false

	#if Engine.editor_hint:
	#	var clientstatus : int = get_clientstatus()
	#	_status = tw_constants.status_to_string(clientstatus)
	pass
	
func _notification(_what):
	#log_debug(str("_notification: ", _what))
	if (_what == Spatial.NOTIFICATION_TRANSFORM_CHANGED):
		log_debug("_notification: global transform changed")
		_transform_changed = true
	elif (_what == Spatial.NOTIFICATION_VISIBILITY_CHANGED):
		log_debug("_notification: visibility changed")
		_visibility_changed = true

func resizing():
	log_debug(str("Resizing: ", get_viewport().size))

func init() -> bool:
	log_debug("init")
	if _init_done:
		return false
	else:
		GDN_main().init(self)
		set_debug_mode(_debug_mode)
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

func set_editor_camera(camera : Camera):
	GDN_viewer().set_editor_camera(camera)
	return

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	_status = tw_constants.status_to_string(new_client_status)
	var old_client_status_str : String = tw_constants.status_to_string(old_client_status)
	var new_client_status_str : String = tw_constants.status_to_string(new_client_status)
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))

func find_node_by_name(node_name : String) -> Node:
		if Engine.editor_hint:
			var scene : SceneTree = get_tree()
			if scene == null:
				return null
			var node : Node = get_tree().get_edited_scene_root().find_node(node_name, true, false)
			return node
		else:
			var scene : SceneTree = get_tree()
			if scene == null:
				return null
			var node : Node = get_tree().get_root().find_node(node_name, true, false)
			return node
	
func GDN_main():
	if TWViewerGDNMain_instance == null:
		TWViewerGDNMain_instance = find_node_by_name(tw_constants.tw_gdn_main_node_name)
		#GDNTheWorldMain_instance = GDNTheWorldMain.new()
	return TWViewerGDNMain_instance

func GDN_globals():
	if GDNTheWorldGlobals == null:
		var main : Node = GDN_main()
		if main == null:
			return null
		if !main.has_method("globals"):
			return null
		GDNTheWorldGlobals = main.globals(true)
	return GDNTheWorldGlobals

func GDN_viewer():
	if GDNTheWorldViewer == null:
		var globals : Node = GDN_globals()
		if globals == null:
			return null
		if !globals.has_method("viewer"):
			return null
		GDNTheWorldViewer = globals.viewer(true)
	return GDNTheWorldViewer

func get_self() -> Spatial:
	return self

func set_debug_mode(debug_mode : int):
	var debug_enabled = false
	if debug_mode == 0:		# DEFAULT
		if _logger.is_verbose():
			debug_enabled = true
	if debug_mode == 1:		# ENABLED
		debug_enabled = true
	var globals = GDN_globals()
	if globals == null:
		print("GDN_globals() null")
		return
	if !globals.has_method("set_debug_enabled"):
		print("GDN_globals() does not have method set_debug_enabled")
		return
	globals.set_debug_enabled(debug_enabled)

func get_clientstatus() -> int:
	if _init_done:
		var gdn_globals : Node = GDN_globals()
		if gdn_globals == null:
			#log_debug(str("gdn_globals null"))
			return tw_constants.clientstatus_uninitialized
		if !gdn_globals.has_method("get_status"):
			return tw_constants.clientstatus_uninitialized
		#else:
		#	log_debug("gdn_globals.has_method(get_status)")
		var status : int = gdn_globals.get_status()
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
	#if Engine.editor_hint:
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("debug_print"):
			gdn_globals.debug_print(str(context,": ", text), godot_print)

func log_info(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)
	
func info_print(var context: String, var text : String, var godot_print : bool):
	#if Engine.editor_hint:
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("info_print"):
			gdn_globals.info_print(str(context,": ", text), godot_print)

func log_error(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)
	
func error_print(var context: String, var text : String, var godot_print : bool):
	#if Engine.editor_hint:
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("error_print"):
			gdn_globals.error_print(str(context,": ", text), godot_print)

# debug
#enum Tile {TILE_AIR = 0, TILE_BLOCK, TILE_ICE}
#export(Tile) var tile_type : int = 0 setget set_tile_type
#func set_tile_type(p_tile_type : int):
#	tile_type = p_tile_type
#	print(tile_type)
#export({user = 0, moderator = 50, admin = 100}) var role : int = 100 setget set_role
#func set_role(p_role : int):
#	role = p_role
#	print(role)
#export({"user": 0, "moderator": 50, "admin": 100}) var role_alt : int = 100 setget set_role_alt
#func set_role_alt(p_role_alt : int):
#	role_alt = p_role_alt
#	print(role_alt)
#const Utils = {"Util 1": 0, "Util 2": 1, "Util 3": 10}
#export(Utils) var util : int setget set_util
#func set_util(p_util):
#	util = p_util
#	print(util)
# debug
