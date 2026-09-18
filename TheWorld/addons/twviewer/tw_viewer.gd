@tool
class_name TWViewer
extends Node3D

var _debug_sprite : Sprite2D = null

var _quitting : bool = false
var _deinit_in_progress : bool = false

var _gdn_main_instance : Node = null
var _gdn_main_instance_errmsg : bool = true

const tw_constants = preload("./tw_const.gd")
const HT_Logger = preload("./util/logger.gd")
const tw_info_container = preload("./tw_info_container.gd")

#var _editor_interface : EditorInterface = null
var _editor_interface = null
var _editor_camera : Camera3D = null
var _editor_3d_overlay : Control = null

const EXIT_STATUS_RUNNING = 0
const EXIT_STATUS_UNDEPLOYWORLD_REQUIRED = 1
const EXIT_STATUS_PREDEINIT_REQUIRED = 2
const EXIT_STATUS_QUIT_REQUIRED = 3
const EXIT_STATUS_QUITTING = 4
var _exit_status : int = EXIT_STATUS_RUNNING

var undeploy_request_logged : bool = false

var _gdn_globals : Node = null
var _gdn_viewer : Node3D = null
var _logger = HT_Logger.get_for(self)
var _plugin_tree_entered := false
var _init_done : bool = false
var _is_ready : bool = false
var _is_initialized : bool = false
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

var _info_panel_closing_labels = []
var _info_panel_num_closing_labels : int = 2
var _info_panel_external_labels = []

#var _info_panel : Control = null
var _info_panel : tw_info_container = null
var _info_panel_main_vboxcontainer : VBoxContainer = null
var _info_panel_scroll_container : ScrollContainer = null
var _info_panel_max_width : int = 0
var _mouse_inside_info_panel : bool = false

var _info_panel_general_label : Label = null
var _info_panel_camera3d_label : Label = null
var _info_panel_camera2d_label : Label = null
var _info_panel_quadrants_label : Label = null
var _info_panel_chunks_label : Label = null
var _info_panel_map_quadrants_label : Label = null
var _info_panel_mouse_tracking_label : Label = null

var _info_panel_status := ""
var _info_panel_render_process_durations_mcs := ""
var _info_panel_draw_mode := ""
var _info_panel_num_locks := ""
var _info_panel_grid_origin := ""
var _info_panel_camera_degree_from_north := ""
var _info_panel_camera_yaw := ""
var _info_panel_camera_pitch := ""
var _info_panel_camera_roll := ""
var _info_panel_camera_rot := ""
var _info_panel_camera_pos := ""
var _info_panel_camera_pos_in_map := ""
var _info_panel_camera_velocity := ""
var _info_panel_camera_und_water := ""
var _info_panel_camera2d_pos := ""
var _info_panel_camera2d_pos_in_map := ""
var _info_map_quadrants := ""
var _info_map_quadrant_overrides := ""
var _info_map_texture_rects := ""
var _info_label_num_quadrants := ""
var _info_label_num_visible_quadrants := ""
var _info_label_num_empty_quadrants := ""
var _info_label_num_flushed_quadrants := ""
var _info_label_num_reloading_quadrants := ""
var _info_label_num_loading_quadrants := ""
var _info_label_num_with_collider := ""
var _info_panel_num_active_chunks := ""
var _info_panel_num_chunk_splits := ""
var _info_panel_num_chunk_joins := ""
var _info_panel_hit_pos := ""
var _info_panel_hit_pos_in_map := ""
var _info_panel_hit_distance_from_camera := ""
var _info_panel_delta_pos := ""
var _info_panel_quad_hit_name := ""
var _info_panel_quad_hit_pos := ""
var _info_panel_quad_hit_size := ""
var _info_panel_chunk_hit_name := ""
var _info_panel_chunk_hit_pos := ""
var _info_panel_chunk_hit_size := ""
var _info_panel_chunk_hit_dist_from_camera := ""
var _info_panel_track_mouse_state := ""
var _info_panel_info_camera := ""
var _info_panel_camera_projection := ""

var _initial_level : int = 0

var _camera3d_current_pos : Vector3
var _camera3d_current_pos_in_map : Vector3
var _camera3d_current_yaw_pitch_roll_rad : Vector3

var _desidered_map_camera_zoom_factor : float = tw_constants.map_camera_initial_zoom_factor
var _desidered_map_camera_zoom_factor_changed = false

#@export_category("TWViewer")

var _loading_screen_changed := true
@export var _loading_screen : bool = true:
	set = _set_loading_screen
func _set_loading_screen(loading_screen : bool):
	_loading_screen = loading_screen
	_loading_screen_changed = true
	
var _full_world_deploy_changed := true
@export var _full_world_deploy : bool = true:
	set = _set_full_world_deploy
func _set_full_world_deploy(full_world_deploy : bool):
	_full_world_deploy = full_world_deploy
	_full_world_deploy_changed = true

var _debug_mode_changed := true
@export_enum("Default:-1", "Info:0", "Debug:1", "Verbose:2") var _debug_mode: int = 0:
	set = _set_debug_mode
func _set_debug_mode(p_debug_mode : int):
	_debug_mode = p_debug_mode
	_debug_mode_changed = true

@export_group("World", "_world_param")

var _world_param_depth_quad_changed := true
const MAX_DEPTH_QUAD=12
@export var _world_param_depth_quad : int = 3:		# 3
	set = _set_world_param_depth_quad
func _set_world_param_depth_quad(depth_quad : int):
	if depth_quad >= 0 && depth_quad <= MAX_DEPTH_QUAD:
		_world_param_depth_quad = depth_quad
		_world_param_depth_quad_changed = true
		if _world_param_depth_quad > _world_param_max_depth_quad:
			_set_world_param_max_depth_quad(_world_param_depth_quad)

var _world_param_cache_quad_changed := true
const MAX_CACHE_QUAD=2
@export var _world_param_cache_quad : int = 1:		# 1
	set = _set_world_param_cache_quad
func _set_world_param_cache_quad(cache_quad : int):
	if cache_quad >= 0 && cache_quad <= MAX_CACHE_QUAD:
		_world_param_cache_quad = cache_quad
		_world_param_cache_quad_changed = true

var _world_param_max_depth_quad_changed := true
@export var _world_param_max_depth_quad : int = MAX_DEPTH_QUAD:		# 3
	set = _set_world_param_max_depth_quad
func _set_world_param_max_depth_quad(depth_quad : int):
	if depth_quad >= 0 && depth_quad <= MAX_DEPTH_QUAD:
		_world_param_max_depth_quad = depth_quad
		_world_param_max_depth_quad_changed = true
		if _world_param_max_depth_quad < _world_param_depth_quad:
			_set_world_param_depth_quad(_world_param_max_depth_quad)

var _world_param_info_panel_visibility_changed := true
@export var _world_param_info_panel_visible : bool = false:
	set = _set_world_param_info_panel_visible
func _set_world_param_info_panel_visible(info_panel_visible : bool):
	_world_param_info_panel_visible = info_panel_visible
	_world_param_info_panel_visibility_changed = true

var _world_param_edit_panel_visibility_changed := true
@export var _world_param_edit_panel_visible : bool = false:
	set = _set_world_param_edit_panel_visible
func _set_world_param_edit_panel_visible(edit_panel_visible : bool):
	_world_param_edit_panel_visible = edit_panel_visible
	_world_param_edit_panel_visibility_changed = true

var _world_param_deploy_world_changed := true
@export var _world_param_deploy_world : bool = true :
	set = _set_world_param_deploy_world
func _set_world_param_deploy_world(deploy_world : bool):
	_world_param_deploy_world = deploy_world
	_world_param_deploy_world_changed = true

@export_group("World In Editor", "_world_editor_param")

var _world_editor_param_depth_quad_changed := true
@export var _world_editor_param_depth_quad : int = 1:		# 3
	set = _set_world_editor_param_depth_quad
func _set_world_editor_param_depth_quad(depth_quad : int):
	if depth_quad >= 0 && depth_quad <= MAX_DEPTH_QUAD:
		_world_editor_param_depth_quad = depth_quad
		_world_editor_param_depth_quad_changed = true

var _world_editor_param_cache_quad_changed := true
@export var _world_editor_param_cache_quad : int = 0:		# 1
	set = _set_world_editor_param_cache_quad
func _set_world_editor_param_cache_quad(cache_quad : int):
	if cache_quad >= 0 && cache_quad <= MAX_CACHE_QUAD:
		_world_editor_param_cache_quad = cache_quad
		_world_editor_param_cache_quad_changed = true

var _world_editor_param_max_depth_quad_changed := true
@export var _world_editor_param_max_depth_quad : int = MAX_DEPTH_QUAD:		# 3
	set = _set_world_editor_param_max_depth_quad
func _set_world_editor_param_max_depth_quad(depth_quad : int):
	if depth_quad >= 0 && depth_quad <= MAX_DEPTH_QUAD:
		_world_editor_param_max_depth_quad = depth_quad
		_world_editor_param_max_depth_quad_changed = true

var _world_editor_param_info_panel_visibility_changed := true
@export var _world_editor_param_info_panel_visible : bool = false:
	set = _set_world_editor_param_info_panel_visible
func _set_world_editor_param_info_panel_visible(info_panel_visible : bool):
	_world_editor_param_info_panel_visible = info_panel_visible
	_world_editor_param_info_panel_visibility_changed = true

var _world_editor_param_edit_panel_visibility_changed := true
@export var _world_editor_param_edit_panel_visible : bool = false:
	set = _set_world_editor_param_edit_panel_visible
func _set_world_editor_param_edit_panel_visible(edit_panel_visible : bool):
	_world_editor_param_edit_panel_visible = edit_panel_visible
	_world_editor_param_edit_panel_visibility_changed = true

var _world_editor_param_deploy_world_changed := true
@export var _world_editor_param_deploy_world : bool = false :
	set = _set_world_editor_param_deploy_world
func _set_world_editor_param_deploy_world(deploy_world : bool):
	_world_editor_param_deploy_world = deploy_world
	_world_editor_param_deploy_world_changed = true

@export_group("Camera", "_camera_param")

var _camera_param_initial_pos_changed := true
@export var _camera_param_initial_pos : Vector3 = Vector3(0, 2200, 0):
	get = _get_camera_param_initial_pos, set = _set_camera_param_initial_pos
func _set_camera_param_initial_pos(initial_pos : Vector3):
	_camera_param_initial_pos = initial_pos
	_camera_param_initial_pos_changed = true
