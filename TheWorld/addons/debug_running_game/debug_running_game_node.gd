# res://addons/debug_running_game/debug_running_game_node.gd
# it is executed both in editor and game

@tool
extends Node

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)
var _plugin_tree_entered := false
var _editor_debugger_session_id : Variant = null

const PREFIX = 'debug_running_game'

@export_category("debug_running_game")
var _anchor_changed := true
@export var _anchor : bool = false:
	set = _set_anchor
func _set_anchor(p_anchor : bool):
	_anchor = p_anchor
	_anchor_changed = true

func _enter_tree() -> void:
	log_debug("_enter_tree")
	add_to_group(debug_running_game_global._group_name)
	_plugin_tree_entered = true
	
func _exit_tree() -> void:
	log_debug("_exit_tree")
	remove_from_group(debug_running_game_global._group_name)
	_plugin_tree_entered = false

func _ready() -> void:
	if Engine.is_editor_hint():
		log_debug("_ready")
		#var e := get_tree().get_root().connect("size_changed", Callable(self, "resizing"))
		#log_debug(str("connect size_changed result=", e))
	else:
		log_debug("_ready")
		if EngineDebugger.is_active():
			EngineDebugger.register_message_capture(PREFIX, _on_debug_running_game)
			EngineDebugger.send_message.call_deferred(PREFIX + ":get_id", [])

func _on_debug_running_game(message : String, data : Array) -> bool:
	match message:
		"session_id":
			var info:Dictionary = data[0]
			_editor_debugger_session_id = info.get("id", -1)
			var _all = info.get("all", [])
			log_debug(str("Received message in game", message, ", info=", info))
			return true
		"viewport_info":
			var info:Dictionary = data[0]
			var editor_debugger_session_id : int = info.get("id", -1)
			var pos : Vector2 = info.get("pos", -1)
			var size : Vector2 = info.get("size", -1)
			var visible_3d : bool = info.get("visible_3d", -1)
			#log_debug(str("Received message in game", message, ", pos=", pos, " size=", size, " visible_3d=", visible_3d))
			adjust_pos_size(pos, size, visible_3d)
			return true
	return false

func adjust_pos_size(pos : Vector2, size : Vector2, visible_3d : bool) -> void:
	var w : Window = get_window()
	if _anchor and visible_3d:
		w.mode = Window.MODE_WINDOWED
		w.always_on_top = true
		w.borderless = true
		#pos += Vector2(1, -14)
		#size += Vector2(0, 36)
		w.position = pos
		w.size = size
	else:
		w.mode = Window.MODE_WINDOWED
		w.always_on_top = false
		w.borderless = false

#func set_editor_overlay(editor_overlay : Control) -> void:
#	if not editor_overlay.is_connected("size_changed", Callable(self, "resizing")):
#		var e := editor_overlay.connect("size_changed", Callable(self, "resizing"))
#		log_debug(str("connect 'size_changed' result=", e))
		
#func resizing() -> void:
#	log_debug(str("Resizing"))

func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
		
	if _anchor_changed && _editor_debugger_session_id != null:
		debug_running_game_global.log_debug(str("_anchor: ", _anchor))
		debug_running_game_global.set_game_anchored_in_editor(_anchor)
		if _anchor:
			EngineDebugger.send_message.call_deferred(PREFIX + ":anchored", [])
		else:
			EngineDebugger.send_message.call_deferred(PREFIX + ":not_anchored", [])
		_anchor_changed = false

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
