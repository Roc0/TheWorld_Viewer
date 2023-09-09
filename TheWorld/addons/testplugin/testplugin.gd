@tool
extends EditorPlugin

const HT_Logger = preload("./util/logger.gd")
var _logger = HT_Logger.get_for(self)

const MYButton = preload("./my_button.gd")

func _enter_tree():
	_logger.debug("_enter_tree")

	# Initialization of the plugin goes here.
	add_custom_type("MyButton", "Button", MYButton, preload("./Node3D.svg"))


func _exit_tree():
	#_logger.debug("_exit_tree")	# causes crash on exit

	# Clean-up of the plugin goes here.
	remove_custom_type("MyButton")
