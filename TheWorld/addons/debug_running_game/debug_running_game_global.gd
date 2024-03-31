# res://addons/debug_running_game/debug_running_game_global.gd
# loadede as autoload: it is executed only in game 
extends Node

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)
var _game_anchored_in_editor := false

const _group_name := "debug_running_game_nodes"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	log_debug("ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func set_game_anchored_in_editor(value : bool) -> void:
	_game_anchored_in_editor = value
	
func get_game_anchored_in_editor() -> bool:
	return _game_anchored_in_editor

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
