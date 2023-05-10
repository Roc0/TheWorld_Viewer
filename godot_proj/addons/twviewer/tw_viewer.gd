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

var _client_status : int
var _hit_pos : Vector3 = Vector3(0, 0, 0)
var _prev_hit_pos : Vector3 = Vector3(0, 0, 0)

var _alt_pressed : bool = false
var _ctrl_pressed : bool = false
var _shift_pressed : bool = false

var _edit_panel_visibility_changed = false

var _info_panel_visible : bool = false

var _info_panel_external_labels = []

var _info_panel_visibility_changed = false
var _info_panel : Control = null
var _info_panel_main_vboxcontainer : VBoxContainer = null
var _fps_label : Label = null
var _client_status_label : Label = null
var _render_process_durations_mcs : Label = null
var _num_locks_label : Label = null
var _draw_mode_label : Label
var _grid_origin_label : Label
var _mouse_pos_in_viewport : Label
var _camera_degree_from_north_label : Label
var _camera_yaw_label : Label
var _camera_pitch_label : Label
var _camera_rot_label : Label
var _camera_pos_label : Label
var _num_quadrant_label : Label
var _num_visible_quadrant_label : Label
var _num_empty_quadrant_label : Label
var _num_flushed_quadrant_label : Label
var _num_active_chunks_label : Label
var _num_chunk_split_label : Label
var _num_chunk_join_label : Label
var _hit_pos_label : Label
var _delta_pos_label : Label
var _quad_hit_name_label : Label
var _quad_hit_pos_label : Label
var _quad_hit_size_label : Label
var _chunk_hit_name_label : Label
var _chunk_hit_pos_label : Label
var _chunk_hit_size_label : Label
var _chunk_hit_dist_from_cam_label : Label

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
		
	log_debug("_ready done")
	_is_ready = true
		
func _enter_tree():
	_logger.debug("_enter_tree")
	
func _exit_tree():
	log_debug("_exit_tree")
	_is_ready = false	
	if _init_done:
		deinit()
	#if _info_panel != null:
	#	_info_panel.queue_free()
	#	_info_panel = null

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

	if _info_panel != null && _info_panel.visible:
		if !Engine.editor_hint:
			_fps_label.text = String(Engine.get_frames_per_second())
			_num_locks_label.text = ""
			_draw_mode_label.text = ""
			_camera_degree_from_north_label.text = ""
			_camera_yaw_label.text = ""
			_camera_pitch_label.text = ""
			_chunk_hit_dist_from_cam_label.text = ""
			_num_empty_quadrant_label.text = ""
			_num_flushed_quadrant_label.text = ""
		_camera_rot_label.text = ""
		_camera_pos_label.text = ""
		_client_status_label.text = tw_constants.status_to_string(_client_status)
		_render_process_durations_mcs.text = ""
		_grid_origin_label.text = ""
		_mouse_pos_in_viewport.text = str(get_viewport().get_mouse_position())
		_num_quadrant_label.text = ""
		_num_visible_quadrant_label.text = ""
		_num_active_chunks_label.text = ""
		_num_chunk_split_label.text = ""
		_num_chunk_join_label.text = ""
		_hit_pos_label.text = ""
		_delta_pos_label.text = ""
		_quad_hit_name_label.text = ""
		_quad_hit_pos_label.text = ""
		_quad_hit_size_label.text = ""
		_chunk_hit_name_label.text = ""
		_chunk_hit_pos_label.text = ""
		_chunk_hit_size_label.text = ""

		if viewer != null && viewer.has_method("get_camera"):
			var camera : Camera = null
			camera = viewer.get_camera()
			var update_quads1_duration : int = viewer.get_update_quads1_duration()
			var update_quads2_duration : int = viewer.get_update_quads2_duration()
			var update_quads3_duration : int = viewer.get_update_quads3_duration()
			var delta_pos : Vector3
			_hit_pos = viewer.get_mouse_hit()
			if _hit_pos != _prev_hit_pos:
				delta_pos = _hit_pos - _prev_hit_pos
				_prev_hit_pos = _hit_pos
			_render_process_durations_mcs.text = String(viewer.get_process_duration())
			#_render_process_durations_mcs.text = String(viewer.get_process_duration()) \
			#+ " UQ " + String (update_quads1_duration + update_quads2_duration + update_quads3_duration) \
			#+ " (" + String(update_quads1_duration) \
			#+ " " + String(update_quads2_duration) \
			#+ " " + String(update_quads3_duration)\
			#+ ") UC " + String(viewer.get_update_chunks_duration()) \
			#+ " UM " + String(viewer.get_update_material_params_duration()) \
			#+ " RQ " + String(viewer.get_refresh_quads_duration()) \
			#+ " T " + String(viewer.get_mouse_track_hit_duration())
			if !Engine.editor_hint:
				_num_locks_label.text = str(viewer.get_num_process_not_owns_lock())
				_draw_mode_label.text = viewer.get_debug_draw_mode()
				if camera != null:
					if camera.has_method("get_angle_from_north"):
						_camera_degree_from_north_label.text = str(camera.get_angle_from_north())
					if camera.has_method("get_yaw"):
						_camera_yaw_label.text = str(camera.get_yaw(false))
					if camera.has_method("get_pitch"):
						_camera_pitch_label.text = str(camera.get_pitch(false))
				_chunk_hit_dist_from_cam_label.text = str(viewer.get_mouse_chunk_hit_dist_from_cam())
				_num_empty_quadrant_label.text = str(viewer.get_num_empty_quadrant())
				_num_flushed_quadrant_label.text = str(viewer.get_num_flushed_quadrant())
			if camera != null:
				_camera_rot_label.text = str(camera.global_transform.basis.get_euler())
				_camera_pos_label.text = str(camera.global_transform.origin)
			_grid_origin_label.text = str(viewer.global_transform.origin)
			_num_quadrant_label.text = str(viewer.get_num_initialized_quadrant(), ":", viewer.get_num_quadrant())
			_num_visible_quadrant_label.text = str(viewer.get_num_initialized_visible_quadrant(), ":", viewer.get_num_visible_quadrant())
			_num_active_chunks_label.text = str(viewer.get_num_active_chunks())
			_num_chunk_split_label.text = str(viewer.get_num_splits())
			_num_chunk_join_label.text = str(viewer.get_num_joins())
			_hit_pos_label.text = str(viewer.get_mouse_hit())
			_delta_pos_label.text = str(delta_pos)
			_quad_hit_name_label.text = viewer.get_mouse_quadrant_hit_name() + " " + viewer.get_mouse_quadrant_hit_tag()
			_quad_hit_pos_label.text = str(viewer.get_mouse_quadrant_hit_pos())
			_quad_hit_size_label.text = str(viewer.get_mouse_quadrant_hit_size())
			_chunk_hit_name_label.text = viewer.get_mouse_chunk_hit_name()
			_chunk_hit_pos_label.text = str(viewer.get_mouse_chunk_hit_pos())
			_chunk_hit_size_label.text = str(viewer.get_mouse_chunk_hit_size())

	#if Engine.editor_hint:
	#	var clientstatus : int = get_clientstatus()
	#	_status = tw_constants.status_to_string(clientstatus)
	
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

