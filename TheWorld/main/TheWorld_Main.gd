extends Node3D

var _debug_window_active : bool = false
var _world_entered : bool = false

var tw_const = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("res://addons/twviewer/util/logger.gd")
var _logger = HT_Logger.get_for(self)

#var debug_running_game_global = preload("res://addons/debug_running_game/debug_running_game_global.gd")

var _config_file_name : String = ""
var _config := ConfigFile.new()

var _viewpoint_to_save : int = -1
var _viewpoint_to_load : int = -1

#var _initialCameraDistanceFromTerrain : float = 300

var _fullscreen := false

var _initial_player_pos_in_world : Variant = null
var _initial_player_basis_in_world : Variant = null
var _initial_camera_position_in_world : Variant = null
#var initialViewerPoFs := Vector3(0, 2200, 0)ww
#var initialCameraAltitudeForced = 0
#var initialYawPitchRoll := Vector3(-139, -7, 0)
#var initialViewerPos := Vector3(872, 1463, -3742)
#var initialCameraAltitudeForced = 0
#var initialYawPitchRoll := Vector3(-0.238, -0.098, 0)

var _saved_time_to_fade_message = 0

var _window_mode = Window.MODE_MAXIMIZED if (true) else Window.MODE_WINDOWED
const initialLevel := 0
#var init_world_thread : Thread
var world_initialized : bool = false
var test_action_enabled : bool = false
var prev_test_action_enabled : bool = false
var process_test_action : bool = false
var collider_up_pressed : bool = false
var collider_down_pressed : bool = false
var collider_left_pressed : bool = false
var collider_right_pressed : bool = false
var collider_upaltitude_pressed : bool = false
var collider_downaltitude_pressed : bool = false
var collider_mesh_up_pressed : bool = false
var collider_mesh_down_pressed : bool = false
var collider_mesh_left_pressed : bool = false
var collider_mesh_right_pressed : bool = false
var collider_mesh_upaltitude_pressed : bool = false
var collider_mesh_downaltitude_pressed : bool = false
#var scene_initialized : bool = false
var post_world_deploy_initialized : bool = false
var fps := 0.0
var chunk_grid_global_pos : Vector3
#var active_camera_global_rot : Vector3
var active_camera_global_rot : String
var degree_from_north : float
var active_camera_global_pos : Vector3
var num_splits : int
var num_joins : int
var num_quadrant : String
var num_visible_quadrant : String
var num_empty_quadrant : String
var num_flushed_quadrant : String
var num_active_chunks : int
var process_durations_mcs : String
var num_process_locked : int
var _client_status_str : String
var _client_status : int = tw_const.clientstatus_uninitialized
var debug_draw_mode : String
var chunk_debug_mode  : String = ""
var cam_chunk_pos : String = ""
var cam_chunk_mesh_pos : Vector3 = Vector3(0,0,0)
var cam_chunk_mesh_aabb : AABB
var cam_chunk_mesh_pos_xzy : String = ""
var cam_chunk_mesh_aabb_x : String = ""
var cam_chunk_mesh_aabb_y : String = ""
var cam_chunk_mesh_aabb_z : String = ""
var cam_chunk_dmesh_pos_xzy : String = ""
var cam_chunk_dmesh_aabb_x : String = ""
var cam_chunk_dmesh_aabb_y : String = ""
var cam_chunk_dmesh_aabb_z : String = ""
var mouse_pos_in_viewport : Vector2
var deltaPos : Vector3
var hit : Vector3
var quad_hit_name : String
var quad_hit_pos : Vector3
var quad_hit_size : float
var chunk_hit_name : String
var chunk_hit_pos : Vector3
var chunk_hit_size : float
var chunk_hit_dist_from_cam : float
var time_of_last_ray : int = 0
const Color_Yellow_Apricot := Color(251.0 / 255.0, 206.0 / 255.0, 177.0 / 255.0)
var altPressed := false
var ctrlPressed := false
var shiftPressed := false
var ball_pos := Vector3.ZERO
var _ball_pos_info_line_index : int = 0
var _player_pos := Vector3.ZERO
var _player_velocity := Vector3.ZERO
var _player_info_line_1_index : int = 0
var _player_info_line_2_index : int = 0

var prev_hit : Vector3 = Vector3(0, 0, 0)

#var debug_running_game_global_exist := false

func _ready():
	get_tree().set_auto_accept_quit(false)

	init()

	$Test/TestBall.visible = false
	#$Player/Player.visible = false
	$Player/Player.set_player_in_world(false)
	#var cam : Camera3D = get_viewport().get_camera_3d()
	$Player/Player.set_camera(get_viewport().get_camera_3d(), $Player/Control/BackCameraContainer/BackCameraSubViewport/BackCamera, $Player/Control/BackCameraContainer, $Player/Control/SatelliteCameraContainer/SatelliteCameraSubViewport/SatelliteCamera, $Player/Control/SatelliteCameraContainer)
	var e := get_tree().get_root().connect("size_changed", Callable(self, "resizing"))
	log_debug(str("connect size_changed result=", e))
	#get_tree().get_root().set_transparent_background(true)
	#set_notify_transform(true)
	#TWViewer().global_transform = global_transform
	
	#if get_tree() != null:
	#	if get_tree().root.has_node("debug_running_game_global"):
	#		debug_running_game_global_exist = true
	
	#if not debug_running_game_global.get_game_anchored_in_editor():
	#	get_window().mode = _window_mode

func resizing():
	log_debug(str("Resizing: ", get_viewport().size))

