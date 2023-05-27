extends Node

var Constants = preload("res://addons/twviewer/tw_const.gd")

const HT_Logger = preload("res://addons/twviewer/util/logger.gd")
var _logger = HT_Logger.get_for(self)

var appstatus : int
const appstatus_running = 1
const appstatus_deinit_required = 2
const appstatus_deinit_in_progress = 3
const appstatus_quit_required = 4
const appstatus_quit_in_progress = 5

var world_main_node : Node3D

func _ready():
	#get_tree().set_auto_accept_quit(false)
	appstatus = appstatus_running
	assert(connect("tree_exiting", Callable(self, "exit_funct").bind()) == 0)
	world_main_node = get_tree().get_root().find_child("TheWorld_Main", true, false)
	log_debug("_ready")

func _notification(_what):
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func exit_funct():
	log_debug ("Quitting...")

func log_debug(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)
	var ctx : String = _logger.get_context()
	debug_print(ctx, _text, false)

func debug_print(context : String, text : String, godot_print : bool):
	world_main_node.debug_print(context, text, godot_print)

func log_info(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)
	var ctx : String = _logger.get_context()
	info_print(ctx, _text, false)

func info_print(context : String, text : String, godot_print : bool):
	world_main_node.info_print(context, text, godot_print)

func log_error(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
	var ctx : String = _logger.get_context()
	error_print(ctx, _text, false)

func error_print(context : String, text : String, godot_print : bool):
	world_main_node.error_print(context, text, godot_print)
