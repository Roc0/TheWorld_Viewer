extends Spatial

var debug_window_Active : bool = false
var world_entered : bool = false

var tw_const = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("res://addons/twviewer/util/logger.gd")
var _logger = HT_Logger.get_for(self)

const initialCameraDistanceFromTerrain = 300

const initialViewerPos := Vector3(0, 0, 0)
#const initialViewerPos := Vector3(2000, 0, 9000)
#const initialViewerPos := Vector3(2000, 0, 15000)
#const initialViewerPos := Vector3(1196000, 0, 5464000)
#const initialViewerPos := Vector3(1196000, 0, 5467000)

#const initialCameraAltitudeForced = 0
const initialCameraAltitudeForced = 2000
#const initialCameraAltitudeForced = 7000
#const initialCameraAltitudeForced = 2900
#const initialCameraAltitudeForced = 1485
#const initialCameraAltitudeForced = 9417

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
var scene_initialized : bool = false
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

var prev_hit : Vector3 = Vector3(0, 0, 0)
		
func _ready():
	init()
	$BallRigidBody.visible = false
	var e := get_tree().get_root().connect("size_changed", self, "resizing")
	log_debug(str("connect size_changed result=", e))
	#set_notify_transform(true)
	#TWViewer().global_transform = global_transform

func resizing():
	log_debug(str("Resizing: ", get_viewport().size))

func TWViewer() -> Spatial:
	return $TWViewer.get_self()

func init():
	log_debug("init")
	#var init_done : bool = TWViewer().init()
	var result = TWViewer().GDN_globals().connect("tw_status_changed", self, "_on_tw_status_changed") == 0
	log_debug(str("signal tw_status_changed connected (result=", result, ")"))
	_clientstatus = get_clientstatus()
	_client_status = tw_const.status_to_string(_clientstatus)

func deinit():
	log_debug("deinit")
	TWViewer().GDN_globals().disconnect("tw_status_changed", self, "_on_tw_status_changed")
	#TWViewer().deinit()

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
			if debug_window_Active:
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
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
			log_debug("ESC pressed...")
		elif event.is_action_pressed("ui_test"):
			test_action_enabled = !test_action_enabled
			process_test_action = true
		#elif event.is_action_pressed("ui_dump"):
		#	TWViewer().GDN_viewer().dump_required()