func _get_camera_param_initial_pos():
	return _camera_param_initial_pos

var _camera_param_initial_alt_forced_changed := true
@export var _camera_param_initial_alt_forced : float = 0:
	get = _get_camera_param_initial_alt_forced, set = _set_camera_param_initial_alt_forced
func _set_camera_param_initial_alt_forced(initial_alt_forced : float):
	_camera_param_initial_alt_forced = initial_alt_forced
	_camera_param_initial_alt_forced_changed = true
func _get_camera_param_initial_alt_forced() -> float:
	return _camera_param_initial_alt_forced

var _camera_param_initial_yaw_pitch_roll_deg_changed := true
@export var _camera_param_initial_yaw_pitch_roll_deg : Vector3 = Vector3(-139.0, -7.0, 0.0):
	get = _get_camera_param_initial_yaw_pitch_roll_deg, set = _set_camera_param_initial_yaw_pitch_roll_deg
func _set_camera_param_initial_yaw_pitch_roll_deg(initial_yaw_pitch_roll_deg : Vector3):
	_camera_param_initial_yaw_pitch_roll_deg = initial_yaw_pitch_roll_deg
	_camera_param_initial_yaw_pitch_roll_deg_changed = true
func _get_camera_param_initial_yaw_pitch_roll_deg():
	return _camera_param_initial_yaw_pitch_roll_deg

@export_group("Shader Params", "_shader_param")

var _shader_param_ground_roughness_scale_changed := true
@export_range(0.0, 1.0, 0.01) var _shader_param_roughness_scale : float = 1.0:
	set = _set_shader_param_ground_roughness_scale
func _set_shader_param_ground_roughness_scale(roughness_scale : float):
	_shader_param_roughness_scale = roughness_scale
	_shader_param_ground_roughness_scale_changed = true

var _shader_param_ground_normal_scale_changed := true
@export_range(1.0, 16.0, 0.1) var _shader_param_normal_scale : float = 1.0:
	set = _set_shader_param_ground_normal_scale
func _set_shader_param_ground_normal_scale(normal_scale : float):
	_shader_param_normal_scale = normal_scale
	_shader_param_ground_normal_scale_changed = true

#var _shader_param_ground_height_displ_changed := true
#@export_range(0.0, 5.0, 0.001) var _shader_param_height_displ : float = 0.0:
	#set = _set_shader_param_ground_height_displ
#func _set_shader_param_ground_height_displ(height_displ : float):
	#_shader_param_height_displ = height_displ
	#_shader_param_ground_height_displ_changed = true

var _shader_param_ground_ao_light_affect_changed := true
@export_range(0.0, 1.0, 0.01) var _shader_param_ao_light_affect : float = 0.3:
	set = _set_shader_param_ground_ao_light_affect
func _set_shader_param_ground_ao_light_affect(ao_light_affect : float):
	_shader_param_ao_light_affect = ao_light_affect
	_shader_param_ground_ao_light_affect_changed = true

var _shader_param_debug_ground_uv_scale_changed := true
@export var _shader_param_debug_ground_uv_scale : bool = false:	#150.0:
	set = _set_shader_debug_param_ground_uv_scale
func _set_shader_debug_param_ground_uv_scale(debug : bool):
	_shader_param_debug_ground_uv_scale = debug
	_shader_param_debug_ground_uv_scale_changed = true

var _shader_param_ground_uv_scale_changed := true
@export_range(1.0, 10.0, 0.01, "or_greater", "or_less") var _shader_param_ground_uv_scale : float = 1.0:	#150.0:
	set = _set_shader_param_ground_uv_scale
func _set_shader_param_ground_uv_scale(ground_uv_scale : float):
	_shader_param_ground_uv_scale = ground_uv_scale
	_shader_param_ground_uv_scale_changed = true

var _shader_param_depth_blending_changed := true
@export var _shader_param_depth_blending : bool = true:
	set = _set_shader_param_depth_blending
func _set_shader_param_depth_blending(depth_blending : bool):
	_shader_param_depth_blending = depth_blending
	_shader_param_depth_blending_changed = true

#var _shader_param_triplanar_changed := true
#@export var _shader_param_triplanar : bool = false:
#	set = _set_shader_param_triplanar
#func _set_shader_param_triplanar(triplanar : bool):
#	_shader_param_triplanar = triplanar
#	_shader_param_triplanar_changed = true

var _shader_param_tile_reduction_changed := true
@export var _shader_param_tile_reduction : bool = false:
	set = _set_shader_param_tile_reduction
func _set_shader_param_tile_reduction(tile_reduction : bool):
	_shader_param_tile_reduction = tile_reduction
	_shader_param_tile_reduction_changed = true

var _shader_param_colormap_opacity_changed := true
@export_range(0.1, 10.0, 0.1) var _shader_param_colormap_opacity : float = 1.0:
	set = _set_shader_param_colormap_opacity
func _set_shader_param_colormap_opacity(colormap_opacity : float):
	_shader_param_colormap_opacity = colormap_opacity
	_shader_param_colormap_opacity_changed = true

var _shader_param_debug_texture_overflow_changed := true
@export var _shader_param_debug_texture_overflow : bool = false:
	set = _set_shader_param_debug_texture_overflow
func _set_shader_param_debug_texture_overflow(debug_texture_overflow : bool):
	_shader_param_debug_texture_overflow = debug_texture_overflow
	_shader_param_debug_texture_overflow_changed = true

var _shader_param_texture_overflow_size_changed := true
@export_range(0.00, 1.0, 0.01, "or_greater", "or_less")  var _shader_param_texture_overflow_size : float = 0.3:
	set = _set_shader_param_texture_overflow_size
func _set_shader_param_texture_overflow_size(texture_overflow_size : float):
	_shader_param_texture_overflow_size = texture_overflow_size
	_shader_param_texture_overflow_size_changed = true
	
var _shader_param_splatmap_overflow_size_changed := true
@export_range(0.00, 1.0, 0.01, "or_greater", "or_less")  var _shader_param_splatmap_overflow_size : float = 0.2:
	set = _set_shader_param_splatmap_overflow_size
func _set_shader_param_splatmap_overflow_size(splatmap_overflow_size : float):
	_shader_param_splatmap_overflow_size = splatmap_overflow_size
	_shader_param_splatmap_overflow_size_changed = true

var _shader_param_force_elevation_0_changed := true
@export var _shader_param_force_elevation_0 : bool = false:
	set = _set_shader_param_force_elevation_0
func _set_shader_param_force_elevation_0(v : bool):
	_shader_param_force_elevation_0 = v
	_shader_param_force_elevation_0_changed = true

#var _shader_param_new_overflow_changed := true
#@export var _shader_param_new_overflow : bool = false:
	#set = _set_shader_param_new_overflow
#func _set_shader_param_new_overflow(v : bool):
	#_shader_param_new_overflow = v
	#_shader_param_new_overflow_changed = true

var _shader_param_debug_show_pieces_changed := true
@export var _shader_param_debug_show_pieces : bool = false:
	set = _set_shader_debug_param_show_pieces
func _set_shader_debug_param_show_pieces(show : bool):
	_shader_param_debug_show_pieces = show
	_shader_param_debug_show_pieces_changed = true

var _shader_param_debug_piece_size_changed := true
@export_range(50.0, 400.0, 1.0) var _shader_param_debug_piece_size : float = 200.0:
	set = _set_shader_debug_param_piece_size
func _set_shader_debug_param_piece_size(size : float):
	_shader_param_debug_piece_size = size
	_shader_param_debug_piece_size_changed = true

var _shader_param_debug_float0_changed := true
@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float0 : float = 1.0:
	set = _set_shader_debug_param_uv0
func _set_shader_debug_param_uv0(uv : float):
	_shader_param_debug_float0 = uv
	_shader_param_debug_float0_changed = true

#var _shader_param_debug_float1_changed := true
#@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float1 : float = 1.0:
	#set = _set_shader_debug_param_uv1
#func _set_shader_debug_param_uv1(uv : float):
	#_shader_param_debug_float1 = uv
	#_shader_param_debug_float1_changed = true
#
#var _shader_param_debug_float2_changed := true
#@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float2 : float = 1.0:
	#set = _set_shader_debug_param_uv2
#func _set_shader_debug_param_uv2(uv : float):
	#_shader_param_debug_float2 = uv
	#_shader_param_debug_float2_changed = true
#
#var _shader_param_debug_float3_changed := true
#@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float3 : float = 1.0:
	#set = _set_shader_debug_param_uv3
#func _set_shader_debug_param_uv3(uv : float):
	#_shader_param_debug_float3 = uv
	#_shader_param_debug_float3_changed = true
#
#var _shader_param_debug_float4_changed := true
#@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float4 : float = 1.0:
	#set = _set_shader_debug_param_uv4
#func _set_shader_debug_param_uv4(uv : float):
	#_shader_param_debug_float4 = uv
	#_shader_param_debug_float4_changed = true
#
#var _shader_param_debug_float5_changed := true
#@export_range(1.0, 300.0, 1.0) var _shader_param_debug_float5 : float = 1.0:
	#set = _set_shader_debug_param_uv5
#func _set_shader_debug_param_uv5(uv : float):
	#_shader_param_debug_float5 = uv
	#_shader_param_debug_float5_changed = true

var _shader_param_cam_alt_uv_threshold_changed := true
@export_range(1.0, 6000.0, 1.0) var _shader_param_cam_alt_uv_threshold : float = 800.0:
	set = _set_shader_cam_alt_uv_threshold
func _set_shader_cam_alt_uv_threshold(threshold : float):
	_shader_param_cam_alt_uv_threshold = threshold
	_shader_param_cam_alt_uv_threshold_changed = true

var _shader_param_cam_dist_uv_threshold_changed := true
@export_range(1.0, 10000.0, 1.0) var _shader_param_cam_dist_uv_threshold : float = 5000.0:
	set = _set_shader_cam_dist_uv_threshold
func _set_shader_cam_dist_uv_threshold(threshold : float):
	_shader_param_cam_dist_uv_threshold = threshold
	_shader_param_cam_dist_uv_threshold_changed = true

@export_group("", "")

func _init():
	_logger.debug("_init")
	name = tw_constants.tw_viewer_node_name
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_logger.debug("_ready")
	if !Engine.is_editor_hint():
		init_viewer()
	else:
		_set_world_editor_param_deploy_world(false)			# needed to uncheck deploy world in editor at startup
		_set_world_editor_param_edit_panel_visible(false)	# needed to uncheck edit panel visible in editor at startup
	_is_ready = true
	#log_debug("_ready done")
	