func TWViewer() -> Node3D:
	if $Landscape/TWViewer == null:
		return null
	return $Landscape/TWViewer.get_self()

func init():
	log_debug("init")
	
	TWViewer().GDN_viewer().set_anchor_for_origin_shift(self)
	
	if Globals.cmdline_arguments.has(tw_const.cmdline_argument_strict_to_build_mode):
		Globals.strict_to_build_mode = true
	if Globals.cmdline_arguments.has(tw_const.cmdline_argument_world_depth_quads):
		var val : String = Globals.cmdline_arguments[tw_const.cmdline_argument_world_depth_quads]
		if val.is_valid_int():
			TWViewer()._set_world_param_depth_quad(int(val))
			TWViewer()._set_world_param_max_depth_quad(int(val))
	if Globals.cmdline_arguments.has(tw_const.cmdline_argument_world_cache_quads):
		var val : String = Globals.cmdline_arguments[tw_const.cmdline_argument_world_cache_quads]
		if val.is_valid_int():
			TWViewer()._set_world_param_cache_quad(int(val))
	
	#visible = false
	$UI/MessageContainer/Message.add_theme_color_override("font_color", Color(251.0 / 255.0, 206.0 / 255.0, 177.0 / 255.0))
	#$UI/MessageContainer/Message.text = "Deploying world ..."
	
	_config_file_name = ""
	while(_config_file_name == "" and not TWViewer().client_status() <= Globals.Constants.clientstatus_error):
		_config_file_name = TWViewer().GDN_globals().get_config_filename(0)
	if _client_status <= Globals.Constants.clientstatus_error:
		return
	print(str("_config_file_name", "=", _config_file_name))
		#var config = ConfigFile.new()
	
	var _build : String = ""
	if Globals.strict_to_build_mode:
		_build = "_debug" if (TWViewer().GDN_globals().debug_build()) else "_release"
	log_debug(str("init _build=", _build))
	
	var _err = _config.load(_config_file_name)
	
	_initial_camera_position_in_world = _config.get_value(tw_const.param_group_camera, tw_const.param_key_initial_camera_pos + _build)
	var initial_camera_ypr : Variant = _config.get_value(tw_const.param_group_camera, tw_const.param_key_initial_camera_ypr + _build)
	
	if _initial_camera_position_in_world == null or initial_camera_ypr == null:
		_initial_camera_position_in_world = _config.get_value(tw_const.param_group_camera, tw_const.param_key_initial_camera_pos)
		initial_camera_ypr = _config.get_value(tw_const.param_group_camera, tw_const.param_key_initial_camera_ypr)

	if _initial_camera_position_in_world != null and initial_camera_ypr != null:
		TWViewer()._set_camera_param_initial_pos(_initial_camera_position_in_world)
		TWViewer()._set_camera_param_initial_yaw_pitch_roll_deg(initial_camera_ypr)
		
	_initial_player_pos_in_world = _config.get_value(tw_const.param_group_player, tw_const.param_key_player_pos)
	_initial_player_basis_in_world = _config.get_value(tw_const.param_group_player, tw_const.param_key_player_basis)
	var map_camera_zoom : Variant =  _config.get_value(tw_const.param_group_camera, tw_const.param_key_initial_map_camera_zoom)
	if (map_camera_zoom != null):
		TWViewer().set_desidered_map_camera_zoom_factor(map_camera_zoom)

	var result = TWViewer().GDN_globals().connect("tw_status_changed", Callable(self, "_on_tw_status_changed")) == 0
	log_debug(str("signal tw_status_changed connected (result=", result, ")"))
	_client_status = get_clientstatus()
	_client_status_str = tw_const.status_to_string(_client_status)
	_ball_pos_info_line_index = TWViewer().add_info_panel_external_line("", 0)
	_player_info_line_1_index = TWViewer().add_info_panel_external_line("", 0)
	_player_info_line_2_index = TWViewer().add_info_panel_external_line("", 0)

func deinit():
	log_debug("deinit")
	TWViewer().GDN_globals().disconnect("tw_status_changed", Callable(self, "_on_tw_status_changed"))

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	if new_client_status == tw_const.clientstatus_world_undeploy_in_progress:
		save_current_position(-1)
		#$UI/MessageContainer/Message.text = "Undeploying world ..."
			
	_client_status = new_client_status
	_client_status_str = Globals.Constants.status_to_string(new_client_status)
	var old_client_status_str : String = Globals.Constants.status_to_string(old_client_status)
	var new_client_status_str : String = Globals.Constants.status_to_string(new_client_status)
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))
	
