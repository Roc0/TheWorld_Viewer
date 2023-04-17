extends Node

const clientstatus_error = -1
const clientstatus_str_error = "error"
const clientstatus_uninitialized = 0
const clientstatus_str_uninitialized = "uninitialized"
const clientstatus_initialized = 1
const clientstatus_str_initialized = "initialized"
const clientstatus_connected_to_server = 2
const clientstatus_str_connected_to_server = "connected_to_server"
const clientstatus_session_initialized = 3
const clientstatus_str_session_initialized = "session_initialized"
const clientstatus_world_deploy_in_progress = 4
const clientstatus_str_world_deploy_in_progress = "world_deploy_in_progress"
const clientstatus_world_deployed = 5
const clientstatus_str_world_deployed = "world_deployed"

var appstatus : int
const appstatus_running = 1
const appstatus_deinit_required = 2
const appstatus_deinit_in_progress = 3
const appstatus_quit_required = 4
const appstatus_quit_in_progress = 5

var debug_enabled : bool = true
var debug_enable_set : bool = false

var num_vertices_per_chunk_side : int
var bitmap_resolution : int
var lod_max_depth : int
var num_lods : int
var _result : bool
var world_initialized : bool = false
#var main_node : Node
var world_main_node : Spatial

func _ready():
	get_tree().set_auto_accept_quit(false)
	appstatus = appstatus_running
	
	assert(connect("tree_exiting", self, "exit_funct",[]) == 0)
	OS.set_window_maximized(true)
	
	world_main_node = get_tree().get_root().find_node("TheWorld_Main", true, false)
	world_main_node.init()
	debug_print("Globals: _ready")

#func TWViewer() -> Spatial:
#	return world_main_node.TWViewer()

func _notification(_what):
	if (_what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var clientstatus : int = get_clientstatus()
	if clientstatus >= clientstatus_session_initialized && !debug_enable_set:
		debug_enable_set = true
		world_main_node.set_debug_enabled(debug_enabled)
		
	if clientstatus < clientstatus_session_initialized:
		return

	if not world_initialized:
		initialize_world()
		world_initialized = true

func initialize_world() -> void:
	world_main_node.enter_world()
	
func unitialize_world() -> void:
	world_main_node.exit_world()

func get_clientstatus() -> int:
	return world_main_node.get_clientstatus()

func get_appstatus() -> int:
	return appstatus
	
func exit_funct():
	debug_print ("Quitting...")
	unitialize_world()
	world_main_node.deinit()
	#GDN_main().queue_free()	# crash on exit

func debug_print(var text : String):
	world_main_node.debug_print(text)
	

func status_to_string(var status : int) -> String:
	if status == clientstatus_error:
		return clientstatus_str_error
	elif status == clientstatus_uninitialized:
		return clientstatus_str_uninitialized
	elif status == clientstatus_initialized:
		return clientstatus_str_initialized
	elif status == clientstatus_connected_to_server:
		return clientstatus_str_connected_to_server
	elif status == clientstatus_session_initialized:
		return clientstatus_str_session_initialized
	elif status == clientstatus_world_deploy_in_progress:
		return clientstatus_str_world_deploy_in_progress
	elif status == clientstatus_world_deployed:
		return clientstatus_str_world_deployed
	else:
		return ""
