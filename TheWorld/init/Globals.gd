extends Node

var Constants = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("res://addons/twviewer/util/logger.gd")
var _logger = HT_Logger.get_for(self)

var loadingscreen_scene : Node
var main_scene : Node

#var loading_screen = true
#var loading_screen_to_full_world_deploy = false
var still_loading : bool = false
var ending_loading : bool = false

var appstatus : int
const appstatus_running = 1
const appstatus_deinit_required = 2
const appstatus_deinit_in_progress = 3
const appstatus_quit_required = 4
const appstatus_quit_in_progress = 5

var world_main_node : Node3D
var tw_viewer : Node3D

func _ready():
	#get_tree().set_auto_accept_quit(false)
	var w : Window = get_window()
	w.mode = Window.MODE_MAXIMIZED
	appstatus = appstatus_running
	assert(connect("tree_exiting", Callable(self, "exit_funct").bind()) == 0)
	world_main_node = get_tree().get_root().find_child("TheWorld_Main", true, false)
	log_debug("_ready")
	#get_tree().unload_current_scene()
	#get_tree().current_scene.visible = false
	get_tree().get_root().call_deferred('remove_child', get_tree().current_scene)
	load_loading_screen()
	load_main()

func _notification(_what):
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if world_main_node == null:
		world_main_node = get_tree().get_root().find_child("TheWorld_Main", true, false)
		if world_main_node != null:
			print("Main Scene loaded")
			log_debug("Main Scene loaded")
	
	if tw_viewer == null and world_main_node != null:
		tw_viewer = world_main_node.TWViewer()
		if tw_viewer.loading_screen():
			main_scene.visible = false
		else:
			main_scene.visible = true
		var result = tw_viewer.GDN_globals().connect("tw_status_changed", Callable(self, "_on_tw_status_changed")) == 0
		log_debug(str("signal tw_status_changed connected (result=", result, ")"))
	
	if tw_viewer != null and still_loading:
		#var num_initialized_quadrant : float = tw_viewer.get_num_initialized_quadrant()
		#var num_quadrant : float = 0
		#if tw_viewer.full_world_deploy():
		#	num_quadrant = tw_viewer.get_max_num_quadrant()
		#else:
		#	#num_quadrant = tw_viewer.get_num_quadrant()
		#	num_quadrant = tw_viewer.get_min_num_quadrant()
		#if (num_quadrant > 1 and num_initialized_quadrant > 0):
		#	var progress : float = num_initialized_quadrant / num_quadrant
		#	loadingscreen_scene.set_progress(progress * 100)
		var loadingProgress : float = 0
		if ending_loading:
			loadingProgress = 100
			still_loading = false
		else:
			loadingProgress = tw_viewer.get_loading_progress()
		if loadingProgress > 0:
			loadingscreen_scene.set_progress(loadingProgress)
			
func _on_tw_status_changed(old_client_status : int, new_client_status : int) -> void:
	if tw_viewer == null:
		return
		 
	if (tw_viewer.full_world_deploy() and new_client_status == Constants.clientstatus_world_deployed) \
			or (!tw_viewer.full_world_deploy() and new_client_status == Constants.clientstatus_minimal_world_deployed):
		loadingscreen_scene.visible = false
		main_scene.visible = true
		ending_loading = true

func load_loading_screen() -> void:
	var root = get_tree().get_root()
	var loadingscreen_resource = load("res://LoadingScreen.tscn")
	loadingscreen_scene = loadingscreen_resource.instantiate()
	loadingscreen_scene.visible = true
	still_loading = true
	#var scene_root : Node = loadingscreen_scene.
	#var n := Node2D.new()
	#n.name = "loading_screen_root"
	#n.add_child(loadingscreen_scene)
	#root.call_deferred('add_child', n)
	root.call_deferred('add_child', loadingscreen_scene)
	
func load_main() -> void:
	var root = get_tree().get_root()
	var main_resource = load("res://Main.tscn")
	main_scene = main_resource.instantiate()
	main_scene.visible = false
	#var n := Node3D.new()
	#n.name = "main_root"
	#n.add_child(main_scene)
	#root.call_deferred('add_child', n)
	root.call_deferred('add_child', main_scene)

func exit_funct():
	log_debug ("Quitting...")

func log_debug(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)

func debug_print(context : String, text : String, godot_print : bool) -> void:
	if world_main_node == null:
		return
	world_main_node.debug_print(context, text, godot_print)

func log_info(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)

func info_print(context : String, text : String, godot_print : bool) -> void:
	if world_main_node == null:
		return
	world_main_node.info_print(context, text, godot_print)

func log_error(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)

func error_print(context : String, text : String, godot_print : bool) -> void:
	if world_main_node == null:
		return
	world_main_node.error_print(context, text, godot_print)