func init_viewer():
	log_debug("init_viewer")
	
	_exit_status = EXIT_STATUS_RUNNING
	_is_ready = true
	_quitting = false

	#if !Engine.is_editor_hint():
	#	get_tree().set_auto_accept_quit(false)
	
	if not Engine.is_editor_hint():
		_set_world_param_deploy_world(true)
	#else:
	#	_set_world_editor_param_deploy_world(false)		# eliminated to avoid undeploy on save project data action (CTRL-S)
	
	# everything done here has to be undone in _exit_tree
	
	# first time after adding this node to the scene we check if gdn_main exist
	# and if it does not exist it is added as child (at this point it is choosen the debug/release version)
	# if it exists we use that
	var gdn_main : Node = GDN_main()
	if gdn_main == null:
		gdn_main = GDN_TheWorld_MainNode.new()
		gdn_main.name = tw_constants.tw_gdn_main_node_name
		add_child(gdn_main)

	create_info_panel()

	init_gdn_viewer()
	if !get_tree().get_root().is_connected("size_changed", Callable(self, "resizing")):
		var e := get_tree().get_root().connect("size_changed", Callable(self, "resizing"))
		log_debug(str("connect 'size_changed' result=", e))
	set_notify_transform(true)

	_client_status = get_clientstatus()
	
	log_debug("init_viewer done")
	_is_initialized = true

func client_status() -> int:
	return _client_status

func get_world_camera() -> Camera3D:
	var gdn_viewver = GDN_viewer()
	if (gdn_viewver != null):
		return gdn_viewver.get_world_camera()
	else:
		return null

func _enter_tree():
	_logger.debug("_enter_tree")
	_plugin_tree_entered = true

func _exit_tree():
	if not _quitting:
		_logger.debug(str("_exit_tree _init_done=", _init_done, ", quitting=", _quitting))
	
	if _init_done:
		#_set_camera_param_initial_pos(_camera3d_current_pos_in_map)
		#_set_camera_param_initial_yaw_pitch_roll_deg(Vector3(rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.x), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.y), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.z)))
		
		#pre_deinit()
		#var can_deinit : bool = false
		#while(can_deinit == false):
		#	can_deinit = can_deinit()
		#deinit()
		#_set_world_editor_param_deploy_world(false)

		if _info_panel != null:
			_info_panel.queue_free()
			_info_panel = null

	_plugin_tree_entered = false

func _input(event):
	#if event is InputEventMouseButton:
	#	var gdn_viewer = GDN_viewer()
	#	if gdn_viewer != null:
	#		if (event.pressed && (event.button_index == MOUSE_BUTTON_WHEEL_DOWN || event.button_index == MOUSE_BUTTON_WHEEL_UP)):
	#			if (_mouse_inside_info_panel):
	#				if Engine.is_editor_hint():
	#					if (_editor_3d_overlay != null):
	#						_editor_3d_overlay.accept_event()
	#				else:
	#					get_viewport().set_input_as_handled()

	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey:
		if event.keycode == KEY_ALT:
			if event.is_pressed():
				_alt_pressed = true
			else:
				_alt_pressed = false
		if event.keycode == KEY_CTRL:
			if event.is_pressed():
				_ctrl_pressed = true
			else:
				_ctrl_pressed = false
		if event.keycode == KEY_SHIFT:
			if event.is_pressed():
				_shift_pressed = true
			else:
				_shift_pressed = false
				
		if event.is_pressed() && event.keycode == KEY_I && _alt_pressed:
			toggle_info_panel_visibility()

func init_world() -> void:
	log_debug("Initializing world...")
	log_debug(str("  Pos: ", _camera_param_initial_pos, ", YPR: ", _camera_param_initial_yaw_pitch_roll_deg))
	GDN_viewer().deploy_world(_camera_param_initial_pos.x, _camera_param_initial_pos.y, _camera_param_initial_pos.z, _camera_param_initial_alt_forced, _camera_param_initial_yaw_pitch_roll_deg.x, _camera_param_initial_yaw_pitch_roll_deg.y, _camera_param_initial_yaw_pitch_roll_deg.z, _initial_level, -1 , -1)
	#_camera_param_initial_yaw_pitch_roll_deg_changed = true
	log_debug("World initialization completed...")
	undeploy_request_logged = false

func deinit_world() -> void:
	if not undeploy_request_logged:
		log_debug("Sending undeploy world request...")
		undeploy_request_logged = true
		_set_camera_param_initial_pos(_camera3d_current_pos_in_map)
		_set_camera_param_initial_yaw_pitch_roll_deg(Vector3(rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.x), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.y), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.z)))
	GDN_viewer().undeploy_world()
	#log_debug("World de-initialization completed...")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#log_debug("_process")
	
	# debugric
	#if Engine.is_editor_hint():
	#	return
	
	#log_debug(str("_process: _exit_status=", _exit_status, " _client_status=", _client_status, " _world_editor_param_deploy_world_changed=", _world_editor_param_deploy_world_changed, " _world_editor_param_deploy_world=", _world_editor_param_deploy_world))
	
	var gdn_globals = GDN_globals()

	if _shader_param_debug_ground_uv_scale_changed && gdn_globals != null:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_player_debug_ground_uv_scale, _shader_param_debug_ground_uv_scale)
		_shader_param_debug_ground_uv_scale_changed = false

	if _shader_param_debug_texture_overflow_changed && gdn_globals != null:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_player_debug_texture_overflow, _shader_param_debug_texture_overflow)
		gdn_globals.set_debug_texture_overflow(_shader_param_debug_texture_overflow)
		_shader_param_debug_texture_overflow_changed = false

	if _shader_param_texture_overflow_size_changed && gdn_globals != null:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_player_texture_overflow_size, _shader_param_texture_overflow_size)
		gdn_globals.set_texture_overflow_size(_shader_param_texture_overflow_size)
		_shader_param_texture_overflow_size_changed = false

	if _shader_param_splatmap_overflow_size_changed && gdn_globals != null:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_player_splatmap_overflow_size, _shader_param_splatmap_overflow_size)
		gdn_globals.set_splatmap_overflow_size(_shader_param_splatmap_overflow_size)
		_shader_param_splatmap_overflow_size_changed = false

	if _exit_status == EXIT_STATUS_UNDEPLOYWORLD_REQUIRED:
		if _client_status >= tw_constants.clientstatus_world_deploy_in_progress:
			if _client_status < tw_constants.clientstatus_world_undeploy_in_progress:
				if (!_deinit_in_progress):
					log_debug(str("_process: EXIT_STATUS_UNDEPLOYWORLD_REQUIRED"))
					_set_world_editor_param_deploy_world(false)
					deinit_world()
					#_deinit_in_progress = true
			#else:
		else:
			_exit_status = EXIT_STATUS_PREDEINIT_REQUIRED
			
	if _exit_status == EXIT_STATUS_PREDEINIT_REQUIRED:
		pre_deinit()
		_exit_status = EXIT_STATUS_QUIT_REQUIRED
		return

	if _exit_status == EXIT_STATUS_QUIT_REQUIRED:
		if can_deinit():
			_is_ready = false
			deinit()
			if _info_panel != null:
				_info_panel.queue_free()
				_info_panel = null
			_exit_status = EXIT_STATUS_QUITTING
			force_app_to_quit()
		return

	var gdn_viewer = GDN_viewer()
	var gdn_main = GDN_main()
	
	if gdn_main != null && gdn_main.has_method("initialized"):
		if !_init_done && gdn_main.initialized():
			restore_init()
	
	if gdn_viewer == null or gdn_globals == null:
		return
	
	if _transform_changed:
		var t : Transform3D = global_transform
		var t1 : Transform3D = gdn_viewer.global_transform
		#gdn_viewer.global_transform = global_transform
		log_debug(str("_process: global transform changed: ", global_transform))
		_transform_changed = false
	
	if _visibility_changed:
		gdn_viewer.visible = is_visible_in_tree()
		log_debug(str("_process: visibility changed: ", is_visible_in_tree()))
		_visibility_changed = false

	if Engine.is_editor_hint():
		if _world_editor_param_depth_quad_changed:
			if gdn_viewer.has_method("set_depth_quad"):
				gdn_viewer.set_depth_quad(_world_editor_param_depth_quad)
				log_debug(str("depth quad: ", _world_editor_param_depth_quad))
			_world_editor_param_depth_quad_changed = false

		if _world_editor_param_cache_quad_changed:
			if gdn_viewer.has_method("set_cache_quad"):
				gdn_viewer.set_cache_quad(_world_editor_param_cache_quad)
				log_debug(str("cache quad: ", _world_editor_param_cache_quad))
			_world_editor_param_cache_quad_changed = false

		if _world_editor_param_max_depth_quad_changed:
			if gdn_viewer.has_method("set_max_depth_quad"):
				gdn_viewer.set_max_depth_quad(_world_editor_param_max_depth_quad)
				log_debug(str("max depth quad: ", _world_editor_param_max_depth_quad))
			_world_editor_param_max_depth_quad_changed = false

		if _world_editor_param_info_panel_visibility_changed:
			log_debug(str("DEBUG _info_panel=", _info_panel, " visible=", _world_editor_param_info_panel_visible))
			if _info_panel != null:
				_info_panel.visible = _world_editor_param_info_panel_visible
				gdn_viewer.set_info_panel_visible(_info_panel.visible)
				log_debug(str("DEBUG _info_panel_visible=", _info_panel.visible))
				_world_editor_param_info_panel_visibility_changed = false
			else:
				if not _world_editor_param_info_panel_visible:
					_world_editor_param_info_panel_visibility_changed = false

		if _world_editor_param_edit_panel_visibility_changed:
			if gdn_viewer.has_method("set_edit_mode"):
				gdn_viewer.set_edit_mode(_world_editor_param_edit_panel_visible)
			_world_editor_param_edit_panel_visibility_changed = false
		else:
			var edit_mode = gdn_viewer.is_edit_mode()
			if edit_mode != _world_editor_param_edit_panel_visible:
				_world_editor_param_edit_panel_visible = edit_mode
				_world_editor_param_edit_panel_visibility_changed = false
	else:
		if _world_param_depth_quad_changed:
			if gdn_viewer.has_method("set_depth_quad"):
				gdn_viewer.set_depth_quad(_world_param_depth_quad)
				log_debug(str("depth quad: ", _world_param_depth_quad))
			_world_param_depth_quad_changed = false

		if _world_param_cache_quad_changed:
			if gdn_viewer.has_method("set_cache_quad"):
				gdn_viewer.set_cache_quad(_world_param_cache_quad)
				log_debug(str("cache quad: ", _world_param_cache_quad))
			_world_param_cache_quad_changed = false

		if _world_param_max_depth_quad_changed:
			if gdn_viewer.has_method("set_max_depth_quad"):
				gdn_viewer.set_max_depth_quad(_world_param_max_depth_quad)
				log_debug(str("max depth quad: ", _world_param_max_depth_quad))
			_world_param_max_depth_quad_changed = false

		if _world_param_info_panel_visibility_changed:
			if _info_panel != null:
				_info_panel.visible = _world_param_info_panel_visible
				gdn_viewer.set_info_panel_visible(_info_panel.visible)
				#print(str("_info_panel_visible=", _info_panel.visible))
			_world_param_info_panel_visibility_changed = false
		
		if _world_param_edit_panel_visibility_changed:
			if gdn_viewer.has_method("set_edit_mode"):
				gdn_viewer.set_edit_mode(_world_param_edit_panel_visible)
			_world_param_edit_panel_visibility_changed = false
		else:
			var edit_mode = gdn_viewer.is_edit_mode()
			if edit_mode != _world_param_edit_panel_visible:
				_world_param_edit_panel_visible = edit_mode
				_world_param_edit_panel_visibility_changed = false

	if _shader_param_ground_roughness_scale_changed:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_ground_roughness_scale, _shader_param_roughness_scale)
		_shader_param_ground_roughness_scale_changed = false

	if _shader_param_ground_normal_scale_changed:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_ground_normal_scale, _shader_param_normal_scale)
		_shader_param_ground_normal_scale_changed = false

	#if _shader_param_ground_height_displ_changed:
		#RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_ground_height_displ, _shader_param_height_displ)
		#_shader_param_ground_height_displ_changed = false

	if _shader_param_ground_ao_light_affect_changed:
		RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_ground_ao_light_affect, _shader_param_ao_light_affect)
		_shader_param_ground_ao_light_affect_changed = false

	if gdn_viewer.has_method("set_shader_parameter"):
		
		if _shader_param_ground_uv_scale_changed:
			#var num_vertices_per_quadrant_size = GDN_globals().get_bitmap_resolution() + 1
			#var num_texture_tiles_min : float = floor(num_vertices_per_quadrant_size / _shader_param_ground_uv_scale)
			#var num_texture_tiles_max : float = num_texture_tiles_min + 1
			#var fractional = (num_vertices_per_quadrant_size / _shader_param_ground_uv_scale) - num_texture_tiles_min
			#if (fractional < 0.5):
			#	_shader_param_ground_uv_scale = num_vertices_per_quadrant_size / num_texture_tiles_min
			#else:
			#	_shader_param_ground_uv_scale = num_vertices_per_quadrant_size / num_texture_tiles_max
			gdn_viewer.set_shader_parameter("ground_uv_scale", _shader_param_ground_uv_scale)
			log_debug(str("set_shader_parameter ground_uv_scale=", _shader_param_ground_uv_scale))
			_shader_param_ground_uv_scale_changed = false

		if _shader_param_depth_blending_changed:
			gdn_viewer.set_shader_parameter("depth_blending", _shader_param_depth_blending)
			log_debug(str("set_shader_parameter depth_blending=", _shader_param_depth_blending))
			_shader_param_depth_blending_changed = false

		#if _shader_param_triplanar_changed:
		#	gdn_viewer.set_shader_parameter("triplanar", _shader_param_triplanar)
		#	log_debug(str("set_shader_parameter triplanar=", _shader_param_triplanar))
		#	_shader_param_triplanar_changed = false

		if _shader_param_tile_reduction_changed:
			gdn_viewer.set_shader_parameter("tile_reduction", _shader_param_tile_reduction)
			log_debug(str("set_shader_parameter tile_reduction=", _shader_param_tile_reduction))
			_shader_param_tile_reduction_changed = false

		if _shader_param_colormap_opacity_changed:
			gdn_viewer.set_shader_parameter("colormap_opacity", _shader_param_colormap_opacity)
			log_debug(str("set_shader_parameter colormap_opacity=", _shader_param_colormap_opacity))
			_shader_param_colormap_opacity_changed = false

		if _shader_param_force_elevation_0_changed:
			gdn_viewer.set_shader_parameter("force_elevation_0", _shader_param_force_elevation_0)
			log_debug(str("set_shader_parameter force_elevation_0=", _shader_param_force_elevation_0))
			_shader_param_force_elevation_0_changed = false

		#if _shader_param_new_overflow_changed:
			#RenderingServer.global_shader_parameter_set(tw_constants.global_shader_param_player_texture_new_overflow, _shader_param_new_overflow)
			#_shader_param_new_overflow_changed = false

		if _shader_param_debug_show_pieces_changed:
			RenderingServer.global_shader_parameter_set("gu_debug_view_pieces", _shader_param_debug_show_pieces)
			_shader_param_debug_show_pieces_changed = false

		if _shader_param_debug_piece_size_changed:
			RenderingServer.global_shader_parameter_set("gu_piece_size", _shader_param_debug_piece_size)
			_shader_param_debug_piece_size_changed = false

		if _shader_param_debug_float0_changed:
			RenderingServer.global_shader_parameter_set("gu_debug_float0", _shader_param_debug_float0)
			_shader_param_debug_float0_changed = false

		#if _shader_param_debug_float1_changed:
			#RenderingServer.global_shader_parameter_set("gu_debug_float1", _shader_param_debug_float1)
			#_shader_param_debug_float1_changed = false
