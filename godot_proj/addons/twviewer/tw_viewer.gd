tool

extends Spatial

var _gdn_main = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer_d.gdns")
#var _gdn_main = preload("res://addons/twviewer/native/GDN_TheWorld_Viewer.gdns")
var _gdn_main_instance : Node = null

const tw_constants = preload("res://addons/twviewer/tw_const.gd")
const HT_Logger = preload("./util/logger.gd")

var _editor_interface : EditorInterface = null
var _editor_camera : Camera = null
var _editor_3d_overlay : Control = null

var _gdn_globals : Node = null
var _gdn_viewer : Spatial = null
var _logger = HT_Logger.get_for(self)
var _tree_entered := false
var _init_done : bool = false
var _is_ready : bool = false
var _transform_changed : bool = false
var _visibility_changed : bool = false

var _client_status : int
var _hit_pos : Vector3 = Vector3(0, 0, 0)
var _prev_hit_pos : Vector3 = Vector3(0, 0, 0)
var _last_check_delta_pos := 0
var _delta_pos := Vector3(0, 0, 0)

var _alt_pressed : bool = false
var _ctrl_pressed : bool = false
var _shift_pressed : bool = false

var _edit_panel_visibility_changed = false
var _info_panel_added_to_editor_overlay : bool = false
var _edit_mode_ui_control_added_to_editor_overlay : bool = false

var _info_panel_external_labels = []

var _info_panel_visibility_changed = false
var _info_panel : Control = null
var _info_panel_main_vboxcontainer : VBoxContainer = null

var _info_panel_general_label : Label = null
var _info_panel_camera_label : Label = null
var _info_panel_quadrants_label : Label = null
var _info_panel_chunks_label : Label = null
var _info_panel_mouse_tracking_label : Label = null

var _info_panel_status := ""
var _info_panel_render_process_durations_mcs := ""
var _info_panel_draw_mode := ""
var _info_panel_num_locks := ""
var _info_panel_grid_origin := ""
var _info_panel_camera_degree_from_north := ""
var _info_panel_camera_yaw := ""
var _info_panel_camera_pitch := ""
var _info_panel_camera_rot := ""
var _info_panel_camera_pos := ""
var _info_label_num_quadrants := ""
var _info_label_num_visible_quadrants := ""
var _info_label_num_empty_quadrants := ""
var _info_label_num_flushed_quadrants := ""
var _info_panel_num_active_chunks := ""
var _info_panel_num_chunk_splits := ""
var _info_panel_num_chunk_joins := ""
var _info_panel_hit_pos := ""
var _info_panel_delta_pos := ""
var _info_panel_quad_hit_name := ""
var _info_panel_quad_hit_pos := ""
var _info_panel_quad_hit_size := ""
var _info_panel_chunk_hit_name := ""
var _info_panel_chunk_hit_pos := ""
var _info_panel_chunk_hit_size := ""
var _info_panel_chunk_hit_dist_from_camera := ""

#var _test : Label = null
#var _test_added_to_editor_overlay : bool = false

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
		print("_depth_quad setter: GDN_viewer() null")
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
		print("_cache_quad setter: GDN_viewer() null")
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

#var _info_panel_visible : bool = false
export var _info_panel_visible : bool setget _set_info_panel_visible #, _get_info_panel_visible
func _set_info_panel_visible(info_panel_visible : bool):
	_info_panel_visible = info_panel_visible
	_info_panel_visibility_changed = true
#func _get_info_panel_visible() -> bool:
#	return _info_panel_visible

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
		GDNMain = _gdn_main.new()
		GDNMain.name = tw_constants.tw_gdn_main_node_name
		add_child(GDNMain)
	if Engine.editor_hint:
		#delete_children()
		init()
	else:
		#delete_children()
		init()
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
	
	create_info_panel()
	
	#_test = Label.new()
	#add_child(_test)
	#_test.text = "AAAAAAAAAAAAAAAAAAAAA\nAAAAAAAAAAAAAAAAAAAAA\nAAAAAAAAAAAAAAAAAAAAA\nAAAAAAAAAAAAAAAAAAAAA"
	#var dpi_scale : float = 0.1
	#if _test.rect_min_size != Vector2(0, 0):
	#	_test.rect_min_size *= dpi_scale
	#_test.margin_bottom *= dpi_scale
	#_test.margin_left *= dpi_scale
	#_test.margin_top *= dpi_scale
	#_test.margin_right *= dpi_scale

	log_debug("_ready done")
	_is_ready = true

