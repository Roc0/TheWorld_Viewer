@tool
extends EditorPlugin

const MYButton = preload("./my_button.gd")

func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("MyButton", "Button", MYButton, preload("./Node3D.svg"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("MyButton")
