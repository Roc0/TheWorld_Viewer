extends Node3D

var debug_window_active : bool = false
var world_entered : bool = false

var tw_const = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("res://addons/twviewer/util/logger.gd")
var _logger = HT_Logger.get_for(self)

var initialCameraDistanceFromTerrain : float = 300

var initialBallPos := Vector3(0, 0, 0)

#var initialViewerPos := Vector3(0, 2200, 0)
#var initialCameraAltitudeForced = 0
#var initialYawPitchRoll := Vector3(-139, -7, 0)

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
var _client_status : String
var _clientstatus : int = tw_const.clientstatus_uninitialized
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
var ball_pos := Vector3(0, 0, 0)
var _ball_pos_info_line_index : int = 0

var prev_hit : Vector3 = Vector3(0, 0, 0)
		
func _ready():
	get_tree().set_auto_accept_quit(false)

	init()

	$Test/TestBallRigidBody.visible = false
	var e := get_tree().get_root().connect("size_changed", Callable(self, "resizing"))
	log_debug(str("connect size_changed result=", e))
	#get_tree().get_root().set_transparent_background(true)
	#set_notify_transform(true)
	#TWViewer().global_transform = global_transform
	
	get_window().mode = _window_mode


func resizing():
	log_debug(str("Resizing: ", get_viewport().size))

func TWViewer() -> Node3D:
	if $TWViewer == null:
		return null
	return $TWViewer.get_self()

func init():
	log_debug("init")
	var result = TWViewer().GDN_globals().connect("tw_status_changed", Callable(self, "_on_tw_status_changed")) == 0
	log_debug(str("signal tw_status_changed connected (result=", result, ")"))
	_clientstatus = get_clientstatus()
	_client_status = tw_const.status_to_string(_clientstatus)
	_ball_pos_info_line_index = TWViewer().add_info_panel_external_line("Ball pos:", 0)

func deinit():
	log_debug("deinit")
	TWViewer().GDN_globals().disconnect("tw_status_changed", Callable(self, "_on_tw_status_changed"))

func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	_clientstatus = new_client_status
	_client_status = Globals.Constants.status_to_string(new_client_status)
	var old_client_status_str : String = Globals.Constants.status_to_string(old_client_status)
	var new_client_status_str : String = Globals.Constants.status_to_string(new_client_status)
	log_debug(str("_on_tw_status_changed ", old_client_status_str, "(", old_client_status, ") ==> ", new_client_status_str, "(", new_client_status, ")"))

func _input(event):
	_clientstatus = get_clientstatus()
	if _clientstatus < Globals.Constants.clientstatus_session_initialized:
		pass
		
	if event is InputEventKey:
		if event.is_action_pressed("ui_alt"):
			altPressed = true
		if event.is_action_released("ui_alt"):
			altPressed = false

		if event.is_action_pressed("ui_ctrl"):
			ctrlPressed = true
		if event.is_action_released("ui_ctrl"):
			ctrlPressed = false

		if event.is_action_pressed("ui_toggle_debug_stats"):
			if debug_window_active:
				set_debug_window(false)
			else:
				set_debug_window(true)
		elif event.is_action_pressed("ui_up_arrow") && altPressed:
			collider_up_pressed = true
		elif event.is_action_pressed("ui_down_arrow") && altPressed:
			collider_down_pressed = true
		elif event.is_action_pressed("ui_left_arrow") && altPressed:
			collider_left_pressed = true
		elif event.is_action_pressed("ui_right_arrow") && altPressed:
			collider_right_pressed = true
		elif event.is_action_pressed("ui_page_up") && altPressed:
			collider_upaltitude_pressed = true
		elif event.is_action_pressed("ui_page_down") && altPressed:
			collider_downaltitude_pressed = true
		elif event.is_action_pressed("ui_up_arrow") && ctrlPressed:
			collider_mesh_up_pressed = true
		elif event.is_action_pressed("ui_down_arrow") && ctrlPressed:
			collider_mesh_down_pressed = true
		elif event.is_action_pressed("ui_left_arrow") && ctrlPressed:
			collider_mesh_left_pressed = true
		elif event.is_action_pressed("ui_right_arrow") && ctrlPressed:
			collider_mesh_right_pressed = true
		elif event.is_action_pressed("ui_page_up") && ctrlPressed:
			collider_mesh_upaltitude_pressed = true
		elif event.is_action_pressed("ui_page_down") && ctrlPressed:
			collider_mesh_downaltitude_pressed = true
		elif event.is_action_pressed("ui_cancel"):
			get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			log_debug("ESC pressed...")
		elif event.is_action_pressed("ui_test"):
			test_action_enabled = !test_action_enabled
			process_test_action = true
		#elif event.is_action_pressed("ui_dump"):
		#	TWViewer().GDN_viewer().dump_required()

func _notification(_what):
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
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

	if Globals.appstatus != Globals.appstatus_running:
		return
	
	#var clientstatus : int = TWViewer().get_clientstatus()
	#client_status = Globals.Constants.status_to_string(clientstatus)
	
	if not world_initialized && get_clientstatus() >= tw_const.clientstatus_session_initialized:
		get_window().mode = _window_mode
		enter_world()
		world_initialized = true

	if _clientstatus < Globals.Constants.clientstatus_session_initialized:
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
	
	if not world_entered:
		return
		
	if not gdn_viewer.initial_world_viewer_pos_set():
		return
	
	var current_camera := get_viewport().get_camera_3d()
	
	#if not scene_initialized:
		#current_camera.global_transform.origin = Vector3(current_camera.global_transform.origin.x, initialCameraAltitudeForced, current_camera.global_transform.origin.z)
		#if (initialCameraDistanceFromTerrain == 0):
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
	if !post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
		$Test/TestBallRigidBody.global_transform.origin = Vector3(initialBallPos.x + 1, initialBallPos.y + 1500, initialBallPos.z + 1)
		#if (initialCameraAltitudeForced != 0):
		#	$Test/TestBallRigidBody.global_transform.origin.y = initialCameraAltitudeForced
		$Test/TestBallRigidBody.visible = true
		post_world_deploy_initialized = true
	
	#if scene_initialized && post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
	if post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
		ball_pos = $Test/TestBallRigidBody.global_transform.origin
		tw_viewer.set_info_panel_external_value(str(ball_pos), _ball_pos_info_line_index)
	
	if debug_window_active:
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
		
		hit = gdn_viewer.get_mouse_hit()
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
		num_quadrant = str(gdn_viewer.get_num_initialized_quadrant()) + ":" + str(gdn_viewer.get_num_quadrant())
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
			+ " RQ " + str(gdn_viewer.get_refresh_quads_duration()) \
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
	world_entered = true
	
func exit_world():
	if world_entered:
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
		world_entered = false
	
func set_debug_window(active : bool) -> void:
	if active:
		debug_window_active = true
		$UI/DebugStats.visible = true
	else:
		debug_window_active = false
		$UI/DebugStats.visible = false
		
#func _init_world() -> void:
#	log_debug("Initializing world...")
#	initialViewerPos = TWViewer()._get_initial_viewer_pos()
#	initialCameraDistanceFromTerrain = TWViewer()._get_dist_from_terr()
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