func _enter_tree():
	_logger.debug("_enter_tree")
	_tree_entered = true

func _exit_tree():
	log_debug("_exit_tree")
	_is_ready = false	
	if _init_done:
		deinit()
	#if _test != null:
	#	_test.queue_free()
	#	_test = null
	if _info_panel != null:
		_info_panel.queue_free()
		_info_panel = null
	_tree_entered = false

func _input(event):
	if Engine.editor_hint:
		return
		
	if event is InputEventKey:
		if event.scancode == KEY_ALT:
			if event.is_pressed():
				_alt_pressed = true
			else:
				_alt_pressed = false
		if event.scancode == KEY_CONTROL:
			if event.is_pressed():
				_ctrl_pressed = true
			else:
				_ctrl_pressed = false
		if event.scancode == KEY_SHIFT:
			if event.is_pressed():
				_shift_pressed = true
			else:
				_shift_pressed = false
				
		if event.is_pressed() && event.scancode == KEY_I && _alt_pressed:
			toggle_info_panel_visibility()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#log_debug("_process")
	
	_client_status = get_clientstatus()
	var viewer = GDN_viewer()
	
	if _transform_changed && viewer != null:
		viewer.global_transform = global_transform
		log_debug(str("_process: global transform changed: ", global_transform))
		_transform_changed = false
	
	if _visibility_changed && viewer != null:
		viewer.visible = is_visible_in_tree()
		log_debug(str("_process: visibility changed: ", is_visible_in_tree()))
		_visibility_changed = false

	if _info_panel_visibility_changed:
		if _info_panel != null:
			_info_panel.visible =  _info_panel_visible
			#print(str("_info_panel_visible=", _info_panel.visible))
		_info_panel_visibility_changed = false

	if _edit_panel_visibility_changed:
		if viewer != null:
			viewer.toggle_edit_mode()
			_edit_panel_visibility_changed = false

	if Engine.editor_hint:
		#if _editor_3d_overlay != null && _test != null && !_test_added_to_editor_overlay:
		#	var parent : Node = _test.get_parent()
		#	if parent != null:
		#		parent.remove_child(_test)
		#	_editor_3d_overlay.add_child(_test)
		#	log_debug(str("_editor_3d_overlay=", _editor_3d_overlay))
		#	_test_added_to_editor_overlay = true

		if _editor_3d_overlay != null && !_info_panel_added_to_editor_overlay && _info_panel != null:
			var parent : Node = _info_panel.get_parent()
			if parent != null:
				parent.remove_child(_info_panel)
			_editor_3d_overlay.add_child(_info_panel)
			log_debug(str("_info_panel added"))
			_info_panel_added_to_editor_overlay = true

		if _editor_3d_overlay != null && !_edit_mode_ui_control_added_to_editor_overlay:
			var edit_mode_ui_control : Control = get_or_create_edit_mode_ui_control()
			if edit_mode_ui_control != null:
				var parent : Node = edit_mode_ui_control.get_parent()
				if parent != null:
					parent.remove_child(edit_mode_ui_control)
				_editor_3d_overlay.add_child(edit_mode_ui_control)
				log_debug(str("edit_mode_ui_control added"))
				_edit_mode_ui_control_added_to_editor_overlay = true
	
	if _info_panel != null && _info_panel.visible && viewer != null && viewer.has_method("get_camera"):
		_info_panel_status = "Status: " + tw_constants.status_to_string(_client_status) + "\n"
		var camera : Camera = null
		camera = viewer.get_camera()
		var update_quads1_duration : int = viewer.get_update_quads1_duration()
		var update_quads2_duration : int = viewer.get_update_quads2_duration()
		var update_quads3_duration : int = viewer.get_update_quads3_duration()
		_hit_pos = viewer.get_mouse_hit()
		if OS.get_ticks_msec() - _last_check_delta_pos > 500:
			if _hit_pos != _prev_hit_pos:
				_delta_pos = _hit_pos - _prev_hit_pos
				_prev_hit_pos = _hit_pos
			_last_check_delta_pos = OS.get_ticks_msec()
		if !Engine.editor_hint:
			_info_panel_draw_mode = "Draw mode: " +  viewer.get_debug_draw_mode() + "\n"
			_info_panel_num_locks = "Locks: " +  str(viewer.get_num_process_not_owns_lock()) + "\n"
			if camera != null && camera.has_method("get_yaw"):
				_info_panel_camera_degree_from_north = "  Deg. north: " + str(camera.get_angle_from_north()) + "\n"
				_info_panel_camera_yaw = "  Yaw :" + str(camera.get_yaw(false)) + "\n"
				_info_panel_camera_pitch = "  Pitch :" + str(camera.get_pitch(false)) + "\n"
		_info_panel_grid_origin = "Grid origin: " + str(viewer.global_transform.origin) + "\n"
		_info_panel_render_process_durations_mcs = "Render process (mcs): " + str(viewer.get_process_duration()) + "\n"
		#+ " UQ " + String (update_quads1_duration + update_quads2_duration + update_quads3_duration) \
		#+ " (" + String(update_quads1_duration) \
		#+ " " + String(update_quads2_duration) \
		#+ " " + String(update_quads3_duration)\
		#+ ") UC " + String(viewer.get_update_chunks_duration()) \
		#+ " UM " + String(viewer.get_update_material_params_duration()) \
		#+ " RQ " + String(viewer.get_refresh_quads_duration()) \
		#+ " T " + String(viewer.get_mouse_track_hit_duration()) + "\n"
		if camera != null:
			_info_panel_camera_rot = "  Rot: " + str(camera.global_transform.basis.get_euler()) + "\n"
			_info_panel_camera_pos = "  Pos :" + str(camera.global_transform.origin)
		_info_label_num_quadrants = "  Total: " + str(viewer.get_num_initialized_quadrant(), ":", viewer.get_num_quadrant()) + "\n"
		_info_label_num_visible_quadrants = "  Visible: " + str(viewer.get_num_initialized_visible_quadrant(), ":", viewer.get_num_visible_quadrant()) + "\n"
		_info_label_num_empty_quadrants = "  Empty: " + str(viewer.get_num_empty_quadrant()) + "\n"
		_info_label_num_flushed_quadrants = "  Flushed: " + str(viewer.get_num_flushed_quadrant())
		_info_panel_num_active_chunks = "  Active: " + str(viewer.get_num_active_chunks()) + "\n"
		_info_panel_num_chunk_splits = "  Splits: " + str(viewer.get_num_splits()) + "\n"
		_info_panel_num_chunk_joins = "  Joins: " + str(viewer.get_num_joins())
		_info_panel_hit_pos = "  Hit pos: " + str(viewer.get_mouse_hit()) + "\n"
		_info_panel_delta_pos = "  Delta pos: " + str(_delta_pos) + "\n"
		_info_panel_quad_hit_name = "  Quad name: " + viewer.get_mouse_quadrant_hit_name() + " " + viewer.get_mouse_quadrant_hit_tag() + "\n"
		_info_panel_quad_hit_pos = "  Quad pos: " + str(viewer.get_mouse_quadrant_hit_pos()) + "\n"
		_info_panel_quad_hit_size = "  Quad size: " + str(viewer.get_mouse_quadrant_hit_size()) + "\n"
		_info_panel_chunk_hit_name = "  Chunk name: " + viewer.get_mouse_chunk_hit_name() + "\n"
		_info_panel_chunk_hit_pos = "  Chunk pos: " + str(viewer.get_mouse_chunk_hit_pos()) + "\n"
		_info_panel_chunk_hit_size = "  Chunk size: " + str(viewer.get_mouse_chunk_hit_size()) + "\n"
		_info_panel_chunk_hit_dist_from_camera = "  Chunk dist from camera: " + str(viewer.get_mouse_chunk_hit_dist_from_cam())
		
		_info_panel_general_label.text = "FPS: " + str(Engine.get_frames_per_second()) + "\n" \
			+ _info_panel_status \
			+ _info_panel_render_process_durations_mcs \
			+ _info_panel_draw_mode \
			+ _info_panel_num_locks \
			+ _info_panel_grid_origin \
			+ "Pos in viewport: " + str(get_viewport().get_mouse_position())
		
		_info_panel_camera_label.text = "Camera\n" \
		+ _info_panel_camera_degree_from_north \
		+ _info_panel_camera_yaw \
		+ _info_panel_camera_pitch \
		+ _info_panel_camera_rot \
		+ _info_panel_camera_pos
		
		_info_panel_quadrants_label.text = "Quadrants\n" \
		+ _info_label_num_quadrants \
		+ _info_label_num_visible_quadrants \
		+ _info_label_num_empty_quadrants \
		+ _info_label_num_flushed_quadrants
		
		_info_panel_chunks_label.text = "Chunks\n" \
		+ _info_panel_num_active_chunks \
		+ _info_panel_num_chunk_splits \
		+ _info_panel_num_chunk_joins
		
		_info_panel_mouse_tracking_label.text = "Mouse tracking\n" \
		+ _info_panel_hit_pos \
		+ _info_panel_delta_pos \
		+ _info_panel_quad_hit_name \
		+ _info_panel_quad_hit_pos \
		+ _info_panel_quad_hit_size \
		+ _info_panel_chunk_hit_name \
		+ _info_panel_chunk_hit_pos \
		+ _info_panel_chunk_hit_size \
		+ _info_panel_chunk_hit_dist_from_camera
	
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
	set_size_info_panel()

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