#
		#if _shader_param_debug_float2_changed:
			#RenderingServer.global_shader_parameter_set("gu_debug_float2", _shader_param_debug_float2)
			#_shader_param_debug_float2_changed = false
#
		#if _shader_param_debug_float3_changed:
			#RenderingServer.global_shader_parameter_set("gu_debug_float3", _shader_param_debug_float3)
			#_shader_param_debug_float3_changed = false
#
		#if _shader_param_debug_float4_changed:
			#RenderingServer.global_shader_parameter_set("gu_debug_float4", _shader_param_debug_float4)
			#_shader_param_debug_float4_changed = false
#
		#if _shader_param_debug_float5_changed:
			#RenderingServer.global_shader_parameter_set("gu_debug_float5", _shader_param_debug_float5)
			#_shader_param_debug_float5_changed = false

		if _shader_param_cam_alt_uv_threshold_changed:
			RenderingServer.global_shader_parameter_set("gu_camera_altitude_uv_scale_threshold", _shader_param_cam_alt_uv_threshold)
			_shader_param_cam_alt_uv_threshold_changed = false

		if _shader_param_cam_dist_uv_threshold_changed:
			RenderingServer.global_shader_parameter_set("gu_camera_distance_uv_scale_threshold", _shader_param_cam_dist_uv_threshold)
			_shader_param_cam_dist_uv_threshold_changed = false

	if _edit_panel_visibility_changed:
		gdn_viewer.toggle_edit_mode()
		_edit_panel_visibility_changed = false

	var camera2d : Camera2D = gdn_viewer.get_map_camera()

	if _desidered_map_camera_zoom_factor_changed and camera2d != null and camera2d.initialized():
		_desidered_map_camera_zoom_factor_changed = false
		set_map_camera_zoom_factor(_desidered_map_camera_zoom_factor)
		
	if Engine.is_editor_hint():
		if _world_editor_param_deploy_world_changed:
			if _world_editor_param_deploy_world:
				if _client_status == tw_constants.clientstatus_session_initialized:
					init_world()
					_world_editor_param_deploy_world_changed = false
				elif _client_status == tw_constants.clientstatus_uninitialized:
					init_viewer()
				elif _client_status >= tw_constants.clientstatus_world_deploy_in_progress:
					_world_editor_param_deploy_world_changed = false
			else:
				# changed from tw_constants.clientstatus_world_deployed
				if _client_status >= tw_constants.clientstatus_world_deploy_in_progress \
				 && _client_status < tw_constants.clientstatus_world_undeploy_in_progress:
					log_debug(str("_process: _world_editor_param_deploy_world_changed"))
					deinit_world()
					_world_editor_param_deploy_world_changed = false
	else:
		if _world_param_deploy_world_changed:
			if _world_param_deploy_world:
				if _client_status == tw_constants.clientstatus_session_initialized:
					init_world()
					_world_param_deploy_world_changed = false
				elif _client_status >= tw_constants.clientstatus_world_deploy_in_progress:
					_world_param_deploy_world_changed = false
			else:
				if _client_status >= tw_constants.clientstatus_world_deployed && _client_status < tw_constants.clientstatus_world_undeploy_in_progress:
					deinit_world()
					_world_param_deploy_world_changed = false
		
	if _debug_mode_changed:
		set_debug_mode(_debug_mode)
		_debug_mode_changed = false
		
	if _loading_screen_changed:
		gdn_globals.set_loading_screen(_loading_screen)
		_loading_screen_changed = false
		
	if _full_world_deploy_changed:
		gdn_globals.set_loading_screen_exit_on_full_world_deploy(_full_world_deploy)

	if _camera_param_initial_pos_changed:
		if _client_status >= tw_constants.clientstatus_world_deploy_in_progress:
			var viewer_custom_camera = gdn_viewer.get_custom_camera()
			if (viewer_custom_camera != null):
				viewer_custom_camera.set_camera_world_pos(_camera_param_initial_pos)
			_camera_param_initial_pos_changed = false
	
	if _camera_param_initial_yaw_pitch_roll_deg_changed:
		if _client_status >= tw_constants.clientstatus_world_deploy_in_progress:
			var viewer_custom_camera = gdn_viewer.get_custom_camera()
			if (viewer_custom_camera != null):
				viewer_custom_camera.set_yaw(_camera_param_initial_yaw_pitch_roll_deg.x, false)
				viewer_custom_camera.set_pitch(_camera_param_initial_yaw_pitch_roll_deg.y, false)
				viewer_custom_camera.set_roll(_camera_param_initial_yaw_pitch_roll_deg.z, false)
				#log_debug(str("yaw_pitch_roll changed - YPR: ", _camera_param_initial_yaw_pitch_roll_deg))
			_camera_param_initial_yaw_pitch_roll_deg_changed = false
		
	if Engine.is_editor_hint():

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
	
	#print(gdn_viewer.has_method("get_world_camera"))
	if _info_panel != null && _info_panel.visible && gdn_viewer.has_method("get_world_camera") && not _quitting:
		var tot_element_to_initialize : int = GDN_globals().get_tot_element_to_initialize()
		var num_element_initialized : int = GDN_globals().get_num_element_initialized()
		_info_panel_status = "Status: " + tw_constants.status_to_string(_client_status) + " (" + str(num_element_initialized) + "/"+ str(tot_element_to_initialize) + ")" + "\n"
		var realSceneCamera : Camera3D = gdn_viewer.get_world_camera()
		var viewer_custom_camera = gdn_viewer.get_custom_camera()
		#var viewer_custom_camera = get_tree().get_first_node_in_group(tw_constants.custom_cameras_group)	# same as above
		var update_quads1_duration : int = gdn_viewer.get_update_quads1_duration()
		var update_quads2_duration : int = gdn_viewer.get_update_quads2_duration()
		var update_quads3_duration : int = gdn_viewer.get_update_quads3_duration()
		_hit_pos = gdn_viewer.get_mouse_hit_in_map()
		if gdn_viewer.map_mode():
			_delta_pos = Vector3(0, 0, 0)
		else:
			if Time.get_ticks_msec() - _last_check_delta_pos > 100:
				if _hit_pos != _prev_hit_pos:
					_delta_pos = _hit_pos - _prev_hit_pos
					_prev_hit_pos = _hit_pos
				_last_check_delta_pos = Time.get_ticks_msec()
		if !Engine.is_editor_hint() or Engine.is_editor_hint():
			_info_panel_draw_mode = "Draw mode: " +  gdn_viewer.get_debug_draw_mode() + "\n"
			_info_panel_num_locks = "Locks: " + str(gdn_viewer.get_num_process_not_owns_lock()) + " debug: " + str(gdn_viewer.get_debug_visibility()) + "\n"
			if viewer_custom_camera != null && viewer_custom_camera.has_method("get_yaw"):
				_info_panel_camera_degree_from_north = "  Deg. north: " + str(snapped(viewer_custom_camera.get_angle_from_north_degree(), 0.01)) + " Alt: " + str(snapped(viewer_custom_camera.get_camera_altitude_from_sea(), 0.01)) + " (" + str(snapped(viewer_custom_camera.get_camera_altitude_from_terrain(), 0.01)) + ")" + "\n"
				_info_panel_camera_yaw = "  Yaw: " + str(snapped(viewer_custom_camera.get_yaw(false), 0.01)) 
				_info_panel_camera_pitch = "  Pitch: " + str(snapped(viewer_custom_camera.get_pitch(false), 0.01))
				_info_panel_camera_roll = "  Roll: " + str(snapped(viewer_custom_camera.get_roll(false), 0.01)) + "\n"
		_info_panel_grid_origin = "Map origin: " + str(gdn_viewer.get_anchor_for_origin_shift().global_transform.origin) + "\n"
		_info_panel_render_process_durations_mcs = "Render process (mcs): " + str(gdn_viewer.get_process_duration()) + "\n"
		#+ " UQ " + String (update_quads1_duration + update_quads2_duration + update_quads3_duration) \
		#+ " (" + String(update_quads1_duration) \
		#+ " " + String(update_quads2_duration) \
		#+ " " + String(update_quads3_duration)\
		#+ ") UC " + String(viewer.get_update_chunks_duration()) \
		#+ " UM " + String(viewer.get_update_material_params_duration()) \
		####+ " RQ " + String(viewer.get_refresh_quads_duration()) \
		#+ " T " + String(viewer.get_mouse_track_hit_duration()) + "\n"
		if realSceneCamera != null && viewer_custom_camera != null:
			_camera3d_current_pos_in_map = viewer_custom_camera.get_camera_world_transform().origin
			_camera3d_current_pos = realSceneCamera.global_transform.origin
			var v : Vector3 = realSceneCamera.global_transform.basis.get_euler()
			_camera3d_current_yaw_pitch_roll_rad = Vector3(v.y, v.x, v.z)
			#_info_panel_camera_rot = "  YPR: " + str(rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.y), ", ", rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.x), ", ", rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.z)) + "\n"
			_info_panel_camera_pos = "  Pos: " + str(_camera3d_current_pos) + "\n"
			_info_panel_camera_pos_in_map = "  Pos in map: " + str(_camera3d_current_pos_in_map) + "\n"
			var camera_velocity : float = 0
			if (realSceneCamera.has_method("get_velocity")):
				camera_velocity = realSceneCamera.get_velocity()
			var camera_under_water := "S" if viewer_custom_camera.is_camera_under_water() else "N"
			_info_panel_camera_velocity = "  Velocity: " + str(snapped(camera_velocity, 0.1)) + "m/s " + str(snapped((camera_velocity * 60 * 60) / 1000, 0.1)) + "km/h" + " Delay: " + str(snapped((gdn_viewer.get_delay_degree()), 0.1)) + "\n"
			_info_panel_camera_und_water = " Under Water: " + camera_under_water
		if camera2d != null:
			var camera2d_pos_in_map : Vector2
			if camera2d.has_method("get_camera_world_transform"):
				camera2d_pos_in_map = camera2d.get_camera_world_transform().origin
			else:
				camera2d_pos_in_map = camera2d.global_transform.origin
			var zoom : float = 1
			if camera2d.has_method("get_zoom_factor"):
				zoom = camera2d.get_zoom_factor()
			_info_panel_camera2d_pos = "  Pos: " + str(camera2d.global_transform.origin) + " Zoom: " + str(snapped(zoom, 0.01)) + "\n"
			_info_panel_camera2d_pos_in_map = "  Pos in map: " + str(camera2d_pos_in_map)
		_info_map_quadrants = "Total: " + str(gdn_viewer.get_map_quadrant_num()) + " To show: " + str(gdn_viewer.get_to_show_map_quadrant_num()) + " Updating: " + str(gdn_viewer.get_updating_map_quadrant_num()) + "\n"
		_info_map_quadrant_overrides = "Overrides: " + str(gdn_viewer.get_map_quadrant_override_num()) + " Color ovr: " + str(gdn_viewer.get_map_quadrant_color_override_num()) + " Texture ovr: " + str(gdn_viewer.get_map_quadrant_texture_override_num()) + "\n"
		_info_map_texture_rects = "Texture Rects: " + str(gdn_viewer.get_map_quadrants_rect())
		var toEraseQuadrants : int = gdn_viewer.get_num_toerase_quadrant()
		var notInitializedQuadrants : int = gdn_viewer.get_num_quadrant_in_view() - gdn_viewer.get_num_initialized_quadrant()
		_info_label_num_quadrants = "  Total: " + str(gdn_viewer.get_num_initialized_quadrant(), ":", gdn_viewer.get_num_quadrant_in_view(), " (", gdn_viewer.get_num_quadrant_in_memory(),")") + " To Init: " + str(notInitializedQuadrants) + " To Erase: " + str(toEraseQuadrants) + "\n"
		var notInitializedVisibleQuadrants : int = gdn_viewer.get_num_visible_quadrant() - gdn_viewer.get_num_initialized_visible_quadrant()
		_info_label_num_visible_quadrants = "  Visible: " + str(gdn_viewer.get_num_initialized_visible_quadrant(), ":", gdn_viewer.get_num_visible_quadrant()) + " To Init: " + str(notInitializedVisibleQuadrants) + " Shader: " + str(gdn_viewer.get_num_need_shader_reset_quadrant()) + "/" + str(gdn_viewer.get_num_need_shader_update_quadrant()) + "\n"
		_info_label_num_empty_quadrants = "  Empty: " + str(gdn_viewer.get_num_empty_quadrant())
		_info_label_num_flushed_quadrants = "  Flushed: " + str(gdn_viewer.get_num_flushed_quadrant()) + "\n"
		_info_label_num_loading_quadrants = "  Loading: " + str(gdn_viewer.get_num_loading_quadrant())
		_info_label_num_reloading_quadrants = "  Reloading: " + str(gdn_viewer.get_num_reloading_quadrant()) + "\n"
		_info_label_num_with_collider = "  Collider: " + str(gdn_viewer.get_num_quadrant_with_enabled_collider()) + "/" + str(gdn_viewer.get_num_quadrant_with_collider()) + " (H " + str(gdn_viewer.get_num_quadrant_with_hires_collider()) + " / L " + str(gdn_viewer.get_num_quadrant_with_lowres_collider()) + ")"
		_info_panel_num_active_chunks = "  Active: " + str(gdn_viewer.get_num_active_chunks()) + " "
		_info_panel_num_chunk_splits = "  Splits: " + str(gdn_viewer.get_num_splits()) + " "
		_info_panel_num_chunk_joins = "  Joins: " + str(gdn_viewer.get_num_joins())
		_info_panel_hit_pos = "  Hit pos: " + str(gdn_viewer.get_mouse_hit_global()) + "\n"
		_info_panel_hit_pos_in_map = "  Hit pos in map: " + str(gdn_viewer.get_mouse_hit_in_map()) + "\n"
		_info_panel_hit_distance_from_camera = "  Hit pos dist from camera: " + str(gdn_viewer.get_mouse_hit_distance_from_camera()) + "\n"
		_info_panel_delta_pos = "  Delta pos: " + str(_delta_pos) + "\n"
		_info_panel_quad_hit_name = "  Quad name: " + gdn_viewer.get_mouse_quadrant_hit_name() + " " + gdn_viewer.get_mouse_quadrant_hit_tag() + "\n"
		_info_panel_quad_hit_pos = "  Quad pos: " + str(gdn_viewer.get_mouse_quadrant_hit_pos()) + " "
		_info_panel_quad_hit_size = "  size: " + str(gdn_viewer.get_mouse_quadrant_hit_size()) + "\n"
		_info_panel_chunk_hit_name = "  Chunk name: " + gdn_viewer.get_mouse_chunk_hit_name() + "\n"
		_info_panel_chunk_hit_pos = "  Chunk pos: " + str(gdn_viewer.get_mouse_chunk_hit_pos()) + " "
		_info_panel_chunk_hit_size = "  size: " + str(gdn_viewer.get_mouse_chunk_hit_size()) + "\n"
		_info_panel_chunk_hit_dist_from_camera = "  Chunk dist from camera: " + str(gdn_viewer.get_mouse_chunk_hit_dist_from_cam())
		if gdn_viewer.get_track_mouse_state():
			_info_panel_track_mouse_state = "on"
		else:
			_info_panel_track_mouse_state = "off"
		var projection : int = gdn_viewer.get_camera_projection_mode()
		if projection == 0:
			_info_panel_camera_projection = "Perspective"
		elif projection == 1:
			_info_panel_camera_projection = "Orthogonal"
		elif projection == 2:
			_info_panel_camera_projection = "Frustum"
		else:
			_info_panel_camera_projection = "Unknown"
		#_info_panel_info_camera = "  info: " + viewer.get_info_camera() + "\n"
			
		var mouse_pos : Vector2 = Vector2(0, 0)
		mouse_pos = get_viewport().get_mouse_position()
		if (_editor_3d_overlay != null):
			mouse_pos = _editor_3d_overlay.get_local_mouse_position()
		var div : int = 1024 * 1024 * 1024
		var mem = 0
		var gpu_mem = 0
		mem = Performance.get_monitor(Performance.MEMORY_STATIC) / div
		gpu_mem = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / div
		_info_panel_general_label.text = "FPS: " + str(Engine.get_frames_per_second()) \
		 + " Mem: " + str(snapped(mem, 0.01)) + " GB" \
		+ " GPU Mem: " + str(snapped(gpu_mem, 0.01)) + " GB" + "\n" \
			+ _info_panel_status \
			+ _info_panel_render_process_durations_mcs \
			+ _info_panel_draw_mode \
			+ _info_panel_num_locks \
			+ _info_panel_grid_origin \
			+ "Cursor pos in viewport: " + str(mouse_pos)
		
		_info_panel_camera3d_label.text = "Camera3D (World Mode): " + _info_panel_camera_projection + "\n" \
		+ _info_panel_camera_degree_from_north \
		+ _info_panel_camera_yaw \
		+ _info_panel_camera_pitch \
		+ _info_panel_camera_roll \
		+ _info_panel_info_camera \
		+ _info_panel_camera_rot \
		+ _info_panel_camera_pos \
		+ _info_panel_camera_pos_in_map \
		+ _info_panel_camera_velocity \
		+ _info_panel_camera_und_water
		
		_info_panel_camera2d_label.text = "Camera2D (Map Mode)\n" \
		+ _info_panel_camera2d_pos \
		+ _info_panel_camera2d_pos_in_map
		
		_info_panel_quadrants_label.text = "Quadrants\n" \
		+ _info_label_num_quadrants \
		+ _info_label_num_visible_quadrants \
		+ _info_label_num_empty_quadrants \
		+ _info_label_num_flushed_quadrants \
		+ _info_label_num_loading_quadrants \
		+ _info_label_num_reloading_quadrants \
		+ _info_label_num_with_collider
		
		_info_panel_chunks_label.text = "Chunks\n" \
		+ _info_panel_num_active_chunks \
		+ _info_panel_num_chunk_splits \
		+ _info_panel_num_chunk_joins
		
		_info_panel_map_quadrants_label.text = "Map Quadrants\n" \
		+ _info_map_quadrants \
		+ _info_map_quadrant_overrides \
		+ _info_map_texture_rects
		
		_info_panel_mouse_tracking_label.text = "Mouse tracking: " + _info_panel_track_mouse_state + "\n" \
		+ _info_panel_hit_pos \
		+ _info_panel_hit_pos_in_map \
		+ _info_panel_hit_distance_from_camera \
		+ _info_panel_delta_pos \
		+ _info_panel_quad_hit_name \
		+ _info_panel_quad_hit_pos \
		+ _info_panel_quad_hit_size \
		+ _info_panel_chunk_hit_name \
		+ _info_panel_chunk_hit_pos \
		+ _info_panel_chunk_hit_size \
		+ _info_panel_chunk_hit_dist_from_camera
	
	var wr = weakref(_info_panel_main_vboxcontainer);
	if (wr.get_ref()):
		var viewportSize : Vector2 = _gdn_viewer.get_viewport_size()
		var contentSize : Vector2 = _info_panel_main_vboxcontainer.get_rect().size
		var size : Vector2 = viewportSize
		if (contentSize != Vector2(0, 0)):
			if (viewportSize.y > contentSize.y):
				size.y = contentSize.y
			if (viewportSize.x > contentSize.x):
				size.x = contentSize.x
			if size.x > _info_panel_max_width:
				_info_panel_max_width = size.x
			else:
				size.x = _info_panel_max_width
			#size.x = 0	# ??
		_info_panel_scroll_container.custom_minimum_size = size
		
