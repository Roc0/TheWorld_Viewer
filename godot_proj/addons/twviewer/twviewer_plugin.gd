tool

extends EditorPlugin

const TWViewer = preload("./tw_viewer.gd")
const tw_editor_util = preload("./tools/util/editor_util.gd")
const HT_Logger = preload("./util/logger.gd")
var tw_constants = preload("res://addons/twviewer/tw_const.gd")
#const TWTest = preload("./tw_test.gd")
#const HTerrainDetailLayer = preload("../zylann.hterrain/hterrain_detail_layer.gd")

const initialViewerPos := Vector3(0, 0, 0)
const initialCameraDistanceFromTerrain = 300
const initialLevel := 0

var _debug_enabled : bool = true
var _debug_enable_set : bool = false
var _world_initialized : bool = false
var _logger = HT_Logger.get_for(self)
var _viewer : TWViewer = null
var _init_done : bool = false
var _viewer_connected : bool = false
#var _tw_test : TWTest = null

#const AUTOLOAD_NAME = "Globals"
#const AUTOLOAD_SCRIPT = "res://addons/twviewer/init/Globals.gd"

func _enter_tree():
	_logger.debug("_enter_tree")
	
	add_custom_type("TWViewer", "Spatial", TWViewer, get_icon("heightmap_node"))
	#add_custom_type("TWTest", "Spatial", TWTest, get_icon("heightmap_node"))
	
	#add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _exit_tree():
	_logger.debug("_exit_tree")
	
	#remove_custom_type("TWTest")
	remove_custom_type("TWViewer")
	
	#remove_autoload_singleton(AUTOLOAD_NAME)

func _process(delta: float):
	#_logger.debug(str("_process "))
	
	if _viewer != null && !_init_done:
		_logger.debug(str("_process calling ", _viewer, ".init"))
		var init_done : bool =_viewer.init()
		_logger.debug(str("init_done ", init_done))
		if (init_done):
			var editor_interface := get_editor_interface()
			_logger.debug (str("EditorInterface ", editor_interface))
			_viewer.set_editor_interface(editor_interface)
			_init_done = true

	var clientstatus : int = get_clientstatus()
	if clientstatus >= tw_constants.clientstatus_session_initialized && !_debug_enable_set:
		_debug_enable_set = true
		set_debug_enabled(_debug_enabled)

	if clientstatus >= tw_constants.clientstatus_session_initialized && !_world_initialized:
		#_viewer.GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
		_world_initialized = true

func handles(object):
	var b : bool = _get_custom_object(object) != null
	#if b:
	#	_logger.debug(str("handles ", object))
	return b

func make_visible(visible: bool):
	#_panel.set_visible(visible)
	#_toolbar.set_visible(visible)
	#_brush_decal.update_visibility()

	# TODO Workaround https://github.com/godotengine/godot/issues/6459
	# When the user selects another node,
	# I want the plugin to release its references to the terrain.
	# This is important because if we don't do that, some modified resources will still be
	# loaded in memory, so if the user closes the scene and reopens it later, the changes will
	# still be partially present, and this is not expected.
	if not visible:
		edit(null)

func edit(object):
	_logger.debug(str("edit ", object))

	var custom_object = _get_custom_object(object)
	
	if _viewer != null && _viewer_connected:
		_viewer.disconnect("tree_exited", self, "_viewer_exited_scene")
		_viewer_connected = false
		#_viewer = null

	if custom_object == null:
		return
		
	if custom_object != null && custom_object is TWViewer:
		_viewer = custom_object
	
	if _viewer != null && !_viewer_connected:
		_viewer.connect("tree_exited", self, "_viewer_exited_scene")
		_viewer_connected = true
	
	#if _viewer != null:
		#_logger.debug(str("edit ", object, " calling ", object, ".init"))
		#var init_done : bool =_viewer.init()
		#print(str("init_done ", init_done))
		#if (init_done):
		#	var editor_interface := get_editor_interface()
		#	print (str("EditorInterface ", editor_interface))
		#	_viewer.set_editor_interface(editor_interface)
		
		#var clientstatus : int = get_clientstatus()
		#if clientstatus >= tw_constants.clientstatus_session_initialized && !_debug_enable_set:
		#	_debug_enable_set = true
		#	set_debug_enabled(_debug_enabled)

		#if clientstatus >= tw_constants.clientstatus_session_initialized && !_world_initialized:
		#	_viewer.GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
		#	_world_initialized = true
		
		#var node = HTerrainDetailLayer.new()
		#print (str("HTerrainDetailLayer", node))
		
		#if _tw_test == null:
		#	_tw_test = TWTest.new()
		#	print("TWTest: " + str(_tw_test))
		#	_viewer.get_parent().add_child(_tw_test)
		#	_tw_test.owner = get_tree().edited_scene_root
	#else:
	#	if _tw_test != null:
	#		_viewer.get_parent().remove_child(_tw_test)
	#		_tw_test.queue_free()
	#		_tw_test = null
		
func _viewer_exited_scene():
	_logger.debug("exited the scene")
	edit(null)

static func _get_custom_object(object):
	if object != null and object is Spatial:
		if not object.is_inside_tree():
			return null
		if object is TWViewer:
			return object
		#if object is TWTest:
		#	return object
		#if object is HTerrainDetailLayer and object.get_parent() is HTerrain:
		#	return object.get_parent()
	return null
	
func get_icon(icon_name: String) -> Texture:
	return tw_editor_util.load_texture("res://addons/zylann.hterrain/tools/icons/icon_" + icon_name + ".svg")

func get_clientstatus() -> int:
	if _viewer == null:
		return tw_constants.clientstatus_uninitialized
	else:
		return _viewer.get_clientstatus()

func set_debug_enabled(debug_mode : bool):
	if _viewer != null:
		_viewer.set_debug_enabled(debug_mode)
