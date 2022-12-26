extends Spatial

var debug_window_Active : bool = false
var world_entered : bool = false
#var initialViewerPos := Vector3(1195425.176295 + 200, 0, 5465512.560295 +200)
##var initialViewerPos := Vector3(1194125, 0, 5463250)
##var initialViewerPos := Vector3(1194156, 0, 5463351)
#var initialViewerPos := Vector3(1195476, 0, 5467999)
#var initialViewerPos := Vector3(0, 0, 0)
var initialViewerPos := Vector3(2639.48, 0, 338.69)
var initialCameraDistanceFromTerrain = 300
var initialCameraAltitudeForced = 0
#var initialCameraAltitudeForced = 9417
#var initialCameraAltitudeForced = 1485
var initialLevel := 0
#var init_world_thread : Thread
var test_action_enabled : bool = false
var process_test_action : bool = false
var scene_initialized : bool = false
var fps := 0.0
var chunk_grid_global_pos : Vector3
var active_camera_global_rot : Vector3
var active_camera_global_pos : Vector3
var num_splits : int
var num_joins : int
var num_quadrant : String
var num_visible_quadrant : String
var num_active_chunks : int
var process_duration_mcs : int
var num_process_locked : int
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
		
func _ready():
	pass
	
func _input(event):
	var status : int = Globals.get_clientstatus()
	if status != Globals.clientstatus_session_initialized:
		pass
		
	if event is InputEventKey:
		if event.is_action_pressed("ui_toggle_debug_stats"):
			if debug_window_Active:
				set_debug_window(false)
			else:
				set_debug_window(true)
		elif event.is_action_pressed("ui_cancel"):
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
			Globals.debug_print("ESC pressed...")
		elif event.is_action_pressed("ui_test"):
			test_action_enabled = !test_action_enabled
			process_test_action = true
		#elif event.is_action_pressed("ui_dump"):
		#	Globals.GDN_viewer().dump_required()