func set_editor_3d_overlay(overlay : Control):
	_editor_3d_overlay = overlay

func set_editor_interface(editor_interface : EditorInterface):
	_editor_interface = editor_interface
	GDN_viewer().set_editor_interface(editor_interface)

func set_editor_camera(camera : Camera):
	_editor_camera = camera
	GDN_viewer().set_editor_camera(camera)
	return

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	#var status : String = tw_constants.status_to_string(new_client_status)
	var old_client_status_str : String = tw_constants.status_to_string(old_client_status)
	var new_client_status_str : String = tw_constants.status_to_string(new_client_status)
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))

func find_node_by_name(node_name : String) -> Node:
		if Engine.editor_hint:
			var scene : SceneTree = null
			#if _tree_entered:
			scene = get_tree()
			if scene == null:
				return null
			var node : Node = get_tree().get_edited_scene_root().find_node(node_name, true, false)
			return node
		else:
			var scene : SceneTree = null
			if _tree_entered:
				scene = get_tree()
			if scene == null:
				return null
			var node : Node = get_tree().get_root().find_node(node_name, true, false)
			return node
	
func GDN_main():
	if _gdn_main_instance == null:
		_gdn_main_instance = find_node_by_name(tw_constants.tw_gdn_main_node_name)
		#_gdn_main_instance = _gdn_main.new()
	return _gdn_main_instance

