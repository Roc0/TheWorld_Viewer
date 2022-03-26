extends Spatial

var debug_window_Active : bool = false
var world_entered : bool = false
var initialViewerPos := Vector3(1195425.176295 + 200, 0, 5465512.560295 +200)
var initiaCameraDistanceFromTerrain = 200
var initialLevel := 0
var init_world_thread : Thread
var world_initalized : bool = false
var request_to_quit_pending : bool = false
var scene_initialized : bool = false
var fps := 0.0
var chunk_grid_global_pos : Vector3
var active_camera_global_rot : Vector3
var active_camera_global_pos : Vector3
var num_splits : int
var num_joins : int
var cameraChunkId : String = ""

func _ready():
	pass

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_toggle_debug_window"):
			if debug_window_Active:
				set_debug_window(false)
			else:
				set_debug_window(true)
		elif event.is_action_pressed("ui_cancel"):
			request_to_quit_pending = true
		elif event.is_action_pressed("ui_dump"):
			Globals.GDN_viewer().dump_required()
				
func _process(_delta):
	fps = Engine.get_frames_per_second()
	
	if init_world_thread.is_alive():
		return
	if init_world_thread.is_active():
		init_world_thread.wait_to_finish()
	if request_to_quit_pending:
		force_app_to_quit()
	if not world_entered:
		return
	if not world_initalized:
		return
	
	var current_camera := get_viewport().get_camera()
	var viewer = Globals.GDN_viewer()
	if not scene_initialized:
		#var cube_mesh = $MeshProva.mesh as CubeMesh
		#cube_mesh.size = Vector3(1, 1, 1)
		scene_initialized = true	
	
	var _cameraChunkId = viewer.get_camera_chunk_id()
	if (_cameraChunkId != cameraChunkId):
		#var camera_chunk_t : Transform = Globals.GDN_viewer().get_camera_chunk_global_transform_of_aabb()
		#var displ : Vector3 = Vector3(camera_chunk_t.basis.x.x, camera_chunk_t.basis.y.y, camera_chunk_t.basis.z.z) / 2
		#camera_chunk_t.origin += displ
		#$MeshProva.global_transform = camera_chunk_t
		cameraChunkId = _cameraChunkId

	chunk_grid_global_pos = Globals.GDN_viewer().global_transform.origin
	if current_camera:
		active_camera_global_rot = current_camera.global_transform.basis.get_euler()
		active_camera_global_pos = current_camera.global_transform.origin
	
	num_splits = viewer.get_num_splits()
	num_joins = viewer.get_num_joins()
		
func enter_world():
	Globals.debug_print("Entering world...")
	OS.window_maximized = true
	set_debug_window(true)
	$DebugStats.add_property(self, "fps", "")
	$DebugStats.add_property(self, "chunk_grid_global_pos", "")
	$DebugStats.add_property(self, "active_camera_global_rot", "")
	$DebugStats.add_property(self, "active_camera_global_pos", "")
	$DebugStats.add_property(self, "num_splits", "")
	$DebugStats.add_property(self, "num_joins", "")
	$DebugStats.add_property(self, "cameraChunkId", "")
	world_initalized = false
	init_world_thread = Thread.new()
	var err := init_world_thread.start(self, "_init_world")
	if err:
		Globals.debug_print("Start _init_world failure!")
	world_entered = true
	Globals.debug_print("World entered...")
	
func exit_world():
	if world_entered:
		Globals.debug_print("Exiting world...")
		$DebugStats.remove_property(self, "fps")
		$DebugStats.remove_property(self, "chunk_grid_global_pos")
		$DebugStats.remove_property(self, "active_camera_global_rot")
		$DebugStats.remove_property(self, "active_camera_global_pos")
		$DebugStats.remove_property(self, "num_splits")
		$DebugStats.remove_property(self, "num_joins")
		$DebugStats.remove_property(self, "cameraChunkId")
		if init_world_thread.is_active():
			init_world_thread.wait_to_finish()
		world_initalized = false
		world_entered = false
		Globals.debug_print("World exited...")
	
func set_debug_window(active : bool) -> void:
	if active:
		debug_window_Active = true
		$DebugStats.visible = true
	else:
		debug_window_Active = false
		$DebugStats.visible = false
		
func _init_world() -> void:
	Globals.debug_print("Initializing world...")
	Globals.GDN_viewer().reset_initial_world_viewer_pos(initialViewerPos.x, initialViewerPos.z, initiaCameraDistanceFromTerrain, initialLevel)
	Globals.debug_print("World initialization completed...")
	world_initalized = true
	
func force_app_to_quit() -> void:
	get_tree().set_input_as_handled()
	exit_world()
	get_tree().quit()
	