func _notification(_what):
	if (_what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		Globals.appstatus = Globals.appstatus_deinit_required
	#elif (_what == Spatial.NOTIFICATION_TRANSFORM_CHANGED):
		#var viewer : Spatial = TWViewer().GDN_viewer()
		#viewer.global_transform = global_transform
	elif (_what == Spatial.NOTIFICATION_ENTER_WORLD):
		log_debug("Notification Spatial.NOTIFICATION_ENTER_WORLD")
		
func _enter_tree():
	log_debug("_enter_tree")
	
func _exit_tree():
	log_debug("_exit_tree")
	exit_world()
	deinit()
	
func _process(_delta):
	if Globals.appstatus == Globals.appstatus_deinit_required:
		Globals.appstatus = Globals.appstatus_deinit_in_progress
		log_debug("Pre deinit...")
		TWViewer().pre_deinit()
		log_debug("Pre deinit completed...")
		Globals.appstatus = Globals.appstatus_quit_required
		return
		
	if Globals.appstatus == Globals.appstatus_quit_required:
		if TWViewer().can_deinit():
			Globals.appstatus = Globals.appstatus_quit_in_progress
			force_app_to_quit()
			return

	if Globals.appstatus != Globals.appstatus_running:
		return
	
	#var clientstatus : int = TWViewer().get_clientstatus()
	#client_status = Globals.Constants.status_to_string(clientstatus)
	
	if not world_initialized && get_clientstatus() >= tw_const.clientstatus_session_initialized:
		enter_world()
		world_initialized = true

	if _clientstatus < Globals.Constants.clientstatus_session_initialized:
		return
	
	fps = Engine.get_frames_per_second()
	
	var viewer : Spatial = TWViewer().GDN_viewer()

	#if init_world_thread.is_alive():
	#	return
	#if init_world_thread.is_active():
	#	init_world_thread.wait_to_finish()
	
	if not world_entered:
		return
		
	if not viewer.initial_world_viewer_pos_set():
		return
	
	var current_camera := get_viewport().get_camera()
	if not scene_initialized:
		#current_camera.global_transform.origin = Vector3(current_camera.global_transform.origin.x, initialCameraAltitudeForced, current_camera.global_transform.origin.z)
		if (initialCameraAltitudeForced != 0):
			current_camera.global_transform.origin.y = initialCameraAltitudeForced
		#current_camera.look_at(initialViewerPos, Vector3(0, 1, 0))
		#current_camera.look_at(Vector3(current_camera.global_transform.origin.x + 1, 0, current_camera.global_transform.origin.z + 1), Vector3(0, 1, 0))
		
		# face to north
		#current_camera.look_at(Vector3(current_camera.global_transform.origin.x, current_camera.global_transform.origin.y, current_camera.global_transform.origin.z - 10000), Vector3(0, 1, 0))
		
		#current_camera.set_yaw(-139, false)
		#current_camera.set_pitch(-7, false)
		
		current_camera.global_transform.origin = Vector3(-7, 2200, -40)	# Procedural HTerrain view
		#current_camera.global_transform.origin = Vector3(-7, 140, -40)		# HTerrain view
		current_camera.set_yaw(-141, false)
		current_camera.set_pitch(-30, false)
		
		#current_camera.global_transform.basis = Basis(Vector3(-1.57, -1.57, 0))
		# DEBUGRIC
		scene_initialized = true
	
	if scene_initialized && !post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
		$BallRigidBody.global_transform.origin = Vector3(initialViewerPos.x + 1, initialViewerPos.y + 1500, initialViewerPos.z + 1)
		#if (initialCameraAltitudeForced != 0):
		#	$BallRigidBody.global_transform.origin.y = initialCameraAltitudeForced
		$BallRigidBody.visible = true
		post_world_deploy_initialized = true
	
	if scene_initialized && post_world_deploy_initialized && _clientstatus >= Globals.Constants.clientstatus_world_deployed:
		ball_pos = $BallRigidBody.global_transform.origin
	
	var _chunk_debug_mode : String = viewer.get_chunk_debug_mode()
	var _cam_chunk_pos = viewer.get_camera_quadrant_name() + " " + viewer.get_camera_chunk_id()
	if (_cam_chunk_pos != cam_chunk_pos or _chunk_debug_mode != chunk_debug_mode):
		var t_aabb : AABB = viewer.get_camera_chunk_local_aabb()
		var t_mesh : Transform = viewer.get_camera_chunk_global_transform_applied()
		cam_chunk_mesh_pos_xzy = String(t_mesh.origin.x) + ":" + String(t_mesh.origin.z) + ":" + String(t_mesh.origin.y)
		cam_chunk_mesh_aabb_x = String(t_mesh.origin.x) + ":" + String(t_mesh.origin.x + t_aabb.size.x)
		cam_chunk_mesh_aabb_y = String(t_mesh.origin.y) + ":" + String(t_mesh.origin.y + t_aabb.size.y)
		cam_chunk_mesh_aabb_z = String(t_mesh.origin.z) + ":" + String(t_mesh.origin.z + t_aabb.size.z)
		t_aabb = viewer.get_camera_chunk_local_debug_aabb()
		t_mesh = viewer.get_camera_chunk_debug_global_transform_applied()
		cam_chunk_dmesh_pos_xzy = String(t_mesh.origin.x) + ":" + String(t_mesh.origin.z) + ":" + String(t_mesh.origin.y)
		cam_chunk_dmesh_aabb_x = String(t_mesh.origin.x) + ":" + String(t_mesh.origin.x + t_aabb.size.x)
		cam_chunk_dmesh_aabb_y = String(t_mesh.origin.y) + ":" + String(t_mesh.origin.y + t_aabb.size.y)
		cam_chunk_dmesh_aabb_z = String(t_mesh.origin.z) + ":" + String(t_mesh.origin.z + t_aabb.size.z)
		chunk_debug_mode = _chunk_debug_mode
		cam_chunk_mesh_pos = t_mesh.origin
		cam_chunk_mesh_aabb = t_aabb
		cam_chunk_pos = _cam_chunk_pos
		
	hit = viewer.get_mouse_hit()
	if hit != prev_hit:
		deltaPos = hit - prev_hit
		prev_hit = hit
	quad_hit_name = viewer.get_mouse_quadrant_hit_name() + " " + viewer.get_mouse_quadrant_hit_tag()
	quad_hit_pos = viewer.get_mouse_quadrant_hit_pos()
	quad_hit_size = viewer.get_mouse_quadrant_hit_size()
	chunk_hit_name = viewer.get_mouse_chunk_hit_name()
	chunk_hit_pos = viewer.get_mouse_chunk_hit_pos()
	chunk_hit_size = viewer.get_mouse_chunk_hit_size()
	chunk_hit_dist_from_cam = viewer.get_mouse_chunk_hit_dist_from_cam()

	# check mouse pos on the ground
	var current_time : int = Time.get_ticks_msec()
	if (process_test_action || current_time - time_of_last_ray > 250):
		time_of_last_ray = current_time
		process_test_action = false
		
		var _test_action_changed := false
		if test_action_enabled != prev_test_action_enabled:
			prev_test_action_enabled = test_action_enabled
			_test_action_changed = true

		#if _test_action_changed:
		#tracked_chunk = TWViewer().GDN_viewer().get_tracked_chunk_str()
		
		mouse_pos_in_viewport = get_viewport().get_mouse_position()

	chunk_grid_global_pos = TWViewer().GDN_viewer().global_transform.origin
	if current_camera:
		#active_camera_global_rot = current_camera.global_transform.basis.get_euler()
		active_camera_global_rot = str(current_camera.global_transform.basis.get_euler()) + " | " + "yaw " + str(int(current_camera.get_yaw(false))) + " pitch " + str(int(current_camera.get_pitch(false)))
		active_camera_global_pos = current_camera.global_transform.origin
		degree_from_north = current_camera.get_angle_from_north()
	
	num_splits = viewer.get_num_splits()
	num_joins = viewer.get_num_joins()
	num_active_chunks = viewer.get_num_active_chunks()
	num_quadrant = str(viewer.get_num_initialized_quadrant()) + ":" + str(viewer.get_num_quadrant())
	num_visible_quadrant = str(viewer.get_num_initialized_visible_quadrant()) + ":" + str(viewer.get_num_visible_quadrant())
	num_empty_quadrant = str(viewer.get_num_empty_quadrant())
	num_flushed_quadrant = str(viewer.get_num_flushed_quadrant())
	var update_quads1_duration : int = viewer.get_update_quads1_duration()
	var update_quads2_duration : int = viewer.get_update_quads2_duration()
	var update_quads3_duration : int = viewer.get_update_quads3_duration()
	process_durations_mcs = String(viewer.get_process_duration()) \
		+ " UQ " + String (update_quads1_duration + update_quads2_duration + update_quads3_duration) \
		+ " (" + String(update_quads1_duration) \
		+ " " + String(update_quads2_duration) \
		+ " " + String(update_quads3_duration)\
		+ ") UC " + String(viewer.get_update_chunks_duration()) \
		+ " UM " + String(viewer.get_update_material_params_duration()) \
		+ " RQ " + String(viewer.get_refresh_quads_duration()) \
		+ " T " + String(viewer.get_mouse_track_hit_duration())
	num_process_locked = viewer.get_num_process_not_owns_lock()
	debug_draw_mode = viewer.get_debug_draw_mode()
		
func enter_world():
	log_debug("Entering world...")
	OS.window_maximized = true
	set_debug_window(true)
	$DebugStats.add_property(self, "_client_status", "")
	$DebugStats.add_property(self, "fps", "")
	$DebugStats.add_property(self, "process_durations_mcs", "")
	$DebugStats.add_property(self, "num_process_locked", "")
	$DebugStats.add_property(self, "debug_draw_mode", "")
	$DebugStats.add_property(self, "chunk_grid_global_pos", "")
	$DebugStats.add_property(self, "degree_from_north", "")
	$DebugStats.add_property(self, "active_camera_global_rot", "")
	$DebugStats.add_property(self, "active_camera_global_pos", "")
	$DebugStats.add_property(self, "num_active_chunks", "")
	$DebugStats.add_property(self, "num_quadrant", "")
	$DebugStats.add_property(self, "num_visible_quadrant", "")
	$DebugStats.add_property(self, "num_empty_quadrant", "")
	$DebugStats.add_property(self, "num_flushed_quadrant", "")
	$DebugStats.add_property(self, "num_splits", "")
	$DebugStats.add_property(self, "num_joins", "")
	#$DebugStats.add_property(self, "cam_chunk_pos", "")
	#$DebugStats.add_property(self, "cam_chunk_mesh_pos_xzy", "")
	#$DebugStats.add_property(self, "cam_chunk_mesh_aabb_x", "")
	#$DebugStats.add_property(self, "cam_chunk_mesh_aabb_z", "")
	#$DebugStats.add_property(self, "cam_chunk_mesh_aabb_y", "")
	#$DebugStats.add_property(self, "chunk_debug_mode", "")
	#$DebugStats.add_property(self, "cam_chunk_dmesh_pos_xzy", "")
	#$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_x", "")
	#$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_z", "")
	#$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_y", "")
	#$DebugStats.add_property(self, "transform_step", "")
	#$DebugStats.add_property(self, "collider_transform_pos", "")
	#$DebugStats.add_property(self, "collider_transform_rot", "")
	#$DebugStats.add_property(self, "collider_transform_scl", "")
	#$DebugStats.add_property(self, "collider_mesh_transform_pos", "")
	#$DebugStats.add_property(self, "collider_mesh_transform_rot", "")
	#$DebugStats.add_property(self, "collider_mesh_transform_scl", "")
	$DebugStats.add_property(self, "mouse_pos_in_viewport", "")
	#$DebugStats.add_property(self, "quadDistFromCamera", "")
	#$DebugStats.add_property(self, "ray_origin", "")
	#$DebugStats.add_property(self, "ray_end", "")
	$DebugStats.add_property(self, "deltaPos", "")
	$DebugStats.add_property(self, "hit", "")
	$DebugStats.add_property(self, "quad_hit_name", "")
	$DebugStats.add_property(self, "quad_hit_pos", "")
	$DebugStats.add_property(self, "quad_hit_size", "")
	$DebugStats.add_property(self, "chunk_hit_name", "")
	$DebugStats.add_property(self, "chunk_hit_pos", "")
	$DebugStats.add_property(self, "chunk_hit_size", "")
	$DebugStats.add_property(self, "chunk_hit_dist_from_cam", "")
	$DebugStats.add_property(self, "ball_pos", "")
	#$DebugStats.add_property(self, "tracked_chunk", "")
	_init_world()
	#init_world_thread = Thread.new()
	#var err := init_world_thread.start(self, "_init_world")
	#if err:
	#	log_debug("Start _init_world failure!")
	log_debug("World entered...")
	world_entered = true
	
func exit_world():
	if world_entered:
		log_debug("Exiting world...")
		$DebugStats.remove_property(self, "_client_status")
		$DebugStats.remove_property(self, "fps")
		$DebugStats.remove_property(self, "process_durations_mcs")
		$DebugStats.remove_property(self, "num_process_locked")
		$DebugStats.remove_property(self, "debug_draw_mode")
		$DebugStats.remove_property(self, "chunk_grid_global_pos")
		$DebugStats.remove_property(self, "degree_from_north")
		$DebugStats.remove_property(self, "active_camera_global_rot")
		$DebugStats.remove_property(self, "active_camera_global_pos")
		$DebugStats.remove_property(self, "num_active_chunks")
		$DebugStats.remove_property(self, "num_quadrant")
		$DebugStats.remove_property(self, "num_visible_quadrant")
		$DebugStats.remove_property(self, "num_empty_quadrant")
		$DebugStats.remove_property(self, "num_flushed_quadrant")
		$DebugStats.remove_property(self, "num_splits")
		$DebugStats.remove_property(self, "num_joins")
		#$DebugStats.remove_property(self, "cam_chunk_pos")
		#$DebugStats.remove_property(self, "cam_chunk_mesh_pos_xzy")
		#$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_x")
		#$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_z")
		#$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_y")
		#$DebugStats.remove_property(self, "chunk_debug_mode")
		#$DebugStats.remove_property(self, "cam_chunk_dmesh_pos_xzy")
		#$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_x")
		#$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_z")
		#$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_y")
		#$DebugStats.remove_property(self, "transform_step")
		#$DebugStats.remove_property(self, "collider_transform_pos")
		#$DebugStats.remove_property(self, "collider_transform_rot")
		#$DebugStats.remove_property(self, "collider_transform_scl")
		#$DebugStats.remove_property(self, "collider_mesh_transform_pos")
		#$DebugStats.remove_property(self, "collider_mesh_transform_rot")
		#$DebugStats.remove_property(self, "collider_mesh_transform_scl")
		$DebugStats.remove_property(self, "mouse_pos_in_viewport")
		#$DebugStats.remove_property(self, "quadDistFromCamera")
		#$DebugStats.remove_property(self, "ray_origin")
		#$DebugStats.remove_property(self, "ray_end")
		$DebugStats.remove_property(self, "deltaPos")
		$DebugStats.remove_property(self, "hit")
		$DebugStats.remove_property(self, "quad_hit_name")
		$DebugStats.remove_property(self, "quad_hit_pos")
		$DebugStats.remove_property(self, "quad_hit_size")
		$DebugStats.remove_property(self, "chunk_hit_name")
		$DebugStats.remove_property(self, "chunk_hit_pos")
		$DebugStats.remove_property(self, "chunk_hit_size")
		$DebugStats.remove_property(self, "chunk_hit_dist_from_cam")
		$DebugStats.remove_property(self, "ball_pos")
		#$DebugStats.remove_property(self, "tracked_chunk")
		#if init_world_thread.is_active():
		#	init_world_thread.wait_to_finish()
		log_debug("World exited...")
		world_entered = false
	
func set_debug_window(active : bool) -> void:
	if active:
		debug_window_Active = true
		$DebugStats.visible = true
	else:
		debug_window_Active = false
		$DebugStats.visible = false
		
func _init_world() -> void:
	log_debug("Initializing world...")
	TWViewer().GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
	log_debug("World initialization completed...")
	
#func _pre_deinit() -> void:
#	log_debug("Pre deinit...")
#	TWViewer().pre_deinit()
#	log_debug("Pre deinit completed...")
	
func force_app_to_quit() -> void:
	get_tree().set_input_as_handled()
	#exit_world()
	get_tree().quit()
	
func set_debug_enabled(debug_mode : bool):
	TWViewer().set_debug_enabled(debug_mode)

func get_clientstatus() -> int:
	return TWViewer().get_clientstatus()
	
func log_debug(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)

func debug_print(var context : String, var text : String, var godot_print : bool):
	TWViewer().debug_print(context, text, godot_print)

func log_info(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)

func info_print(var context : String, var text : String, var godot_print : bool):
	TWViewer().info_print(context, text, godot_print)

func log_error(var text : String) -> void:
	var _text = text
	if Engine.editor_hint:
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)

func error_print(var context : String, var text : String, var godot_print : bool):
	TWViewer().error_print(context, text, godot_print)