func GDN_globals():
	if _gdn_globals == null:
		var main : Node = GDN_main()
		if main == null:
			return null
		if !main.has_method("globals"):
			return null
		_gdn_globals = main.globals(true)
	return _gdn_globals

func GDN_viewer():
	if _gdn_viewer == null:
		var globals : Node = GDN_globals()
		if globals == null:
			return null
		if !globals.has_method("viewer"):
			return null
		_gdn_viewer = globals.viewer(true)
	return _gdn_viewer

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

func toggle_info_panel_visibility():
	_info_panel_visible = !_info_panel_visible
	_info_panel_visibility_changed = true

func toggle_edit_mode():
	_edit_panel_visibility_changed = true

func create_info_panel():
	var label : Label
	var hseparator : HSeparator
	var vseparator : VSeparator

	_info_panel = PanelContainer.new()
	#_info_panel = Control.new()
	#_info_panel = Panel.new()
	log_debug(str("_info_panel:", _info_panel))
	_info_panel.name = "InfoPanel"
	add_child(_info_panel)
	_info_panel_visibility_changed = true
	_info_panel.self_modulate = Color(1, 1, 1, 0.5)
	
	_info_panel_main_vboxcontainer = VBoxContainer.new()
	_info_panel_main_vboxcontainer.name = "Info"

	if Engine.editor_hint:
		var panel = TabContainer.new()
		_info_panel.add_child(panel)
		panel.name = "Info"
		panel.self_modulate = Color(1, 1, 1, 0.5)
		panel.add_child(_info_panel_main_vboxcontainer)
	else:
		_info_panel.add_child(_info_panel_main_vboxcontainer)
		
	#_info_panel_main_vboxcontainer.self_modulate = Color(1, 1, 1, 0.5)
	#var i : int = _info_panel_main_vboxcontainer.get_constant("hseparation=")
	#print(str("hseparation", i))
	#i = _info_panel_main_vboxcontainer.get_constant("vseparation=")
	#print(str("vseparation", i))
	
	_info_panel_general_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_camera_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_quadrants_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_chunks_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_mouse_tracking_label = add_info_panel_empty_line()
	
	set_size_info_panel()
	
	#apply_dpi_scale(_info_panel, 0.5)
	