func _input(event):
	if event is InputEventKey && event.is_pressed() and event.is_action_pressed("ui_cancel"):
		var dict : Dictionary = {'viewpoint_to_save' : _viewpoint_to_save, "viewpoint_to_load" : _viewpoint_to_load}
		tw_const.check_viewpoint_input(event, dict)
		_viewpoint_to_save = dict['viewpoint_to_save']
		_viewpoint_to_load = dict['viewpoint_to_load']
		get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		log_debug("ESC pressed...")
		
	_client_status = get_clientstatus()
	if _client_status < Globals.Constants.clientstatus_session_initialized:
		return
		
	if event is InputEventKey and event.is_action_pressed("ui_toggle_fullscreen"):
		if not debug_running_game_global.get_game_anchored_in_editor():
			var w : Window = get_window()
			if (_fullscreen):
				w.always_on_top = false
				w.borderless = false
				w.mode = Window.MODE_MAXIMIZED
				_fullscreen = false
			else:
				w.always_on_top = true
				w.borderless = true
				w.mode = Window.MODE_MAXIMIZED
				_fullscreen = true

	if event is InputEventKey && event.is_pressed():
		var dict : Dictionary = {'viewpoint_to_save' : _viewpoint_to_save, "viewpoint_to_load" : _viewpoint_to_load}
		tw_const.check_viewpoint_input(event, dict)
		_viewpoint_to_save = dict['viewpoint_to_save']
		_viewpoint_to_load = dict['viewpoint_to_load']

		if event.is_action_pressed("ui_toggle_debug_stats"):
			if _debug_window_active:
				set_debug_window(false)
			else:
				set_debug_window(true)
		elif event.is_action_pressed("ui_up_arrow") && event.alt_pressed:
			collider_up_pressed = true
		elif event.is_action_pressed("ui_down_arrow") && event.alt_pressed:
			collider_down_pressed = true
		elif event.is_action_pressed("ui_left_arrow") && event.alt_pressed:
			collider_left_pressed = true
		elif event.is_action_pressed("ui_right_arrow") && event.alt_pressed:
			collider_right_pressed = true
		elif event.is_action_pressed("ui_page_up") && event.alt_pressed:
			collider_upaltitude_pressed = true
		elif event.is_action_pressed("ui_page_down") && event.alt_pressed:
			collider_downaltitude_pressed = true
		elif event.is_action_pressed("ui_up_arrow") && event.alt_pressed:
			collider_mesh_up_pressed = true
		elif event.is_action_pressed("ui_down_arrow") && event.alt_pressed:
			collider_mesh_down_pressed = true
		elif event.is_action_pressed("ui_left_arrow") && event.alt_pressed:
			collider_mesh_left_pressed = true
		elif event.is_action_pressed("ui_right_arrow") && event.alt_pressed:
			collider_mesh_right_pressed = true
		elif event.is_action_pressed("ui_page_up") && event.alt_pressed:
			collider_mesh_upaltitude_pressed = true
		elif event.is_action_pressed("ui_page_down") && event.alt_pressed:
			collider_mesh_downaltitude_pressed = true
		elif event.is_action_pressed("ui_cancel"):
			get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			log_debug("ESC pressed...")
		elif event.is_action_pressed("ui_test"):
			test_action_enabled = !test_action_enabled
			process_test_action = true
		elif event.is_action_pressed("ui_print_screen"):
			var img = get_viewport().get_texture().get_image()
			var _size : Vector2i = img.get_size()
			var save_path = OS.get_user_data_dir() + "\\screen.png"
			img.save_png(save_path)
		elif event.is_action_pressed("ui_drop_player"):
			var current_camera := get_viewport().get_camera_3d()
			var space_state = get_world_3d().direct_space_state
			var start : Vector3 = Vector3(current_camera.global_transform.origin.x, 10000, current_camera.global_transform.origin.z)
			var end : Vector3 = Vector3(current_camera.global_transform.origin.x, -10000, current_camera.global_transform.origin.z)
			var query = PhysicsRayQueryParameters3D.create(start, end)
			query.exclude = [$Player/Player]
			var result = space_state.intersect_ray(query)
			if result:
				var impact_pos : Vector3 = result.position
				$Player/Player.global_transform.origin = impact_pos + Vector3(0, 5, 0)
				$Player/Player.set_player_in_world(true)
		elif event.is_action_pressed("ui_toggle_back_mirror"):
			$Player/Player.toggle_back_camera_visibility()
		elif event.is_action_pressed("ui_toggle_satellite_view"):
			$Player/Player.toggle_satellite_view_visibility()
		#elif event.is_action_pressed("ui_dump"):
		#	TWViewer().GDN_viewer().dump_required()

func _physics_process(_delta):
	#read_shift_ctrl_alt()
	pass

func _notification(_what):
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		#$Player/Player.visible = false
		$Player/Player.set_player_in_world(false)
		log_debug("_notification: NOTIFICATION_WM_CLOSE_REQUEST ")
		var v = TWViewer()
		if v != null:
			v.activate_shutdown()
		else:
			force_app_to_quit()
		
	#elif (_what == Spatial.NOTIFICATION_TRANSFORM_CHANGED):
		#var viewer : Spatial = TWViewer().GDN_viewer()
		#viewer.global_transform = global_transform
	elif (_what == Node3D.NOTIFICATION_ENTER_WORLD):
		log_debug("Notification Node3D.NOTIFICATION_ENTER_WORLD")
	elif (_what == NOTIFICATION_PREDELETE):
		print("_notification: NOTIFICATION_PREDELETE - Destroy TheWorld_Main")
		
func _enter_tree():
	_logger.debug("_enter_tree")
	log_debug("_enter_tree")
	
func _exit_tree():
	log_debug("_exit_tree")
	exit_world()
	#deinit()
	
