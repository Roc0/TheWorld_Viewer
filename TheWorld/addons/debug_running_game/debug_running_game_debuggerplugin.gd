# res://addons/debug_running_game/debug_running_game_debuggerplugin.gd
# executed only in editor

@tool
extends EditorDebuggerPlugin

const PREFIX = 'debug_running_game'

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)
var _session_id : Variant = null
#var _editor_viewport : SubViewport = null
var _editor_overlay_3d : Control = null
var _editor_overlay_3d_visible : bool = false
var _quit_in_progress : bool = false

func _setup_session(session_id : int) -> void:
	pass

func _has_capture(prefix : String) -> bool:
	return prefix == PREFIX
	
func _capture(message : String, data : Array, session_id : int) -> bool:
	match message:
		"%s:get_id" % PREFIX:
			_quit_in_progress = false
			var all = []
			var sessions = get_sessions()
			for i in sessions.size():
				var session = sessions[i]
				if session.is_active():
					all.push_back(i)
			get_session(session_id).send_message("%s:session_id" % PREFIX, [{"id": session_id, "all": all}])
			log_debug(str(message, " session_id=", session_id))
			return true
		"%s:anchored" % PREFIX:
			_session_id = session_id
			log_debug(str(message, " session_id=", session_id, " editor_overlay=", _editor_overlay_3d))
			#_editor_viewport = EditorInterface.get_editor_viewport_3d(0)
			#log_debug(str(message, " session_id=", session_id, " editor_viewport=", _editor_viewport))
			#var e := _editor_viewport.connect("size_changed", Callable(self, "resizing"))
			#log_debug(str("connect size_changed result=", e))
			send_viewport_info()
			return true
		"%s:not_anchored" % PREFIX:
			#_editor_viewport.disconnect("size_changed", Callable(self, "resizing"))
			send_viewport_info()
			_session_id = null
			#_editor_viewport = null
			log_debug(str(message, " session_id=", session_id))
			return true
			
	return false
	
func quit_in_progress(quit : bool):
	#_editor_overlay_3d_visible = false
	_quit_in_progress = quit
	send_viewport_info()

func set_editor_overlay_3d(editor_overlay : Control) -> void:
	if _editor_overlay_3d == null and editor_overlay != null:
		_editor_overlay_3d = editor_overlay
		var e := _editor_overlay_3d.connect("resized", Callable(self, "editor_overlay_3d_resized"))
		log_debug(str("DEBUGEDIT editor_overlay_3d connect 'resized' result=", e))
		#e = _editor_overlay_3d.connect("focus_entered", Callable(self, "editor_overlay_3d_focus_entered"))
		#log_debug(str("editor_overlay_3d connect 'focus_entered' result=", e))
		#e = _editor_overlay_3d.connect("focus_exited", Callable(self, "editor_overlay_3d_focus_exited"))
		#log_debug(str("editor_overlay_3d connect 'focus_exited' result=", e))
		e = _editor_overlay_3d.connect("visibility_changed", Callable(self, "editor_overlay_3d_visibility_changed"))
		log_debug(str("DEBUGEDIT editor_overlay_3d connect 'visibility_changed' result=", e))
		send_viewport_info()
	
func editor_overlay_3d_resized() -> void:
	#log_debug(str("editor_overlay_resized"))
	send_viewport_info()
	
#func editor_overlay_3d_focus_entered() -> void:
#	log_debug(str("editor_overlay_3d_focus_entered"))

#func editor_overlay_3d_focus_exited() -> void:
#	log_debug(str("editor_overlay_3d_focus_exited"))

func editor_overlay_3d_visibility_changed() -> void:
	#var b : bool = _editor_overlay_3d.visible
	#_editor_overlay_3d_visible = _editor_overlay_3d.is_visible_in_tree()
	#log_debug(str("editor_overlay_3d_visibility_changed visible=", _editor_overlay_3d_visible))
	send_viewport_info()

func send_viewport_info() -> void:
	#if (_session_id != null and _editor_viewport != null):
	#log_debug(str("_session_id=", _session_id, "_editor_overlay", _editor_overlay))
	if (_session_id != null and _editor_overlay_3d != null):
		#var t : Transform2D =  _editor_viewport.get_screen_transform()
		var t : Transform2D =  _editor_overlay_3d.get_screen_transform()
		var viewport_pos : Vector2 = t.origin
		var viewport_size : Vector2 = _editor_overlay_3d.size
		log_debug(str("DEBUGEDIT _quit_in_progress=", _quit_in_progress))
		if _quit_in_progress:
			_editor_overlay_3d_visible = false
		else:
			_editor_overlay_3d_visible = _editor_overlay_3d.is_visible_in_tree()
		get_session(_session_id).send_message("%s:viewport_info" % PREFIX, [{"id": _session_id, "pos": viewport_pos, "size": viewport_size, "visible_3d": _editor_overlay_3d_visible}])
		log_debug(str("DEBUGEDIT sent message viewport_info to game, pos=", viewport_pos, " size=", viewport_size, " visible_3d=", _editor_overlay_3d_visible))

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