func _notification(_what):
	#log_debug(str("_notification: ", self.name, " ", self.get_path(), " ", _what))
	
	if (_what == Node3D.NOTIFICATION_TRANSFORM_CHANGED):
		log_debug("_notification: global transform changed")
		_transform_changed = true
	elif (_what == Node3D.NOTIFICATION_VISIBILITY_CHANGED):
		log_debug("_notification: visibility changed")
		_visibility_changed = true
	elif (_what == NOTIFICATION_PREDELETE):
		if not _quitting:
			log_debug("_notification: NOTIFICATION_PREDELETE - Destroy tw_viewer")
	elif (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		_quitting = true
		log_debug("_notification: NOTIFICATION_WM_CLOSE_REQUEST ")
		if Engine.is_editor_hint() || get_tree().is_auto_accept_quit():
			activate_shutdown()

func activate_shutdown():
	log_debug("activate_shutdown")
	if Engine.is_editor_hint():
		_is_ready = false	
		pre_deinit()
		var can_deinit : bool = false
		while(can_deinit == false):
			can_deinit = can_deinit()
		deinit()
		if _info_panel != null:
			_info_panel.queue_free()
			_info_panel = null
		_set_world_editor_param_deploy_world(false)
		_exit_status = EXIT_STATUS_QUITTING
	else:
		#_exit_status = EXIT_STATUS_PREDEINIT_REQUIRED
		_exit_status = EXIT_STATUS_UNDEPLOYWORLD_REQUIRED
		_deinit_in_progress = false

func resizing():
	if (_gdn_viewer != null && _gdn_viewer.has_method("viewport_size_changed")):
		_gdn_viewer.viewport_size_changed()
	#var size = get_viewport().size
	#if (_gdn_viewer != null && _gdn_viewer.has_method("get_viewport_size")):
	#	size = _gdn_viewer.get_viewport_size()
	#log_debug(str("Resizing: ",size ))
	set_size_info_panel()

func init_gdn_viewer() -> bool:
	log_debug("init")

	if _init_done:
		return false
	else:
		GDN_main().init(self, Engine.is_editor_hint())
		set_debug_mode(_debug_mode)

		GDN_globals().connect_to_server()
		log_debug(str("server connected"))

		var result
		if (!GDN_globals().is_connected("tw_status_changed", Callable(self, "_on_tw_status_changed"))):
			result = GDN_globals().connect("tw_status_changed", Callable(self, "_on_tw_status_changed"))
			log_debug(str("signal tw_status_changed connected (result=", result, ")"))

		printTerrainDimensions()

		var gdn_viewer = GDN_viewer()
		if gdn_viewer == null:
			log_debug("GDN_viewer null")
		else:
			gdn_viewer.global_transform = global_transform
			gdn_viewer.visible = is_visible_in_tree()
			log_debug("global_transform changed")
			set_shader_parameters()
			if (!gdn_viewer.is_connected("tw_quadrant_selected_for_edit", Callable(self, "_on_tw_quadrant_selected_for_edit"))):
				result = gdn_viewer.connect("tw_quadrant_selected_for_edit", Callable(self, "_on_tw_quadrant_selected_for_edit"))
				log_debug(str("signal tw_quadrant_selected_for_edit connected (result=", result, ")"))

		_init_done = true
		return true

func set_shader_parameters() -> void:
	_shader_param_ground_roughness_scale_changed = true
	_shader_param_ground_normal_scale_changed = true
	#_shader_param_ground_height_displ_changed = true
	_shader_param_ground_ao_light_affect_changed = true
	_shader_param_debug_ground_uv_scale_changed = true
	_shader_param_ground_uv_scale_changed = true
	_shader_param_depth_blending_changed = true
	#_shader_param_triplanar_changed = true
	_shader_param_tile_reduction_changed = true
	_shader_param_colormap_opacity_changed = true
	_shader_param_debug_texture_overflow_changed = true
	_shader_param_texture_overflow_size_changed = true
	_shader_param_splatmap_overflow_size_changed = true
	#_shader_param_new_overflow_changed = true
	_shader_param_force_elevation_0_changed = true
	_shader_param_debug_show_pieces_changed = true
	_shader_param_debug_piece_size_changed = true
	_shader_param_debug_float0_changed = true
	#_shader_param_debug_float1_changed = true
	#_shader_param_debug_float2_changed = true
	#_shader_param_debug_float3_changed = true
	#_shader_param_debug_float4_changed = true
	#_shader_param_debug_float5_changed = true
	_shader_param_cam_alt_uv_threshold_changed = true
	_shader_param_cam_dist_uv_threshold_changed = true

func pre_deinit():
	log_debug("pre_deinit")
	if GDN_main() == null:
		return
	GDN_main().pre_deinit()
	log_debug("Pre deinit completed...")

func can_deinit() -> bool:
	#log_debug("can_deinit")
	if GDN_main() == null:
		return true
	var can : bool = GDN_main().can_deinit()
	#log_debug(str("can_deinit=", can))
	return can

func deinit():
	log_debug(str("deinit _init_done=", _init_done))
	if _init_done:
		var gdn_viewer = GDN_viewer()
		if gdn_viewer != null:
			gdn_viewer.disconnect("tw_quadrant_selected_for_edit", Callable(self, "_on_tw_quadrant_selected_for_edit"))
			log_debug(str("signal tw_quadrant_selected_for_edit disconnected"))
		#GDN_globals().disconnect("tw_status_changed", Callable(self, "_on_tw_status_changed"))
		#log_debug(str("signal tw_status_changed disconnected"))
		GDN_globals().disconnect_from_server()
		GDN_main().deinit()
		_init_done = false
		log_debug("Deinit completed...")

func set_editor_3d_overlay(overlay : Control):
	#log_debug("set_editor_3d_overlay")
	_editor_3d_overlay = overlay
	if !_editor_3d_overlay.is_connected("resized", Callable(self, "resizing")):
		var e := _editor_3d_overlay.connect("resized", Callable(self, "resizing"))
		log_debug(str("connected _editor_3d_overlay resized signal (result=", e, ")"))
	GDN_viewer().set_editor_3d_overlay(overlay)

#func set_editor_interface(editor_interface : EditorInterface):
func set_editor_interface(editor_interface):
	_editor_interface = editor_interface
	GDN_viewer().set_editor_interface(editor_interface)

func set_world_editor_camera(camera : Camera3D):
	var gdn_viewer = GDN_viewer()
	if (gdn_viewer != null && gdn_viewer.has_method("set_world_editor_camera")):
		gdn_viewer.set_world_editor_camera(camera)
	_editor_camera = camera

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	#var status : String = tw_constants.status_to_string(new_client_status)
	var old_client_status_str : String = tw_constants.status_to_string(old_client_status)
	var new_client_status_str : String = tw_constants.status_to_string(new_client_status)
	_client_status = new_client_status
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))
	if (_client_status == tw_constants.clientstatus_session_initialized):
		set_shader_parameters()