func _notification(_what):
	if (_what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		Globals.appstatus = Globals.appstatus_deinit_required
		#prepare_deinit_thread = Thread.new()
		#var err := prepare_deinit_thread.start(self, "_prepare_deinit")
		#if err:
		#	Globals.debug_print("Start _prepare_deinit failure!")
	elif (_what == Spatial.NOTIFICATION_TRANSFORM_CHANGED):
		var viewer : Spatial = Globals.GDN_viewer()
		viewer.global_transform = global_transform
	elif (_what == Spatial.NOTIFICATION_ENTER_WORLD):
		print("Notification Spatial.NOTIFICATION_ENTER_WORLD")
		
func _process(_delta):
	if Globals.appstatus == Globals.appstatus_deinit_required:
		Globals.appstatus = Globals.appstatus_deinit_in_progress
		Globals.debug_print("Pre deinit...")
		Globals.GDN_main().pre_deinit()
		Globals.debug_print("Pre deinit completed...")
		Globals.appstatus = Globals.appstatus_quit_required
		return
		
	if Globals.appstatus == Globals.appstatus_quit_required:
		if Globals.GDN_main().can_deinit():
			Globals.appstatus = Globals.appstatus_quit_in_progress
			force_app_to_quit()
			return

	if Globals.appstatus != Globals.appstatus_running:
		return
	
	var status : int = Globals.get_clientstatus()
	if status != Globals.clientstatus_session_initialized:
		return
	
	fps = Engine.get_frames_per_second()
	
	var viewer : Spatial = Globals.GDN_viewer()

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
		# DEBUGRIC
		$CubeMeshTest.mesh.size = Vector3(1, 1, 1)
		$CubeMeshTest.global_transform.origin = Vector3(initialViewerPos.x, initialViewerPos.y + 5, initialViewerPos.z)
		$NoiseMeshTest.mesh.size = Vector2(10, 10)
		$NoiseMeshTest.get_surface_material(0).set_shader_param("height_scale", 1.5)
		$NoiseMeshTest.global_transform.origin = initialViewerPos
		$OmniLightTest.global_transform.origin = Vector3(initialViewerPos.x, initialViewerPos.y + 5, initialViewerPos.z)
		#current_camera.global_transform.origin = Vector3(current_camera.global_transform.origin.x, initialCameraAltitudeForced, current_camera.global_transform.origin.z)
		if (initialCameraAltitudeForced != 0):
			current_camera.global_transform.origin.y = initialCameraAltitudeForced
		#current_camera.look_at(initialViewerPos, Vector3(0, 1, 0))
		current_camera.look_at(Vector3(current_camera.global_transform.origin.x + 1, 0, current_camera.global_transform.origin.z + 1), Vector3(0, 1, 0))
		# DEBUGRIC
		scene_initialized = true
	
	var _chunk_debug_mode : String = viewer.get_chunk_debug_mode()
	var _cam_chunk_pos = viewer.get_camera_quadrant_name() + " " + viewer.get_camera_chunk_id()
	if (_cam_chunk_pos != cam_chunk_pos or _chunk_debug_mode != chunk_debug_mode):
		#var cam_chunk_t : Transform = Globals.GDN_viewer().get_camera_chunk_global_transform_of_aabb()
		#var displ : Vector3 = Vector3(cam_chunk_t.basis.x.x, cam_chunk_t.basis.y.y, cam_chunk_t.basis.z.z) / 2
		#cam_chunk_t.origin += displ
		#$CubeMeshTest.global_transform = cam_chunk_t
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
		#process_test_action = true
		
	if (process_test_action):
		process_test_action = false
		if (test_action_enabled):
			var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
			var mouse_pos_in_viewport : Vector2 = get_viewport().get_mouse_position()
			var camera : Camera = get_tree().root.get_camera()
			var ray_origin : Vector3 = camera.project_ray_origin(mouse_pos_in_viewport)
			var ray_end : Vector3 = ray_origin + camera.project_ray_normal(mouse_pos_in_viewport) * 20000
			var ray_array : Dictionary = space_state.intersect_ray(ray_origin, ray_end)
			var mouse_pos_in_3d : Vector3
			if ray_array.has("position"):
				mouse_pos_in_3d = ray_array["position"]
			
			var chunk_mis : Array
			chunk_mis = get_tree().get_nodes_in_group("ChunkMeshInstanceGroup")
			for chunk_mi in chunk_mis:
				var mi : MeshInstance = MeshInstance.new()
				viewer.add_child(mi)
				mi.add_to_group("TestChunkMeshInstanceGroup")
				mi.name = "Test" + chunk_mi.name
				mi.global_transform.origin = chunk_mi.global_transform.origin
				mi.global_transform.origin.y = 250
				mi.visible = true
				
				#mi.mesh = (chunk_mi as MeshInstance).mesh
				#mi.set_surface_material(0, (chunk_mi as MeshInstance).get_surface_material(0))
				
				#mi.mesh = $PlaneMeshTest.mesh
				#mi.set_surface_material(0, $PlaneMeshTest.get_surface_material(0))
				
				chunk_mi.visible = false
				var lod : int = chunk_mi.get_lod()
				var mesh := PlaneMesh.new()
				var size := Vector2(160 * pow(2, lod), 160 * pow(2, lod))
				mesh.size = size
				mesh.subdivide_width = 32
				mesh.subdivide_depth = 32
				mi.mesh = mesh
				mi.global_transform.origin = Vector3(chunk_mi.global_transform.origin.x + (size.x / 2),
													 mi.global_transform.origin.y,
													 chunk_mi.global_transform.origin.z + (size.y / 2))
				print(mi.name + " - " + str(mi.global_transform.origin) + " - " + str(mesh.size))
				#mi.set_surface_material(0, $PlaneMeshTest.get_surface_material(0))
				
			#$PlaneMeshTest.global_transform.origin = Vector3(cam_chunk_mesh_pos.x + (cam_chunk_mesh_aabb.size.x / 2),
			#	cam_chunk_mesh_pos.y, 
			#	cam_chunk_mesh_pos.z + (cam_chunk_mesh_aabb.size.z / 2))
			#$PlaneMeshTest.visible = true
			#print("$PlaneMeshTest.global_transform.origin=" + str($PlaneMeshTest.global_transform.origin))
			#print("($PlaneMeshTest.mesh as PlaneMesh).size=" + str(($PlaneMeshTest.mesh as PlaneMesh).size))
			#var s := "/root/Main/TheWorld_Main/GDN_TheWorld_Viewer/ChunkDebug_" + cam_chunk_pos.replace(":","")
			#var chunkDebugMeshInstance : MeshInstance = get_node(s)
			#if (chunkDebugMeshInstance != null):
			#	print("chunkDebugMeshInstance.global_transform.origin=" + str(chunkDebugMeshInstance.global_transform.origin))
			#s = "/root/Main/TheWorld_Main/GDN_TheWorld_Viewer/Chunk_" + cam_chunk_pos.replace(":","")
			#var chunkMeshInstance : MeshInstance = get_node(s)
			#if (chunkMeshInstance != null):
			#	print("chunkMeshInstance.global_transform.origin=" + str(chunkMeshInstance.global_transform.origin))
			#	print("mesh 160 x 160")
				#var mdt := MeshDataTool.new()
				#if mdt.create_from_surface(chunkMeshInstance.mesh, 0) == OK:  # Check pass
				#	var v_count := mdt.get_vertex_count()
				#	print("Vertex Count: " + str(v_count))
				#	var dim := sqrt(v_count)
				#	s = ""
				#	var idx : int = 0
				#	for z in range (dim):
				#		for x in range (dim):
				#			s += str(mdt.get_vertex(idx)) + " "
				#			idx = idx + 1
				#		print(s)
				#		s = ""
				#else:
				#	print("Fail...")
		else:
			#$PlaneMeshTest.visible = false
			var chunks : Array = get_tree().get_nodes_in_group("TestChunkMeshInstanceGroup")
			for chunk in chunks:
				chunk.visible = false
				chunk.remove_from_group("TestChunkMeshInstanceGroup")
				chunk.queue_free()
		#var n = get_node("/root/Main/@@2")
		#print(n)

	chunk_grid_global_pos = Globals.GDN_viewer().global_transform.origin
	if current_camera:
		active_camera_global_rot = current_camera.global_transform.basis.get_euler()
		active_camera_global_pos = current_camera.global_transform.origin
	
	num_splits = viewer.get_num_splits()
	num_joins = viewer.get_num_joins()
	num_active_chunks = viewer.get_num_active_chunks()
	num_quadrant = str(viewer.get_num_initialized_quadrant()) + ":" + str(viewer.get_num_quadrant())
	num_visible_quadrant = str(viewer.get_num_initialized_visible_quadrant()) + ":" + str(viewer.get_num_visible_quadrant())
	process_duration_mcs = viewer.get_process_duration()
	num_process_locked = viewer.get_num_process_not_owns_lock()
	debug_draw_mode = viewer.get_debug_draw_mode()
		
func enter_world():
	Globals.debug_print("Entering world...")
	OS.window_maximized = true
	set_debug_window(true)
	$DebugStats.add_property(self, "fps", "")
	$DebugStats.add_property(self, "debug_draw_mode", "")
	$DebugStats.add_property(self, "chunk_grid_global_pos", "")
	$DebugStats.add_property(self, "active_camera_global_rot", "")
	$DebugStats.add_property(self, "active_camera_global_pos", "")
	$DebugStats.add_property(self, "num_active_chunks", "")
	$DebugStats.add_property(self, "process_duration_mcs", "")
	$DebugStats.add_property(self, "num_process_locked", "")
	$DebugStats.add_property(self, "num_splits", "")
	$DebugStats.add_property(self, "num_joins", "")
	$DebugStats.add_property(self, "num_quadrant", "")
	$DebugStats.add_property(self, "num_visible_quadrant", "")
	$DebugStats.add_property(self, "cam_chunk_pos", "")
	$DebugStats.add_property(self, "cam_chunk_mesh_pos_xzy", "")
	$DebugStats.add_property(self, "cam_chunk_mesh_aabb_x", "")
	$DebugStats.add_property(self, "cam_chunk_mesh_aabb_z", "")
	$DebugStats.add_property(self, "cam_chunk_mesh_aabb_y", "")
	$DebugStats.add_property(self, "chunk_debug_mode", "")
	$DebugStats.add_property(self, "cam_chunk_dmesh_pos_xzy", "")
	$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_x", "")
	$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_z", "")
	$DebugStats.add_property(self, "cam_chunk_dmesh_aabb_y", "")
	_init_world()
	#init_world_thread = Thread.new()
	#var err := init_world_thread.start(self, "_init_world")
	#if err:
	#	Globals.debug_print("Start _init_world failure!")
	Globals.debug_print("World entered...")
	world_entered = true
	
func exit_world():
	if world_entered:
		Globals.debug_print("Exiting world...")
		$DebugStats.remove_property(self, "fps")
		$DebugStats.remove_property(self, "debug_draw_mode")
		$DebugStats.remove_property(self, "chunk_grid_global_pos")
		$DebugStats.remove_property(self, "active_camera_global_rot")
		$DebugStats.remove_property(self, "active_camera_global_pos")
		$DebugStats.remove_property(self, "num_active_chunks")
		$DebugStats.remove_property(self, "process_duration_mcs")
		$DebugStats.remove_property(self, "num_process_locked")
		$DebugStats.remove_property(self, "num_splits")
		$DebugStats.remove_property(self, "num_joins")
		$DebugStats.remove_property(self, "num_quadrant")
		$DebugStats.remove_property(self, "num_visible_quadrant")
		$DebugStats.remove_property(self, "cam_chunk_pos")
		$DebugStats.remove_property(self, "cam_chunk_mesh_pos_xzy")
		$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_x")
		$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_z")
		$DebugStats.remove_property(self, "cam_chunk_mesh_aabb_y")
		$DebugStats.remove_property(self, "chunk_debug_mode")
		$DebugStats.remove_property(self, "cam_chunk_dmesh_pos_xzy")
		$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_x")
		$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_z")
		$DebugStats.remove_property(self, "cam_chunk_dmesh_aabb_y")
		#if init_world_thread.is_active():
		#	init_world_thread.wait_to_finish()
		Globals.debug_print("World exited...")
		world_entered = false
	
func set_debug_window(active : bool) -> void:
	if active:
		debug_window_Active = true
		$DebugStats.visible = true
	else:
		debug_window_Active = false
		$DebugStats.visible = false
		
func _init_world() -> void:
	Globals.debug_print("Initializing world...")
	Globals.GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initialCameraDistanceFromTerrain, initialLevel, -1 , -1)
	Globals.debug_print("World initialization completed...")
	
#func _pre_deinit() -> void:
#	Globals.debug_print("Pre deinit...")
#	Globals.GDN_main().pre_deinit()
#	Globals.debug_print("Pre deinit completed...")
	
func force_app_to_quit() -> void:
	get_tree().set_input_as_handled()
	exit_world()
	get_tree().quit()
	
