extends Spatial

var debug_window_Active : bool = false
var world_entered : bool = false
var initialViewerPos := Vector3(1195425.176295 + 100, 0, 5465512.560295 +100)
var initiaCameraDistanceFromTerrain = 20
var initialLevel := 0
var init_world_thread : Thread
var world_initalized : bool = false
var request_to_quit_pending : bool = false
var fps := 0.0
var chunk_grid_global_pos : Vector3
var active_camera_global_rot : Vector3
var active_camera_global_pos : Vector3

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
				
func _process(delta):
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
		
	chunk_grid_global_pos = Globals.GDN_viewer().global_transform.origin
	var current_camera = get_viewport().get_camera()
	if current_camera:
		active_camera_global_rot = current_camera.global_transform.basis.get_euler()
		active_camera_global_pos = current_camera.global_transform.origin
			
func enter_world():
	Globals.debug_print("Entering world...")
	OS.window_maximized = true
	set_debug_window(true)
	$DebugStats.add_property(self, "fps", "")
	$DebugStats.add_property(self, "chunk_grid_global_pos", "")
	$DebugStats.add_property(self, "active_camera_global_rot", "")
	$DebugStats.add_property(self, "active_camera_global_pos", "")
	world_initalized = false
	init_world_thread = Thread.new()
	init_world_thread.start(self, "_init_world")
	world_entered = true
	Globals.debug_print("World entered...")
	
func exit_world():
	if world_entered:
		Globals.debug_print("Exiting world...")
		$DebugStats.remove_property(self, "fps")
		$DebugStats.remove_property(self, "chunk_grid_global_pos")
		$DebugStats.remove_property(self, "active_camera_global_rot")
		$DebugStats.remove_property(self, "active_camera_global_pos")
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
	Globals.debug_print("World initializatoin completed...")
	world_initalized = true
	
func force_app_to_quit() -> void:
	get_tree().set_input_as_handled()
	exit_world()
	get_tree().quit()
	