func _on_tw_quadrant_selected_for_edit(selected : bool) -> void:
	return
	if (!selected):
		if _debug_sprite != null:
			_debug_sprite.queue_free()
			_debug_sprite = null
			return
	
	if (_debug_sprite == null):
		_debug_sprite = Sprite2D.new()
		add_child(_debug_sprite)
	
	var subviewport = SubViewport.new()
	add_child(subviewport)
	
	var shaderMaterial = ShaderMaterial.new()
	#shaderMaterial.shader = load("res://addons/twviewer/tools/shaders/height2normal.gdshader")
	shaderMaterial.shader = load("res://addons/twviewer/tools/shaders/universe.gdshader")

	var colorRect = ColorRect.new()
	subviewport.add_child(colorRect)
	colorRect.set_size(subviewport.size)
	colorRect.set_anchors_preset(Control.PRESET_FULL_RECT)
	colorRect.material = shaderMaterial
	
	_debug_sprite.texture = subviewport.get_texture()

func find_node_by_name(node_name : String) -> Node:
	if Engine.is_editor_hint():
		var scene : SceneTree = null
		#if _plugin_tree_entered:
		scene = get_tree()
		if scene == null:
			return null
		var node : Node = get_tree().get_edited_scene_root().find_child(node_name, true, false)
		return node
	else:
		var scene : SceneTree = null
		if _plugin_tree_entered:
			scene = get_tree()
		if scene == null:
			return null
		var node : Node = get_tree().get_root().find_child(node_name, true, false)
		return node
	
