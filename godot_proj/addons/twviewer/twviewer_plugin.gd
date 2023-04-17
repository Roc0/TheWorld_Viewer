tool

extends EditorPlugin

const TWViewer = preload("./tw_viewer.gd")
const TWTest = preload("./tw_test.gd")
const tw_editor_util = preload("./tools/util/editor_util.gd")
const HT_Logger = preload("./util/logger.gd")

var _logger = HT_Logger.get_for(self)
var _viewer : TWViewer = null
var _tw_test : TWTest = null

#const AUTOLOAD_NAME = "Globals"
#const AUTOLOAD_SCRIPT = "res://addons/twviewer/init/Globals.gd"

func _enter_tree():
	_logger.debug("TWViewer plugin: _enter_tree")
	
	add_custom_type("TWViewer", "Spatial", TWViewer, get_icon("heightmap_node"))
	add_custom_type("TWTest", "Spatial", TWTest, get_icon("heightmap_node"))
	
	#add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _exit_tree():
	_logger.debug("TWViewer plugin: _exit_tree")
	
	remove_custom_type("TWTest")
	remove_custom_type("TWViewer")
	
	#remove_autoload_singleton(AUTOLOAD_NAME)

func handles(object):
	var b : bool = _get_custom_object(object) != null
	#if b:
	#	_logger.debug(str("TWViewer: handles ", object))
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
	_logger.debug(str("TWViewer: edit ", object))

	var custom_object = _get_custom_object(object)
	
	if _viewer != null:
		_viewer.disconnect("tree_exited", self, "_viewer_exited_scene")
		_viewer = null

	if custom_object != null && custom_object is TWViewer:
		_viewer = custom_object
	
	if _viewer != null:
		_viewer.connect("tree_exited", self, "_viewer_exited_scene")
		
		_logger.debug(str("TWViewer: edit ", object, " calling ", object, ".init"))
		var init_done : bool =_viewer.init()
		
		if _tw_test == null:
			_tw_test = TWTest.new()
			print("TWTest: " + str(_tw_test))
			_viewer.get_parent().add_child(_tw_test)
	#else:
	#	if _tw_test != null:
	#		_viewer.get_parent().remove_child(_tw_test)
	#		_tw_test.queue_free()
	#		_tw_test = null
		
func _viewer_exited_scene():
	_logger.debug("TWViewer exited the scene")
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
