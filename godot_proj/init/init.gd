extends Node

var GDNTheWorldViewer = preload("res://native/GDN_TheWorld_Viewer.gdns").new()


# Called when the node enters the scene tree for the first time.
func _ready():
	GDNTheWorldViewer.set_debug_enabled(Globals.debug_enabled)
	GDNTheWorldViewer.debug_print(GDNTheWorldViewer.hello("Test", "1", 2))
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
