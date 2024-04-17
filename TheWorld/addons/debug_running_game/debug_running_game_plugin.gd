# res://addons/debug_running_game/debug_running_game_plugin.gd
# executed only in editor

@tool
extends EditorPlugin

var _debug_running_game_debuggerplugin = preload("res://addons/debug_running_game/debug_running_game_debuggerplugin.gd").new()
const _debug_running_game_node = preload("./debug_running_game_node.gd")
const AUTOLOAD_NAME = "debug_running_game_global"
const AUTOLOAD_SCRIPT = "res://addons/debug_running_game/debug_running_game_global.gd"
var _init_done : bool = false
#var _anchor_overlay : Control = null

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)

var _overlay_3d : Control = null

const _group_name := "debug_running_game_nodes"

func _enter_tree():
	add_debugger_plugin(_debug_running_game_debuggerplugin)
	add_custom_type("debug_running_game_node", "Node", _debug_running_game_node, preload("./Node.svg"))
	#add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_custom_type("debug_running_game_node")
	#remove_debugger_plugin(_debug_running_game_debuggerplugin)

func _process(delta: float):
	if not _init_done:
		update_overlays()
		#var m : VBoxContainer = EditorInterface.get_editor_main_screen()
		#if m != null:
		#	log_debug(str("editor_main_screen get_child_count(true)", m.get_child_count(true)))
		#	var ctrls : Array = m.get_children(true)
		#	recurse_in_children(ctrls, 0)
		_init_done = true

func _forward_3d_draw_over_viewport(overlay : Control):
	if _overlay_3d == null:
		log_debug(str("DEBUGEDIT _forward_3d_draw_over_viewport control=", overlay))
		_overlay_3d = overlay
	#_anchor_overlay = overlay
	_debug_running_game_debuggerplugin.set_editor_overlay_3d(overlay)
	#if not overlay.is_connected("size_changed", Callable(self, "resizing")):
	#	var e := overlay.connect("size_changed", Callable(self, "resizing"))
	#	log_debug(str("connect 'size_changed' result=", e))
	#var scene : SceneTree = get_tree()
	#var debug_running_game_nodes : Array = scene.get_nodes_in_group(_group_name)
	#for debug_running_game_node in debug_running_game_nodes:
	#	debug_running_game_node.set_editor_overlay(overlay)
		
#func resizing() -> void:
#	log_debug(str("Resizing"))
#	#send_viewport_info()

func _notification(_what):
#	log_debug(str("_notification ", _what))
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		_debug_running_game_debuggerplugin.quit_in_progress(true)

func _handles(object) -> bool:
	if object is _debug_running_game_node:
		return true
	return false

func _make_visible(visible: bool):
	log_debug(str("_make_visible ", visible))

func _edit(object):
	log_debug(str("_edit ", object))

func recurse_in_children(children : Array, num : int):
	if !children.is_empty():
		var indentation : String = ""
		for i in num:
			indentation = indentation + "  "
		for c in children:
			log_debug(str(indentation, c.name, " ", c.get_class(), " ", c.get_child_count(true)))
			recurse_in_children(c.get_children(true), num + 1)

func log_debug(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.debug(_text)

func log_info(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.info(_text)

func log_error(text : String) -> void:
	var _text = text
	if Engine.is_editor_hint():
		_text = str("***EDITOR*** ", _text)
	_logger.error(_text)