func set_editor_camera(camera : Camera):
	GDN_viewer().set_editor_camera(camera)
	return

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	#var status : String = tw_constants.status_to_string(new_client_status)
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
	_info_panel.self_modulate = Color(1, 1, 1, 0.5)
	log_debug(str("_info_panel:", _info_panel))
	_info_panel.name = "InfoPanel"
	if Engine.editor_hint:
		_info_panel_visible = false
	else:
		_info_panel_visible = false
		add_child(_info_panel)
	_info_panel_visibility_changed = true
	_info_panel_main_vboxcontainer = VBoxContainer.new()
	_info_panel.add_child(_info_panel_main_vboxcontainer)
	#var i : int = _info_panel_main_vboxcontainer.get_constant("hseparation=")
	#print(str("hseparation", i))
	#i = _info_panel_main_vboxcontainer.get_constant("vseparation=")
	#print(str("vseparation", i))
	
	if !Engine.editor_hint:
		_fps_label = add_info_panel_line("FPS:", 0)
	_client_status_label = add_info_panel_line("Status:", 0)
	if !Engine.editor_hint:
		_draw_mode_label = add_info_panel_line("Draw mode:", 0)
	if !Engine.editor_hint:
		_num_locks_label = add_info_panel_line("Locks:", 0)
	_render_process_durations_mcs = add_info_panel_line("Render process (mcs):", 0)
	_grid_origin_label = add_info_panel_line("Grid origin:", 0)
	_mouse_pos_in_viewport = add_info_panel_line("Pos in viewport:", 0)
	add_info_panel_separator()
	add_info_panel_block("Camera", 0)
	if !Engine.editor_hint:
		_camera_degree_from_north_label = add_info_panel_line("Deg. north:", 1)
		_camera_yaw_label = add_info_panel_line("Yaw:", 1)
		_camera_pitch_label = add_info_panel_line("Pitch:", 1)
	_camera_rot_label = add_info_panel_line("Rot:", 1)
	_camera_pos_label = add_info_panel_line("Pos:", 1)
	add_info_panel_separator()
	add_info_panel_block("Quadrants", 0)
	_num_quadrant_label = add_info_panel_line("Total:", 1)
	_num_visible_quadrant_label = add_info_panel_line("Visible:", 1)
	if !Engine.editor_hint:
		_num_empty_quadrant_label = add_info_panel_line("Empty:", 1)
		_num_flushed_quadrant_label = add_info_panel_line("Flushed:", 1)
	add_info_panel_separator()
	add_info_panel_block("Chunks", 0)
	_num_active_chunks_label = add_info_panel_line("Active:", 1)
	_num_chunk_split_label = add_info_panel_line("Split:", 1)
	_num_chunk_join_label = add_info_panel_line("Join:", 1)
	add_info_panel_separator()
	add_info_panel_block("Mouse tracking", 0)
	_hit_pos_label = add_info_panel_line("Hit pos:", 1)
	_delta_pos_label = add_info_panel_line("Delta:", 1)
	_quad_hit_name_label = add_info_panel_line("Quad name:", 1)
	_quad_hit_pos_label = add_info_panel_line("Quad pos:", 1)
	_quad_hit_size_label = add_info_panel_line("Quad size:", 1)
	_chunk_hit_name_label = add_info_panel_line("Chunk name:", 1)
	_chunk_hit_pos_label = add_info_panel_line("Chunk pos:", 1)
	_chunk_hit_size_label = add_info_panel_line("Chunk size:", 1)
	if !Engine.editor_hint:
		_chunk_hit_dist_from_cam_label = add_info_panel_line("Chunk dist from camera:", 1)
	
	set_size_info_panel()
	
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
	pass
	#_info_panel.anchor_left = 0
	#_info_panel.anchor_right = 0
	#_info_panel.anchor_top = 0
	#_info_panel.anchor_left = 0
	#_info_panel.margin_top = 0
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