func _process(_delta):

	if _saved_time_to_fade_message > 0 and (Time.get_ticks_msec() - _saved_time_to_fade_message) > 3000:
		$UI/MessageContainer/Message.text = ""
		_saved_time_to_fade_message = 0
	
	if Globals.appstatus != Globals.appstatus_running:
		return
	
	#var clientstatus : int = TWViewer().get_clientstatus()
	#client_status = Globals.Constants.status_to_string(clientstatus)
	
	if not world_initialized && get_clientstatus() >= tw_const.clientstatus_session_initialized:
		if not debug_running_game_global.get_game_anchored_in_editor():
			get_window().mode = _window_mode
		enter_world()
		world_initialized = true

	if _client_status < Globals.Constants.clientstatus_session_initialized:
		return
	
	var tw_viewer = TWViewer()
	if tw_viewer == null:
		return
	
	var gdn_viewer : Node3D = tw_viewer.GDN_viewer()
	if gdn_viewer == null:
		return

	#if init_world_thread.is_alive():
	#	return
	#if init_world_thread.is_active():
	#	init_world_thread.wait_to_finish()
	
	if not _world_entered:
		return
		
	if not gdn_viewer.initial_world_viewer_pos_set():
		return
	
	var current_camera := get_viewport().get_camera_3d()
	
	#if not scene_initialized:
		#current_camera.global_transform.origin = Vector3(current_camera.global_transform.origin.x, initialCameraAltitudeForced, current_camera.global_transform.origin.z)
		#if (_initialCameraDistanceFromTerrain == 0):
		#	current_camera.global_transform.origin.y = initialCameraAltitudeForced

		#current_camera.look_at(initialViewerPos, Vector3(0, 1, 0))
		#current_camera.look_at(Vector3(current_camera.global_transform.origin.x + 1, 0, current_camera.global_transform.origin.z + 1), Vector3(0, 1, 0))
		
		# face to north
		#current_camera.look_at(Vector3(current_camera.global_transform.origin.x, current_camera.global_transform.origin.y, current_camera.global_transform.origin.z - 10000), Vector3(0, 1, 0))
		
		#current_camera.set_yaw(-139.0, false)
		#current_camera.set_pitch(-7.0, false)
		
		#current_camera.global_transform.origin = Vector3(-7, 2200, -40)	# Procedural HTerrain view
		#current_camera.set_yaw(-141.0, false)
		#current_camera.set_pitch(-30.0, false)
		
		#current_camera.global_transform.basis = Basis(Vector3(-1.57, -1.57, 0))
		# DEBUGRIC
		#scene_initialized = true
	
	#if scene_initialized && !post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
	if !post_world_deploy_initialized && _client_status >= Globals.Constants.clientstatus_world_deployed:
		
		if _initial_camera_position_in_world != null:
			var space_state = get_world_3d().direct_space_state
			var initial_ball_global_transform : Vector3 = TWViewer().GDN_viewer().world_pos_to_global_pos(_initial_camera_position_in_world)
			var query = PhysicsRayQueryParameters3D.create(Vector3(initial_ball_global_transform.x, 10000, initial_ball_global_transform.z), Vector3(initial_ball_global_transform.x, -10000, initial_ball_global_transform.z))
			var result = space_state.intersect_ray(query)
			if result:
				$Test/TestBall.global_transform.origin = Vector3(initial_ball_global_transform.x + 10, result.position.y + 50, initial_ball_global_transform.z + 10)
				#$Player/Player.global_transform.origin = Vector3(initial_ball_global_transform.x, result.position.y + 50, initial_ball_global_transform.z)
			if _initial_player_pos_in_world != null && _initial_player_basis_in_world != null:
				var player_initial_map_transform : Transform3D = Transform3D(_initial_player_basis_in_world, _initial_player_pos_in_world)
				var player_initial_global_transform : Transform3D = TWViewer().GDN_viewer().world_transform_to_global_transform(player_initial_map_transform)
				var initial_player_pos_global_coord := player_initial_global_transform.origin
				var initial_player_basis_global_coord := player_initial_global_transform.basis
				$Player/Player.global_transform.origin = initial_player_pos_global_coord #+  Vector3(10, 5000, 10)
				$Player/Player.global_transform.basis = initial_player_basis_global_coord
				if not result:
					$Test/TestBall.global_transform.origin = initial_player_pos_global_coord + Vector3(10, 50, 10)
			#$Test/TestBall.global_transform.origin = Vector3(_initial_camera_position_in_world.x + 10, 500, _initial_camera_position_in_world.z + 10)
			$Test/TestBall.visible = true
			#$Player/Player.visible = true
			$Player/Player.set_player_in_world(true)
			#$UI/MessageContainer/Message.text = ""
		
		#_saved_time_to_fade_message = Time.get_ticks_msec()
		#$UI/MessageContainer/Message.text = "World deployed"
		#visible = true
		post_world_deploy_initialized = true
	
	#if scene_initialized && post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
	if post_world_deploy_initialized && _client_status >= Globals.Constants.clientstatus_world_deployed:
		ball_pos = TWViewer().GDN_viewer().global_pos_to_world_transform($Test/TestBall.global_transform.origin).origin
		tw_viewer.set_info_panel_external_value("Ball pos: (" + str(snapped(ball_pos.x, 0.01)) + ", " + str(snapped(ball_pos.y, 0.01)) + ", " + str(snapped(ball_pos.z, 0.01)) + ")", _ball_pos_info_line_index)
		_player_pos = TWViewer().GDN_viewer().global_pos_to_world_transform($Player/Player.global_transform.origin).origin
		_player_velocity = $Player/Player.velocity
		var velocity : float = _player_velocity.length()
		if ($Player/Player.is_stopped()):
			velocity = 0
		var player_dist_from_terrain := ""
		if ($Player/Player.player_dist_from_terrain >= 0):
			player_dist_from_terrain = str(snapped($Player/Player.player_dist_from_terrain, 0.01))
		tw_viewer.set_info_panel_external_value("Player pos: (" + str(snapped(_player_pos.x, 0.01)) + ", " + str(snapped(_player_pos.y, 0.01)) + ", " + str(snapped(_player_pos.z, 0.01)) + ")", _player_info_line_1_index)
		#tw_viewer.set_info_panel_external_value("Speed: " + str(snapped(velocity, 0.01)) + " m/s " +  str(int((velocity * 60 * 60)) / 1000) + " km/h  H: " + player_dist_from_terrain, _player_info_2_line_index) 
		tw_viewer.set_info_panel_external_value("Player speed: " + str(snapped(velocity, 0.01)) + " m/s " +  str(floor((velocity * 60 * 60) / 1000)) + " km/h  alt: " + player_dist_from_terrain, _player_info_line_2_index) 
		
		if _viewpoint_to_save >= 0:
			save_current_position(_viewpoint_to_save)
			#$UI/MessageContainer/Message.text = "Viewpoint " + str(_viewpoint_to_save) + " saved!"
			TWViewer().GDN_viewer().set_hud_message("Viewpoint " + str(_viewpoint_to_save) + " saved!", 3000)
			_saved_time_to_fade_message = Time.get_ticks_msec()
			_viewpoint_to_save = -1
		
		if _viewpoint_to_load >= 0:			
			if not $Player/Player.camera_tracking_player():
				load_position(_viewpoint_to_load)
				#$UI/MessageContainer/Message.text = "Viewpoint " + str(_viewpoint_to_load) + " loaded!"
				TWViewer().GDN_viewer().set_hud_message("Viewpoint " + str(_viewpoint_to_load) + " loaded!", 3000)
				_saved_time_to_fade_message = Time.get_ticks_msec()
			_viewpoint_to_load = -1
			
	if _debug_window_active:
		fps = Engine.get_frames_per_second()
		var _chunk_debug_mode : String = gdn_viewer.get_chunk_debug_mode()
		var _cam_chunk_pos = gdn_viewer.get_camera_quadrant_name() + " " + gdn_viewer.get_camera_chunk_id()
		if (_cam_chunk_pos != cam_chunk_pos or _chunk_debug_mode != chunk_debug_mode):
			var t_aabb : AABB = gdn_viewer.get_camera_chunk_local_aabb()
			var t_mesh : Transform3D = gdn_viewer.get_camera_chunk_global_transform_applied()
			cam_chunk_mesh_pos_xzy = str(t_mesh.origin.x, ":", t_mesh.origin.z, ":", t_mesh.origin.y)
			cam_chunk_mesh_aabb_x = str(t_mesh.origin.x, ":", t_mesh.origin.x + t_aabb.size.x)
			cam_chunk_mesh_aabb_y = str(t_mesh.origin.y, ":", t_mesh.origin.y + t_aabb.size.y)
			cam_chunk_mesh_aabb_z = str(t_mesh.origin.z, ":", t_mesh.origin.z + t_aabb.size.z)
			t_aabb = gdn_viewer.get_camera_chunk_local_debug_aabb()
			t_mesh = gdn_viewer.get_camera_chunk_debug_global_transform_applied()
			cam_chunk_dmesh_pos_xzy = str(t_mesh.origin.x, ":", t_mesh.origin.z, ":", t_mesh.origin.y)
			cam_chunk_dmesh_aabb_x = str(t_mesh.origin.x, ":", t_mesh.origin.x + t_aabb.size.x)
			cam_chunk_dmesh_aabb_y = str(t_mesh.origin.y, ":", t_mesh.origin.y + t_aabb.size.y)
			cam_chunk_dmesh_aabb_z = str(t_mesh.origin.z, ":", t_mesh.origin.z + t_aabb.size.z)
			chunk_debug_mode = _chunk_debug_mode
			cam_chunk_mesh_pos = t_mesh.origin
			cam_chunk_mesh_aabb = t_aabb
			cam_chunk_pos = _cam_chunk_pos
		
		hit = gdn_viewer.get_mouse_hit_in_map()
		if hit != prev_hit:
			deltaPos = hit - prev_hit
			prev_hit = hit
		quad_hit_name = gdn_viewer.get_mouse_quadrant_hit_name() + " " + gdn_viewer.get_mouse_quadrant_hit_tag()
		quad_hit_pos = gdn_viewer.get_mouse_quadrant_hit_pos()
		quad_hit_size = gdn_viewer.get_mouse_quadrant_hit_size()
		chunk_hit_name = gdn_viewer.get_mouse_chunk_hit_name()
		chunk_hit_pos = gdn_viewer.get_mouse_chunk_hit_pos()
		chunk_hit_size = gdn_viewer.get_mouse_chunk_hit_size()
		chunk_hit_dist_from_cam = gdn_viewer.get_mouse_chunk_hit_dist_from_cam()
		mouse_pos_in_viewport = get_viewport().get_mouse_position()
		chunk_grid_global_pos = tw_viewer.GDN_viewer().global_transform.origin
		if current_camera:
			#active_camera_global_rot = current_camera.global_transform.basis.get_euler()
			active_camera_global_rot = str(current_camera.global_transform.basis.get_euler()) + " | " + "yaw " + str(int(current_camera.get_yaw(false))) + " pitch " + str(int(current_camera.get_pitch(false)))
			active_camera_global_pos = current_camera.global_transform.origin
			degree_from_north = current_camera.get_angle_from_north_degree()
		num_splits = gdn_viewer.get_num_splits()
		num_joins = gdn_viewer.get_num_joins()
		num_active_chunks = gdn_viewer.get_num_active_chunks()
		num_quadrant = str(gdn_viewer.get_num_initialized_quadrant()) + ":" + str(gdn_viewer.get_num_quadrant_in_view()) + "(" + str(gdn_viewer.get_num_quadrant_in_memory()) + ")"
		num_visible_quadrant = str(gdn_viewer.get_num_initialized_visible_quadrant()) + ":" + str(gdn_viewer.get_num_visible_quadrant())
		num_empty_quadrant = str(gdn_viewer.get_num_empty_quadrant())
		num_flushed_quadrant = str(gdn_viewer.get_num_flushed_quadrant())
		var update_quads1_duration : int = gdn_viewer.get_update_quads1_duration()
		var update_quads2_duration : int = gdn_viewer.get_update_quads2_duration()
		var update_quads3_duration : int = gdn_viewer.get_update_quads3_duration()
		process_durations_mcs = str(gdn_viewer.get_process_duration()) \
			+ " UQ " + str (update_quads1_duration + update_quads2_duration + update_quads3_duration) \
			+ " (" + str(update_quads1_duration) \
			+ " " + str(update_quads2_duration) \
			+ " " + str(update_quads3_duration)\
			+ ") UC " + str(gdn_viewer.get_update_chunks_duration()) \
			+ " UM " + str(gdn_viewer.get_update_material_params_duration()) \
			###+ " RQ " + str(gdn_viewer.get_refresh_quads_duration()) \
			+ " T " + str(gdn_viewer.get_mouse_track_hit_duration())
		num_process_locked = gdn_viewer.get_num_process_not_owns_lock()
		debug_draw_mode = gdn_viewer.get_debug_draw_mode()

	# check mouse pos on the ground
	#var current_time : int = Time.get_ticks_msec()
	#if (process_test_action || current_time - time_of_last_ray > 250):
	#	time_of_last_ray = current_time
	#	process_test_action = false
		
	#	var _test_action_changed := false
	#	if test_action_enabled != prev_test_action_enabled:
	#		prev_test_action_enabled = test_action_enabled
	#		_test_action_changed = true

		#if _test_action_changed:
		#tracked_chunk = tw_viewer.GDN_viewer().get_tracked_chunk_str()
		
