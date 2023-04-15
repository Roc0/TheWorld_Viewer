tool

extends EditorPlugin

const tw_viever = preload("./tw_viewer.gd")
const tw_editor_util = preload("./tools/util/editor_util.gd")

#const AUTOLOAD_NAME = "Globals"
#const AUTOLOAD_SCRIPT = "res://addons/twviewer/init/Globals.gd"

func _enter_tree():
	print("TWViewer plugin: _enter_tree")
	
	add_custom_type("TWViever", "Spatial", tw_viever, get_icon("heightmap_node"))
	
	#add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _exit_tree():
	print("TWViewer plugin: _exit_tree")
	
	remove_custom_type("TWViever")
	
	#remove_autoload_singleton(AUTOLOAD_NAME)
	
func get_icon(icon_name: String) -> Texture:
	return tw_editor_util.load_texture("res://addons/zylann.hterrain/tools/icons/icon_" + icon_name + ".svg")
