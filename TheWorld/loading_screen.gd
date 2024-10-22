extends Node2D
var first_resize := false
var scene_root : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer.custom_minimum_size = Vector2(500, 0)
	$VBoxContainer/Label.modulate = Color(0.5, 0, 0)
	$VBoxContainer/Label.add_theme_font_size_override("font_size", 20)
	var v : Viewport = get_viewport()
	var result = v.connect("size_changed", Callable(self, "resize"))
	scene_root = get_tree().current_scene
	#print(scene_root)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not first_resize:
		resize()
		first_resize = true
	
func resize() -> void:
	var viewport_rect : Rect2 = get_viewport_rect()
	var vbox_container_size : Vector2 = $VBoxContainer.size
	#$VBoxContainer.set_anchor(SIDE_TOP, 0.5)
	$VBoxContainer.set_offset(SIDE_TOP, (viewport_rect.size.y / 2) - (vbox_container_size.y / 2))
	#$VBoxContainer.set_anchor(SIDE_LEFT, 0.5)
	$VBoxContainer.set_offset(SIDE_LEFT, (viewport_rect.size.x / 2) - (vbox_container_size.x / 2))
	#$VBoxContainer.set_position(Vector2(0, 0))
	#$VBoxContainer.set_size(get_viewport_rect().size)
	
func set_progress(progress : float) -> void:
	$VBoxContainer/ProgressBar.value = progress
	