func enter_world():
	log_debug("Entering world...")
	#var mode = Window.MODE_MAXIMIZED if (true) else Window.MODE_WINDOWED
	#get_window().mode = mode
	set_debug_window(false)
	$UI/DebugStats.add_property(self, "_client_status", "")
	$UI/DebugStats.add_property(self, "fps", "")
	$UI/DebugStats.add_property(self, "process_durations_mcs", "")
	$UI/DebugStats.add_property(self, "num_process_locked", "")
	$UI/DebugStats.add_property(self, "debug_draw_mode", "")
	$UI/DebugStats.add_property(self, "chunk_grid_global_pos", "")
	$UI/DebugStats.add_property(self, "degree_from_north", "")
	$UI/DebugStats.add_property(self, "active_camera_global_rot", "")
	$UI/DebugStats.add_property(self, "active_camera_global_pos", "")
	$UI/DebugStats.add_property(self, "num_active_chunks", "")
	$UI/DebugStats.add_property(self, "num_quadrant", "")
	$UI/DebugStats.add_property(self, "num_visible_quadrant", "")
	$UI/DebugStats.add_property(self, "num_empty_quadrant", "")
	$UI/DebugStats.add_property(self, "num_flushed_quadrant", "")
	$UI/DebugStats.add_property(self, "num_splits", "")
	$UI/DebugStats.add_property(self, "num_joins", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_pos", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_mesh_pos_xzy", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_mesh_aabb_x", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_mesh_aabb_z", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_mesh_aabb_y", "")
	#$UI/DebugStats.add_property(self, "chunk_debug_mode", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_dmesh_pos_xzy", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_dmesh_aabb_x", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_dmesh_aabb_z", "")
	#$UI/DebugStats.add_property(self, "cam_chunk_dmesh_aabb_y", "")
	#$UI/DebugStats.add_property(self, "transform_step", "")
	#$UI/DebugStats.add_property(self, "collider_transform_pos", "")
	#$UI/DebugStats.add_property(self, "collider_transform_rot", "")
	#$UI/DebugStats.add_property(self, "collider_transform_scl", "")
	#$UI/DebugStats.add_property(self, "collider_mesh_transform_pos", "")
	#$UI/DebugStats.add_property(self, "collider_mesh_transform_rot", "")
	#$UI/DebugStats.add_property(self, "collider_mesh_transform_scl", "")
	$UI/DebugStats.add_property(self, "mouse_pos_in_viewport", "")
	#$UI/DebugStats.add_property(self, "quadDistFromCamera", "")
	#$UI/DebugStats.add_property(self, "ray_origin", "")
	#$UI/DebugStats.add_property(self, "ray_end", "")
	$UI/DebugStats.add_property(self, "deltaPos", "")
	$UI/DebugStats.add_property(self, "hit", "")
	$UI/DebugStats.add_property(self, "quad_hit_name", "")
	$UI/DebugStats.add_property(self, "quad_hit_pos", "")
	$UI/DebugStats.add_property(self, "quad_hit_size", "")
	$UI/DebugStats.add_property(self, "chunk_hit_name", "")
	$UI/DebugStats.add_property(self, "chunk_hit_pos", "")
	$UI/DebugStats.add_property(self, "chunk_hit_size", "")
	$UI/DebugStats.add_property(self, "chunk_hit_dist_from_cam", "")
	$UI/DebugStats.add_property(self, "ball_pos", "")
	#$UI/DebugStats.add_property(self, "tracked_chunk", "")
	
	#_init_world()
	
	#init_world_thread = Thread.new()
	#var err := init_world_thread.start(self, "_init_world")
	#if err:
	#	log_debug("Start _init_world failure!")
	log_debug("World entered...")
	_world_entered = true
	
func exit_world():
	if _world_entered:
		log_debug("Exiting world...")
		$UI/DebugStats.remove_property(self, "_client_status")
		$UI/DebugStats.remove_property(self, "fps")
		$UI/DebugStats.remove_property(self, "process_durations_mcs")
		$UI/DebugStats.remove_property(self, "num_process_locked")
		$UI/DebugStats.remove_property(self, "debug_draw_mode")
		$UI/DebugStats.remove_property(self, "chunk_grid_global_pos")
		$UI/DebugStats.remove_property(self, "degree_from_north")
		$UI/DebugStats.remove_property(self, "active_camera_global_rot")
		$UI/DebugStats.remove_property(self, "active_camera_global_pos")
		$UI/DebugStats.remove_property(self, "num_active_chunks")
		$UI/DebugStats.remove_property(self, "num_quadrant")
		$UI/DebugStats.remove_property(self, "num_visible_quadrant")
		$UI/DebugStats.remove_property(self, "num_empty_quadrant")
		$UI/DebugStats.remove_property(self, "num_flushed_quadrant")
		$UI/DebugStats.remove_property(self, "num_splits")
		$UI/DebugStats.remove_property(self, "num_joins")
		#$UI/DebugStats.remove_property(self, "cam_chunk_pos")
		#$UI/DebugStats.remove_property(self, "cam_chunk_mesh_pos_xzy")
		#$UI/DebugStats.remove_property(self, "cam_chunk_mesh_aabb_x")
		#$UI/DebugStats.remove_property(self, "cam_chunk_mesh_aabb_z")
		#$UI/DebugStats.remove_property(self, "cam_chunk_mesh_aabb_y")
		#$UI/DebugStats.remove_property(self, "chunk_debug_mode")
		#$UI/DebugStats.remove_property(self, "cam_chunk_dmesh_pos_xzy")
		#$UI/DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_x")
		#$UI/DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_z")
		#$UI/DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_y")
		#$UI/DebugStats.remove_property(self, "transform_step")
		#$UI/DebugStats.remove_property(self, "collider_transform_pos")
		#$UI/DebugStats.remove_property(self, "collider_transform_rot")
		#$UI/DebugStats.remove_property(self, "collider_transform_scl")
		#$UI/DebugStats.remove_property(self, "collider_mesh_transform_pos")
		#$UI/DebugStats.remove_property(self, "collider_mesh_transform_rot")
		#$UI/DebugStats.remove_property(self, "collider_mesh_transform_scl")
		$UI/DebugStats.remove_property(self, "mouse_pos_in_viewport")
		#$UI/DebugStats.remove_property(self, "quadDistFromCamera")
		#$UI/DebugStats.remove_property(self, "ray_origin")
		#$UI/DebugStats.remove_property(self, "ray_end")
		$UI/DebugStats.remove_property(self, "deltaPos")
		$UI/DebugStats.remove_property(self, "hit")
		$UI/DebugStats.remove_property(self, "quad_hit_name")
		$UI/DebugStats.remove_property(self, "quad_hit_pos")
		$UI/DebugStats.remove_property(self, "quad_hit_size")
		$UI/DebugStats.remove_property(self, "chunk_hit_name")
		$UI/DebugStats.remove_property(self, "chunk_hit_pos")
		$UI/DebugStats.remove_property(self, "chunk_hit_size")
		$UI/DebugStats.remove_property(self, "chunk_hit_dist_from_cam")
		$UI/DebugStats.remove_property(self, "ball_pos")
		#$UI/DebugStats.remove_property(self, "tracked_chunk")
		#if init_world_thread.is_active():
		#	init_world_thread.wait_to_finish()
		log_debug("World exited...")
		_world_entered = false
	
func set_debug_window(active : bool) -> void:
	if active:
		_debug_window_active = true
		$UI/DebugStats.visible = true
	else:
		_debug_window_active = false
		$UI/DebugStats.visible = false
		
#func _init_world() -> void:
#	log_debug("Initializing world...")
#	initialViewerPos = TWViewer()._get_initial_viewer_pos()
#	_initialCameraDistanceFromTerrain = TWViewer()._get_dist_from_terr()
#	initialCameraAltitudeForced = initialViewerPos.y
#	TWViewer().GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
#	log_debug("World initialization completed...")
	
func force_app_to_quit() -> void:
	get_viewport().set_input_as_handled()
	get_tree().quit()
	
func get_clientstatus() -> int:
	return TWViewer().get_clientstatus()
	
func log_debug(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)

func debug_print(context : String, text : String, godot_print : bool):
	TWViewer().debug_print(context, text, godot_print)

func log_info(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)

func info_print(context : String, text : String, godot_print : bool):
	TWViewer().info_print(context, text, godot_print)

func log_error(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)

func error_print(context : String, text : String, godot_print : bool):
	TWViewer().error_print(context, text, godot_print)

func test_subvieport(node : Node) -> void:
	var _viewport : SubViewport = null
	var _viewport_size := 512
	var _plane : MeshInstance3D = null
	var _camera : Camera3D = null

	_viewport = SubViewport.new()
	add_child(_viewport)
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.world_3d = World3D.new()
	_viewport.own_world_3d = true
	#_viewport.name = "CodeViewport"
	_viewport.size = Vector2(_viewport_size + 1, _viewport_size + 1)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 0.0)
	
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(_viewport_size, _viewport_size)
	mesh.subdivide_depth = 3
	mesh.subdivide_width = 3
	
	_plane = MeshInstance3D.new()
	#_plane.name = "CodePlane"
	_plane.material_override = mat
	_plane.mesh = mesh
	_viewport.add_child(_plane)
	
	_camera = Camera3D.new()
	#_camera.name = "Codecamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _viewport.size.x
	_camera.near = 0.1
	_camera.far = 10.0
	_camera.current = true
	_camera.rotation = Vector3(deg_to_rad(-90), 0, 0)
	_viewport.add_child(_camera)
	
	_camera.position = Vector3(0.0, 2.0, 0.0)
	
	var _sprite := Sprite2D.new()
	node.add_child(_sprite)
	_sprite.position = Vector2(256 + 512, 256)
	_sprite.texture = _viewport.get_texture()