func GDN_main():
	if _gdn_main_instance == null:
		_gdn_main_instance = find_node_by_name(tw_constants.tw_gdn_main_node_name)
	if _gdn_main_instance == null && _gdn_main_instance_errmsg:
		_gdn_main_instance_errmsg = false
		log_debug(str("_gdn_main_instance ", _gdn_main_instance, ", probably it is not still ready"))
		_gdn_main_instance_errmsg = true
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

func get_self() -> Node3D:
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
	#if !globals.has_method("set_debug_enabled"):
	#	print("GDN_globals() does not have method set_debug_enabled")
	#	return
	#globals.set_debug_enabled(debug_enabled)
	#log_debug(str("debug mode: ", debug_mode, " ", ("enabled" if debug_mode > 0 else "disabled")))
	if !globals.has_method("set_debug_level"):
		print("GDN_globals() does not have method set_debug_level")
		return
	globals.set_debug_level(debug_mode)
	log_debug(str("debug mode: ", debug_mode))

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

func get_map_camera_zoom_factor() -> float:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return tw_constants.map_camera_initial_zoom_factor
		
	var camera2d : Camera2D = gdn_viewer.get_map_camera()
	if camera2d == null:
		return tw_constants.map_camera_initial_zoom_factor
	
	var zoom : float = camera2d.get_zoom_factor()
	
	return zoom
	
func set_map_camera_zoom_factor(zoom : float) -> void:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return
		
	var camera2d : Camera2D = gdn_viewer.get_map_camera()
	if camera2d == null:
		return
	
	camera2d.set_zoom_factor(zoom)

func set_desidered_map_camera_zoom_factor(zoom : float) -> void:
	_desidered_map_camera_zoom_factor = zoom
	_desidered_map_camera_zoom_factor_changed = true

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
		var s = str("lod (",lod,") - Num chunks per quadrant side = ",chunks," - Grid step in WUs = ",grid_step," - Num vertices per side = ",verticesPerSide," + 1 - Size of the side in WUs = ",verticesPerSide * grid_step)
		log_debug(s)

func get_chunks_per_bitmap_side(lod : int) -> int:
	return GDN_globals().get_chunks_per_bitmap_side(lod)

func delete_children():
	for n in get_children():
		n.owner = null
		remove_child(n)
		n.queue_free()

func log_debug(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)
	
func debug_print(context: String, text : String, godot_print : bool):
	#if Engine.editor_hint:
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("debug_print"):
			gdn_globals.debug_print(str(context,": ", text), godot_print)

func log_info(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)
	
func info_print(context: String, text : String, godot_print : bool):
	#if Engine.editor_hint:
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("info_print"):
			gdn_globals.info_print(str(context,": ", text), godot_print)

func log_error(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)
	
func error_print(context: String, text : String, godot_print : bool):
	#if Engine.is_editor_hint():
	#	return
	var gdn_globals = GDN_globals()
	if gdn_globals != null:
		if gdn_globals.has_method("error_print"):
			gdn_globals.error_print(str(context,": ", text), godot_print)

func toggle_info_panel_visibility():
	if Engine.is_editor_hint():
		_world_editor_param_info_panel_visible = !_world_editor_param_info_panel_visible
		_world_editor_param_info_panel_visibility_changed = true
	else:
		_world_param_info_panel_visible = !_world_param_info_panel_visible
		_world_param_info_panel_visibility_changed = true

func toggle_track_mouse():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null:
		gdn_viewer.toggle_track_mouse()

func toggle_edit_mode():
	_edit_panel_visibility_changed = true

func toggle_quadrant_selected():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null:
		gdn_viewer.toggle_quadrant_selected()

func toggle_debug_visibility():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null && gdn_viewer.has_method("toggle_debug_visibility"):
		gdn_viewer.toggle_debug_visibility()

func rotate_chunk_debug_mode():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null && gdn_viewer.has_method("rotate_chunk_debug_mode"):
		gdn_viewer.rotate_chunk_debug_mode()

func rotate_drawing_mode():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null && gdn_viewer.has_method("rotate_drawing_mode"):
		gdn_viewer.rotate_drawing_mode()

func destroy_info_panel():
	var info_panel = find_node_by_name("InfoPanel")
	if info_panel != null:
		_logger.debug(str("InfoPanel found, removing it ..."))
		info_panel.name = "_InfoPanel"
		var parent = info_panel.get_parent()
		if parent != null:
			parent.remove_child(info_panel)
		info_panel.queue_free()

func create_info_panel():
	var label : Label
	var hseparator : HSeparator
	var vseparator : VSeparator

	_logger.debug("Creating InfoPanel ...")
	
	clear_info_panel_closing_labels()
	
	if _info_panel != null:
		remove_info_panel()
	
	#_info_panel = PanelContainer.new()
	_info_panel = tw_info_container.new()
	_info_panel.connect("mouse_entered", Callable(self, "info_panel_mouse_entered"))
	_info_panel.connect("mouse_exited", Callable(self, "info_panel_mouse_exited"))
	#_info_panel = Control.new()
	#_info_panel = Panel.new()
	_info_panel.name = "InfoPanel"
	log_debug(str("_info_panel:", _info_panel, " ", _info_panel.name))
	#add_child(_info_panel)
	get_tree().get_root().add_child(_info_panel)
	if _world_editor_param_info_panel_visible:
		_info_panel.visible = true
	else:
		_info_panel.visible = false
	_world_param_info_panel_visibility_changed = true
	_info_panel.self_modulate = Color(1, 1, 1, 0.5)
	
	_info_panel_scroll_container = ScrollContainer.new()
	var v_scroll_bar := _info_panel_scroll_container.get_v_scroll_bar()
	v_scroll_bar.connect("mouse_entered", Callable(self, "info_panel_mouse_entered"))
	v_scroll_bar.connect("mouse_exited", Callable(self, "info_panel_mouse_exited"))
	
	_info_panel_main_vboxcontainer = VBoxContainer.new()
	_info_panel_main_vboxcontainer.name = "Info"

	if Engine.is_editor_hint():
		var panel = TabContainer.new()
		_info_panel.add_child(panel)
		panel.self_modulate = Color(1, 1, 1, 0.5)
		#panel.name = "Info"
		#panel.add_child(_info_panel_main_vboxcontainer)
		panel.add_child(_info_panel_scroll_container)
		_info_panel_scroll_container.name = "Info"
	else:
		#_info_panel.add_child(_info_panel_main_vboxcontainer)
		_info_panel.add_child(_info_panel_scroll_container)
	
	_info_panel_scroll_container.add_child(_info_panel_main_vboxcontainer)
		
	#_info_panel_main_vboxcontainer.self_modulate = Color(1, 1, 1, 0.5)
	#var i : int = _info_panel_main_vboxcontainer.get_constant("hseparation=")
	#print(str("hseparation", i))
	#i = _info_panel_main_vboxcontainer.get_constant("vseparation=")
	#print(str("vseparation", i))
	
	_info_panel_general_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_camera3d_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_camera2d_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_quadrants_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_chunks_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_map_quadrants_label = add_info_panel_empty_line()
	add_info_panel_separator()
	_info_panel_mouse_tracking_label = add_info_panel_empty_line()
	
	for idx in _info_panel_num_closing_labels:
		_info_panel_closing_labels.append(add_info_panel_empty_line())
		_info_panel_closing_labels[idx].text = ""
	#label = add_info_panel_empty_line()
	#label.text = " "
	#label = add_info_panel_empty_line()
	#label.text = " "
	#label = add_info_panel_empty_line()
	#label.text = " "
	
	set_size_info_panel()
	
	#apply_dpi_scale(_info_panel, 0.5)
	
	_info_panel_added_to_editor_overlay = false
	
func remove_info_panel():
	if _info_panel != null:
		_logger.debug("Removing InfoPanel ...")
		_info_panel.name = "_InfoPanel"
		var parent = _info_panel.get_parent()
		if parent != null:
			parent.remove_child(_info_panel)
		_info_panel.queue_free()
		_info_panel = null

func info_panel_mouse_entered() -> void:
	_mouse_inside_info_panel = true
	var viewer = GDN_viewer()
	if viewer != null:
		viewer.pause_mouse_movement()

func info_panel_mouse_exited() -> void:
	_mouse_inside_info_panel = false
	var viewer = GDN_viewer()
	if viewer != null:
		viewer.resume_mouse_movement()
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

