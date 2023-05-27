@tool

extends EditorPlugin

const TWViewer = preload("./tw_viewer.gd")
const tw_editor_util = preload("./tools/util/editor_util.gd")
const tw_constants = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)

const initialViewerPos := Vector3(0, 0, 0)
const initialCameraDistanceFromTerrain = 300
const initialLevel := 0

var _debug_enabled : bool = true
var _debug_enable_set : bool = false
var _world_initialized : bool = false
#var _viewer_id : int = 0
var _viewer : TWViewer = null
var _viewer_init_done : bool = false

var _alt_pressed : bool = false
var _ctrl_pressed : bool = false
var _shift_pressed : bool = false

var _info_panel_visible : bool = false
var _info_panel : Control = null
var _edit_mode_ui_control : Control = null

#const AUTOLOAD_NAME = "Globals"
#const AUTOLOAD_SCRIPT = "res://addons/twviewer/init/Globals.gd"

func _enter_tree():
	_logger.debug("_enter_tree")
	
	add_custom_type("TWViewer", "Node3D", TWViewer, preload("icon.png"))
	#add_custom_type("TWViewerGDNMain", "Node", GDNTheWorldMain, get_icon("heightmap_node"))
	
	#set_input_event_forwarding_always_enabled()
	
	#add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)
	
func _exit_tree():
	_logger.debug("_exit_tree")
	
	#remove_custom_type("TWViewerGDNMain")
	remove_custom_type("TWViewer")
	
	#remove_autoload_singleton(AUTOLOAD_NAME)

func _process(delta: float):
	#_logger.debug(str("_process "))
	
	if !_viewer_init_done:
		#_logger.debug(str("_process: _viewer_init_done=", _viewer_init_done))
		_viewer = find_node_by_name(tw_constants.tw_viewer_node_name)
		if _viewer != null && _viewer.has_method("is_ready") && _viewer.is_ready():
			_logger.debug(str("_process: _viewer_init_done=", _viewer_init_done, " initializing ..."))
			
			var editor_interface := get_editor_interface()
			_logger.debug (str("EditorInterface ", editor_interface))
			_viewer.set_editor_interface(editor_interface)
			
			if !_viewer.is_connected("tree_exited", Callable(self, "_viewer_exited_scene")):
				_viewer.connect("tree_exited", Callable(self, "_viewer_exited_scene"))
				_logger.debug ("TWViewer connected")
			
			editor_interface.edit_node(_viewer)
			
			update_overlays()
			
			#_viewer_connected = true
			_viewer_init_done = true
			_logger.debug(str("_process: _viewer_init_done=", _viewer_init_done))

	var clientstatus : int = 0
	clientstatus = get_clientstatus()

	if _viewer != null && clientstatus >= tw_constants.clientstatus_session_initialized && !_world_initialized:
		_viewer.GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
		_world_initialized = true

func handles(object):
	var b : bool = _get_custom_object(object) != null
	#if b:
	#	_logger.debug(str("handles ", object))
	return b

func _make_visible(visible: bool):
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
	
	#if _viewer != null && _viewer_connected:
	#	_viewer.disconnect("tree_exited", self, "_viewer_exited_scene")
	#	_logger.debug ("TWViever disconnected")
	#	_viewer_connected = false

	if custom_object == null:
		return
		
	#if custom_object != null && custom_object is TWViewer:
	#	_viewer = custom_object
	#	#if _viewer_id == 0:
	#	#	_viewer_id = _viewer.get_instance_id()
	
	#if _viewer != null && !_viewer_connected:
	#	_viewer.connect("tree_exited", self, "_viewer_exited_scene")
	#	_logger.debug ("TWViever connected")
	#	_viewer_connected = true
	
func _forward_3d_draw_over_viewport(overlay : Control):
	#print("forward_spatial_draw_over_viewport")
	if _viewer != null:
		_viewer.set_editor_3d_overlay(overlay)
	
func _forward_3d_gui_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	var ret : int = EditorPlugin.AFTER_GUI_INPUT_PASS
	
	if _viewer != null:
		_viewer.set_editor_camera(p_camera)
	
	if p_event is InputEventKey:
		if p_event.keycode == KEY_ALT:
			if p_event.is_pressed():
				_alt_pressed = true
			else:
				_alt_pressed = false
		if p_event.keycode == KEY_CTRL:
			if p_event.is_pressed():
				_ctrl_pressed = true
			else:
				_ctrl_pressed = false
		if p_event.keycode == KEY_SHIFT:
			if p_event.is_pressed():
				_shift_pressed = true
			else:
				_shift_pressed = false
		
		if p_event.is_pressed() && p_event.keycode == KEY_I && _alt_pressed:
			if _viewer != null && _viewer.has_method("toggle_info_panel_visibility"):
				_viewer.toggle_info_panel_visibility()
			
		if p_event.is_pressed() && p_event.keycode == KEY_T && _alt_pressed:
			if _viewer != null && _viewer.has_method("toggle_track_mouse"):
				_viewer.toggle_track_mouse()

		if p_event.is_pressed() && p_event.keycode == KEY_E && _alt_pressed:
			if _viewer != null && _viewer.has_method("toggle_edit_mode"):
				_viewer.toggle_edit_mode()

		if p_event.is_pressed() && p_event.keycode == KEY_SPACE && _alt_pressed:
			if _viewer != null && _viewer.has_method("toggle_quadrant_selected"):
				_viewer.toggle_quadrant_selected()

		if p_event.is_pressed() && p_event.keycode == KEY_D && _alt_pressed:
			if _viewer != null && _viewer.has_method("rotate_chunk_debug_mode"):
				_viewer.rotate_chunk_debug_mode()

	return ret

func _apply_changes():
	_logger.debug("_apply_changes")
	_viewer_init_done = false
	if _viewer != null:
		_viewer._apply_changes()
	
func _viewer_exited_scene():
	_logger.debug("tw_viewer exited the scene")
	_viewer_init_done = false
	_logger.debug(str("_viewer_exited_scene: _viewer_init_done=", _viewer_init_done))
	_viewer = null
	edit(null)

static func _get_custom_object(object):
	if object != null and object is Node3D:
		if not object.is_inside_tree():
			return null
		if object is TWViewer:
			return object
	return null
	
func get_icon(icon_name: String) -> Texture2D:
	return tw_editor_util.load_texture("res://addons/zylann.hterrain/tools/icons/icon_" + icon_name + ".svg")

func get_clientstatus() -> int:
	var clientstatus = tw_constants.clientstatus_uninitialized
	if _viewer != null && _viewer.has_method("get_clientstatus"):
		var _clientstatus = _viewer.get_clientstatus()
		if _clientstatus != null:
			clientstatus = _clientstatus
			#_logger.debug(str("_viewer.get_clientstatus() OK: ", _clientstatus))
		#else:
		#	_logger.debug(str("PID=", OS.get_process_id()))
	return clientstatus

func find_node_by_name(node_name : String) -> Node:
	if Engine.is_editor_hint():
		var scene : SceneTree = get_tree()
		if scene == null:
			return null
		var root = scene.get_edited_scene_root()
		if root == null:
			return null
		var node : Node = scene.root.find_child(node_name, true, false)
		return node
	else:
		var scene : SceneTree = get_tree()
		if scene == null:
			return null
		var root = scene.get_root()
		if root == null:
			return null
		var node : Node = scene.root.find_child(node_name, true, false)
		return node