func save_current_position(viewpoint : int) -> void:
	var camera : Camera3D = TWViewer().get_world_camera()
	var gdn_viewer = TWViewer().GDN_viewer()
	if camera != null && camera.has_method("get_yaw") && camera.has_method("get_pitch") && camera.has_method("get_roll"):
		#var config = ConfigFile.new()
		#@warning_ignore("unused_variable")
		#var err = config.load(config_file_name)
		@warning_ignore("unassigned_variable")
		var camera_ypr : Vector3
		camera_ypr.x = camera.get_yaw(false)
		camera_ypr.y = camera.get_pitch(false)
		camera_ypr.z = camera.get_roll(false)
		var camera_pos : Vector3
		camera_pos = camera.get_camera_world_transform().origin
		var param_key_camera_pos := ""
		var param_key_camera_ypr := ""
		if viewpoint == -1:
			var player_global_transform = $Player/Player.global_transform 
			var player_map_transform : Transform3D = gdn_viewer.global_transform_to_world_transform(player_global_transform)
			_config.set_value(tw_const.param_group_player, tw_const.param_key_player_pos, player_map_transform.origin)
			_config.set_value(tw_const.param_group_player, tw_const.param_key_player_basis, player_map_transform.basis)
			param_key_camera_pos = tw_const.param_key_initial_camera_pos
			param_key_camera_ypr = tw_const.param_key_initial_camera_ypr
			var map_camera_zoom : float = TWViewer().get_map_camera_zoom_factor()
			_config.set_value(tw_const.param_group_camera, tw_const.param_key_initial_map_camera_zoom, map_camera_zoom)
		else:
			param_key_camera_pos = tw_const.param_key_viewpoint_camera_pos + str(viewpoint)
			param_key_camera_ypr = tw_const.param_key_viewpoint_camera_ypr + str(viewpoint)
		
		_config.set_value(tw_const.param_group_camera, param_key_camera_pos, camera_pos)
		_config.set_value(tw_const.param_group_camera, param_key_camera_ypr, camera_ypr)
		var _build : String = "_debug" if (TWViewer().GDN_globals().debug_build()) else "_release"
		_config.set_value(tw_const.param_group_camera, param_key_camera_pos + _build, camera_pos)
		_config.set_value(tw_const.param_group_camera, param_key_camera_ypr + _build, camera_ypr)
		print("TheWorld_Main.save_current_position _build=" + _build)
		
		_config.save(_config_file_name)