func get_info_panel() -> Control:
	return _info_panel

func add_info_panel_separator():
	_info_panel_main_vboxcontainer.add_child(HSeparator.new())
	
func add_info_panel_block(text : String, indent : int):
	var _text : String = ""
	for i in indent:
		_text += "  "
	_text += text
	var hboxcontainer := HBoxContainer.new()
	_info_panel_main_vboxcontainer.add_child(hboxcontainer)
	var label := Label.new()
	hboxcontainer.add_child(label)
	label.text = _text

func add_info_panel_empty_line() -> Label:
	var label := Label.new()
	_info_panel_main_vboxcontainer.add_child(label)
	return label
		
func add_info_panel_line(text : String, indent : int) -> Label:
	var _text : String = ""
	for i in indent:
		_text += "  "
	_text += text
	var hboxcontainer := HBoxContainer.new()
	_info_panel_main_vboxcontainer.add_child(hboxcontainer)
	var label := Label.new()
	hboxcontainer.add_child(label)
	label.text = _text
	label = Label.new()
	hboxcontainer.add_child(label)
	return label

func add_info_panel_external_line(text : String, indent : int) -> int:
	if _info_panel_external_labels.size() == 0:
		add_info_panel_separator()
	var _text : String = ""
	for i in indent:
		_text += "  "
	_text += text
	var label_index = _info_panel_external_labels.size()
	var hboxcontainer := HBoxContainer.new()
	_info_panel_main_vboxcontainer.add_child(hboxcontainer)
	var label := Label.new()
	hboxcontainer.add_child(label)
	label.text = _text
	label = Label.new()
	hboxcontainer.add_child(label)
	_info_panel_external_labels.append(label)
	return label_index
	
func set_info_panel_external_value(text : String, index : int):
	if _info_panel_external_labels.size() > index:
		_info_panel_external_labels[index].text = text

func set_size_info_panel():
	#pass
	#_info_panel.anchor_left = 0
	#_info_panel.anchor_right = 0
	#_info_panel.anchor_top = 0
	#_info_panel.anchor_left = 0
	_info_panel.margin_top = 40
	#_info_panel.margin_left = 0
	#_info_panel.margin_right = 100
	#_info_panel.margin_bottom = 100
	
func is_ready() -> bool:
	return _is_ready

func get_or_create_edit_mode_ui_control() -> Control:
	var control : Control = null
	var viewer = GDN_viewer()
	if viewer != null && viewer.has_method("get_or_create_edit_mode_ui_control"):
		control = viewer.get_or_create_edit_mode_ui_control()
	return control

# Generic way to apply editor scale to a plugin UI scene.
# It is slower than doing it manually on specific controls.
static func apply_dpi_scale(root: Control, dpi_scale: float):
	if dpi_scale == 1.0:
		return
	var to_process := [root]
	while len(to_process) > 0:
		var node : Node = to_process[-1]
		to_process.pop_back()
		if node is Viewport:
			continue
		if node is Control:
			if node.rect_min_size != Vector2(0, 0):
				node.rect_min_size *= dpi_scale
			var parent = node.get_parent()
			if parent != null:
				if not (parent is Container):
					node.margin_bottom *= dpi_scale
					node.margin_left *= dpi_scale
					node.margin_top *= dpi_scale
					node.margin_right *= dpi_scale
		for i in node.get_child_count():
			to_process.append(node.get_child(i))

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