func clear_info_panel_closing_labels() -> void:
	for idx in _info_panel_closing_labels.size():
		if (is_instance_valid(_info_panel_closing_labels[idx])):
			var parent : Node = _info_panel_closing_labels[idx].get_parent()
			if parent != null:
				parent.remove_child(_info_panel_closing_labels[idx])
	_info_panel_closing_labels.clear()

func add_info_panel_external_line(text : String, indent : int) -> int:
	clear_info_panel_closing_labels()
	
	if _info_panel_external_labels.size() == 0:
		add_info_panel_separator()

	var _text : String = ""
	for i in indent:
		_text += "  "
	_text += text
	var label_index = _info_panel_external_labels.size()
	var hboxcontainer := HBoxContainer.new()
	_info_panel_main_vboxcontainer.add_child(hboxcontainer)
	if _text.length() > 0:
		var label := Label.new()
		hboxcontainer.add_child(label)
		label.text = _text
	var label = Label.new()
	hboxcontainer.add_child(label)
	_info_panel_external_labels.append(label)

	for idx in _info_panel_num_closing_labels:
		_info_panel_closing_labels.append(add_info_panel_empty_line())
		_info_panel_closing_labels[idx].text = ""

	return label_index
	
func set_info_panel_external_value(text : String, index : int):
	if _info_panel_external_labels.size() > index:
		_info_panel_external_labels[index].text = text

func set_size_info_panel():
	if Engine.is_editor_hint():
		_info_panel.offset_top = 40
	else:
		_info_panel.anchor_left = 0
		_info_panel.custom_minimum_size = Vector2(360, 0)
	
func is_ready() -> bool:
	return _is_ready

func is_initialized() -> bool:
	return _is_initialized

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
		if node is SubViewport:
			continue
		if node is Control:
			if node.custom_minimum_size != Vector2(0, 0):
				node.custom_minimum_size *= dpi_scale
			var parent = node.get_parent()
			if parent != null:
				if not (parent is Container):
					node.offset_bottom *= dpi_scale
					node.offset_left *= dpi_scale
					node.offset_top *= dpi_scale
					node.offset_right *= dpi_scale
		for i in node.get_child_count():
			to_process.append(node.get_child(i))

func _apply_changes():
	_logger.debug("_apply_changes")
	_logger.debug(str("_apply_changes: _init_done=", _init_done, " _info_panel=", _info_panel))
	
	print_variables_to_restore()
	
	_set_camera_param_initial_pos(_camera3d_current_pos_in_map)
	_set_camera_param_initial_yaw_pitch_roll_deg(Vector3(rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.x), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.y), rad_to_deg(_camera3d_current_yaw_pitch_roll_rad.z)))
	
	log_debug(str("_apply_changes done - Pos: ", _camera_param_initial_pos, ", YPR: ", _camera_param_initial_yaw_pitch_roll_deg))

	#remove_info_panel()
	#_init_done = false	# force restore_init to be executed
	#_info_panel_added_to_editor_overlay = false	# force _info_panel to be added to overlay
	#_info_panel_visibility_changed = true # force to adjust _info_panel visibility

func force_app_to_quit() -> void:
	get_viewport().set_input_as_handled()
	get_tree().quit()

func restore_init():
	_logger.debug("restore_init")
	
	var gdn_main = GDN_main()
	if gdn_main == null || !gdn_main.has_method("initialized"):
		return
	
	_init_done = gdn_main.initialized()
	var gdn_globals = GDN_globals()
	var client_status : int = get_clientstatus()
	var gdn_viewer = GDN_viewer()
	_exit_status = EXIT_STATUS_RUNNING
	_plugin_tree_entered = true
	_is_ready = true
	create_info_panel()
	
	print_variables_to_restore()

func dump_required():
	var gdn_viewer = GDN_viewer()
	if gdn_viewer != null && gdn_viewer.has_method("dump_required"):
		gdn_viewer.dump_required()


func print_variables_to_restore():
	return
	#print(str("_logger=", _logger))
	_logger.debug(str("_gdn_main_instance=", _gdn_main_instance))
	_logger.debug(str("_gdn_globals=", _gdn_globals))
	_logger.debug(str("_gdn_viewer=", _gdn_viewer))
	_logger.debug(str("_init_done=", _init_done))
	_logger.debug(str("_editor_interface=", _editor_interface))
	_logger.debug(str("_editor_camera=", _editor_camera))
	_logger.debug(str("_editor_3d_overlay=", _editor_3d_overlay))
	_logger.debug(str("_exit_status=", _exit_status))
	_logger.debug(str("_plugin_tree_entered=", _plugin_tree_entered))
	_logger.debug(str("_is_ready=", _is_ready))
	_logger.debug(str("_info_panel=", _info_panel))
	_logger.debug(str("_info_panel_main_vboxcontainer=", _info_panel_main_vboxcontainer))
	_logger.debug(str("_info_panel_general_label=", _info_panel_general_label))
	_logger.debug(str("_info_panel_camera3d_label=", _info_panel_camera3d_label))
	_logger.debug(str("_info_panel_camera2d_label=", _info_panel_camera2d_label))
	_logger.debug(str("_info_panel_quadrants_label=", _info_panel_quadrants_label))
	_logger.debug(str("_info_panel_chunks_label=", _info_panel_chunks_label))
	_logger.debug(str("_info_panel_map_quadrants_label=", _info_panel_map_quadrants_label))
	_logger.debug(str("_info_panel_mouse_tracking_label=", _info_panel_mouse_tracking_label))
	
func get_loading_progress() -> float:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return -1
	return gdn_viewer.get_loading_progress()

func get_num_quadrant_in_view() -> int:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return -1
	return gdn_viewer.get_num_quadrant_in_view()
	
func get_max_num_quadrant() -> int:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return -1
	return gdn_viewer.get_max_num_quadrant()

func get_min_num_quadrant() -> int:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return -1
	return gdn_viewer.get_min_num_quadrant()

func get_num_initialized_quadrant() -> int:
	var gdn_viewer = GDN_viewer()
	if gdn_viewer == null:
		return -1
	return gdn_viewer.get_num_initialized_quadrant()

func loading_screen() -> bool:
	return _loading_screen

func full_world_deploy() -> bool:
	return _full_world_deploy

func save_current_camera_position(viewpoint : int) -> void:
	var gdn_viewer = GDN_viewer()
	var gdn_globals = GDN_globals()
	
	var _build : String = ""
	if Globals.strict_to_build_mode:
		_build = "_debug" if (gdn_globals.debug_build()) else "_release"

	#_logger.debug(str(0, " "))
	var _config_file_name : String = gdn_globals.get_config_filename(0)
	if gdn_viewer == null or gdn_globals == null or _config_file_name == "":
		return
	#_logger.debug(str(1, " ", _config_file_name))
	var viewer_custom_camera = gdn_viewer.get_custom_camera()
	if viewer_custom_camera != null:
		#_logger.debug(str(2, " "))
		var camera_ypr : Vector3
		camera_ypr.x = viewer_custom_camera.get_yaw(false)
		camera_ypr.y = viewer_custom_camera.get_pitch(false)
		camera_ypr.z = viewer_custom_camera.get_roll(false)
		var camera_pos : Vector3 = viewer_custom_camera.get_camera_world_transform().origin
		var param_key_camera_pos := ""
		var param_key_camera_ypr := ""
		if viewpoint == -1:
			param_key_camera_pos = tw_constants.param_key_initial_camera_pos
			param_key_camera_ypr = tw_constants.param_key_initial_camera_ypr
		else:
			param_key_camera_pos = tw_constants.param_key_viewpoint_camera_pos + str(viewpoint)
			param_key_camera_ypr = tw_constants.param_key_viewpoint_camera_ypr + str(viewpoint)
		var _config := ConfigFile.new()
		var _err = _config.load(_config_file_name)
		#_logger.debug(str(3, " ", _err))

		_config.set_value(tw_constants.param_group_camera, param_key_camera_pos, camera_pos)
		_config.set_value(tw_constants.param_group_camera, param_key_camera_ypr, camera_ypr)
		_config.set_value(tw_constants.param_group_camera, param_key_camera_pos + _build, camera_pos)
		_config.set_value(tw_constants.param_group_camera, param_key_camera_ypr + _build, camera_ypr)
		print("tw_viewer.save_current_camera_position _build=" + _build)
			
		_config.save(_config_file_name)

func load_camera_position(viewpoint : int) -> void:
	var gdn_viewer = GDN_viewer()
	var gdn_globals = GDN_globals()
	var _config_file_name : String = gdn_globals.get_config_filename(0)
	if gdn_viewer == null or gdn_globals == null or _config_file_name == "":
		return
	#_logger.debug(str(1, " ", _config_file_name))
	var param_key_camera_pos := ""
	var param_key_camera_ypr := ""

	var _build : String = ""
	if Globals.strict_to_build_mode:
		_build = "_debug" if (gdn_globals.debug_build()) else "_release"
	print("tw_viewer.load_camera_position _build=" + _build)

	if viewpoint == -1:
		param_key_camera_pos = tw_constants.param_key_initial_camera_pos
		param_key_camera_ypr = tw_constants.param_key_initial_camera_ypr
	else:
		param_key_camera_pos = tw_constants.param_key_viewpoint_camera_pos + str(viewpoint)
		param_key_camera_ypr = tw_constants.param_key_viewpoint_camera_ypr + str(viewpoint)
	
	var _config := ConfigFile.new()
	var _err = _config.load(_config_file_name)
	#_logger.debug(str(2, " ", _err))
	var camera_position_in_map : Variant = _config.get_value(tw_constants.param_group_camera, param_key_camera_pos + _build)
	var camera_ypr_in_map : Variant = _config.get_value(tw_constants.param_group_camera, param_key_camera_ypr + _build)
	_logger.debug(str(3, " ", param_key_camera_pos + _build, "=", camera_position_in_map, " ", param_key_camera_ypr + _build, "=",camera_ypr_in_map))

	if camera_position_in_map == null or camera_ypr_in_map == null:
		camera_position_in_map = _config.get_value(tw_constants.param_group_camera, param_key_camera_pos)
		camera_ypr_in_map = _config.get_value(tw_constants.param_group_camera, param_key_camera_ypr)
		_logger.debug(str(3, " ", param_key_camera_pos, "=", camera_position_in_map, " ", param_key_camera_ypr, "=",camera_ypr_in_map))

	if camera_position_in_map != null and camera_ypr_in_map != null:
		_set_camera_param_initial_pos(camera_position_in_map)
		_set_camera_param_initial_yaw_pitch_roll_deg(camera_ypr_in_map)