func load_position(viewpoint : int) -> void:
	var param_key_camera_pos := ""
	var param_key_camera_ypr := ""
	var _build : String = ""
	
	if Globals.strict_to_build_mode:
		_build = "_debug" if (TWViewer().GDN_globals().debug_build()) else "_release"
	print("TheWorld_Main.load_position _build=" + _build)

	if viewpoint == -1:
		param_key_camera_pos = tw_const.param_key_initial_camera_pos
		param_key_camera_ypr = tw_const.param_key_initial_camera_ypr
	else:
		param_key_camera_pos = tw_const.param_key_viewpoint_camera_pos + str(viewpoint)
		param_key_camera_ypr = tw_const.param_key_viewpoint_camera_ypr + str(viewpoint)
	
	var camera_position_in_map : Variant = null
	var camera_ypr_in_map : Variant = null
	if _config.has_section_key(tw_const.param_group_camera, param_key_camera_pos + _build):
		camera_position_in_map = _config.get_value(tw_const.param_group_camera, param_key_camera_pos + _build)
	if _config.has_section_key(tw_const.param_group_camera, param_key_camera_ypr + _build):
		camera_ypr_in_map = _config.get_value(tw_const.param_group_camera, param_key_camera_ypr + _build)
	
	if camera_position_in_map == null or camera_ypr_in_map == null:
		camera_position_in_map= _config.get_value(tw_const.param_group_camera, param_key_camera_pos)
		camera_ypr_in_map= _config.get_value(tw_const.param_group_camera, param_key_camera_ypr)
		
	if camera_position_in_map != null and camera_ypr_in_map != null:
		TWViewer()._set_camera_param_initial_pos(camera_position_in_map)
		TWViewer()._set_camera_param_initial_yaw_pitch_roll_deg(camera_ypr_in_map)
		Globals.activate_loading_screen(null)
	
func read_shift_ctrl_alt() -> void:
	if Input.is_action_pressed("ui_alt"):
		altPressed = true
	else:
		altPressed = false

	if Input.is_action_pressed("ui_ctrl"):
		ctrlPressed = true
	else:
		ctrlPressed = false

	if Input.is_action_pressed("ui_shift"):
		shiftPressed = true
	else:
		shiftPressed = false
