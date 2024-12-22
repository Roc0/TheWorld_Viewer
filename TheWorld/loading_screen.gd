extends Node2D
var _first_resize_done := false
var _end_loading_node : Node
var _tw_viewer : Node
var _loading : bool = false
var _loadingProgress : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TitleVBoxContainer/Title.add_theme_font_size_override("font_size", 50)
	$ProgressVBoxContainer.custom_minimum_size = Vector2(500, 0)
	$ProgressVBoxContainer/LoadingLabel.modulate = Color(0.5, 0, 0)
	$ProgressVBoxContainer/LoadingLabel.add_theme_font_size_override("font_size", 20)
	var v : Viewport = get_viewport()
	var result = v.connect("size_changed", Callable(self, "resize"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not _first_resize_done:
		resize()
		_first_resize_done = true
	
	if _tw_viewer != null and _loading:
		var loadingProgress : float = _tw_viewer.get_loading_progress()
		if (loadingProgress < _loadingProgress):
			loadingProgress = _loadingProgress
		else:
			_loadingProgress = loadingProgress
		set_progress(loadingProgress)
		if (loadingProgress == 100):
			_loading = false
			_loadingProgress = 0
			visible = false
			_end_loading_node.visible = true
	
func resize() -> void:
	var viewport_rect : Rect2 = get_viewport_rect()
	var title_vbox_container_size : Vector2 = $TitleVBoxContainer.size
	var progress_vbox_container_size : Vector2 = $ProgressVBoxContainer.size
	$TitleVBoxContainer.set_offset(SIDE_TOP, (viewport_rect.size.y / 2) - (title_vbox_container_size.y / 2))
	$TitleVBoxContainer.set_offset(SIDE_LEFT, (viewport_rect.size.x / 2) - (title_vbox_container_size.x / 2))
	$ProgressVBoxContainer.set_offset(SIDE_TOP, (viewport_rect.size.y) - (progress_vbox_container_size.y + 100))
	#$ProgressVBoxContainer.set_offset(SIDE_TOP, (viewport_rect.size.y / 2) - (vbox_container_size.y / 2))
	$ProgressVBoxContainer.set_offset(SIDE_LEFT, (viewport_rect.size.x / 2) - (progress_vbox_container_size.x / 2))
	
func init(tw_viewer : Node) -> void:
	_tw_viewer = tw_viewer
	
func activate_loading_screen(end_loading_node : Node) -> void:
	_end_loading_node = end_loading_node
	_end_loading_node.visible = false
	visible = true
	_loading = true
	_loadingProgress = 0

func set_progress(progress : float) -> void:
	$ProgressVBoxContainer/ProgressBar.value = progress
	
