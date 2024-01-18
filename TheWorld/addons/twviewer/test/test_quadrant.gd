@tool
extends MeshInstance3D

const HT_Logger = preload("../util/logger.gd")
const tw_constants = preload("../tw_const.gd")

var plugin : EditorPlugin = null

var _viewer : Node3D = null
var _plane_mesh : PlaneMesh = null
var _initialized = false
var _close_requested : bool = false
var _quitting : bool = false
var _logger = HT_Logger.get_for(self)
var _tree_entered := false
var _render_changed := false

var _material : ShaderMaterial = null
var _quadrant_pos : Vector2 = Vector2.ZERO

@export var _render := false:
	set = _set_render
@export var _pos := Vector2(0.0, 0.0)
@export var _size : int = 0
@export var _points_per_size : int = 0

func _set_render(b : bool) -> void:
	if (_render != b):
		_render = b
		_render_changed = true
func _set_size_used(f : float) -> void:
	pass
func _set_step_used(f : float) -> void:
	pass
func _set_points_per_size(f : int) -> void:
	pass

func set_plugin(plugin_ : EditorPlugin) -> void:
	plugin = plugin_
	#_logger.debug(str("set_plugin = ", plugin_))

# Called when the node enters the scene tree for the first time.
func _ready():
	_material = ShaderMaterial.new()
	#var shader : Shader = load("res://addons/twviewer/test/regularChunk.gdshader")
	var shader : Shader = load("res://addons/twviewer/test/test_quadrant.tres")
	_material.shader = shader


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not _initialized and not _close_requested:
		_viewer = find_node_by_name(tw_constants.tw_viewer_node_name)
		if _viewer != null and _viewer.has_method("is_ready") and _viewer.is_ready() and _viewer.is_really_ready():
			_initialized = true
	
	if _render_changed and _initialized:
		if _render:
			render()
		else:
			clear_rendering()
		_render_changed = false
		
func _notification(_what):
	#_logger.debug(str("_notification: ", self.name, " ", self.get_path(), " ", _what))
	
	if (_what == NOTIFICATION_WM_CLOSE_REQUEST):
		_quitting = true
		_logger.debug("_notification: NOTIFICATION_WM_CLOSE_REQUEST ")
		_close_requested = true
		
func _enter_tree():
	_logger.debug("_enter_tree")
	_render = false
	clear_shader_params()
	_tree_entered = true

func _exit_tree():
	if not _quitting:
		_logger.debug(str("_exit_tree _init_done=", _initialized, ", quitting=", _quitting))
	clear_shader_params()
	if plugin != null:
		plugin.remove_test_quadrant_from_array(self)
	
func _apply_changes() -> void:
	_logger.debug(str("_apply_changes"))
	clear_shader_params()

func clear_shader_params() -> void:
	_logger.debug(str("clear_shader_params"))
	var mat : ShaderMaterial = _material
	#mat = get_active_material(0)
	if mat != null:
		_logger.debug(str("clear_shader_params: material"))
		mat.set_shader_parameter("u_terrain_heightmap", null)
		mat.set_shader_parameter("u_terrain_normalmap", null)
		mat.set_shader_parameter("u_terrain_colormap", null)
		mat.set_shader_parameter("u_terrain_splatmap", null)
		mat.set_shader_parameter("u_terrain_globalmap", null)
	clear_rendering()
	_set_render(false)
	
func find_node_by_name(node_name : String) -> Node:
	if Engine.is_editor_hint():
		var scene : SceneTree = get_tree()
		if scene == null:
			return null
		var node : Node = get_tree().get_edited_scene_root().find_child(node_name, true, false)
		return node
	else:
		var scene : SceneTree = null
		if _tree_entered:
			scene = get_tree()
		if scene == null:
			return null
		var node : Node = get_tree().get_root().find_child(node_name, true, false)
		return node

func render():
	#return
	var size : int = _size
	if size == 0:
		size = _viewer.GDN_globals().quadrant_size_in_wus()
	var points_per_size : int = _points_per_size
	if points_per_size == 0:
		points_per_size = size / _viewer.GDN_globals().quadrant_step_in_wus()
	else:
		points_per_size -= 1

	var gdn_viewer = _viewer.GDN_viewer()
	if (gdn_viewer == null):
		_logger.debug(str("gdn_viewer null"))
		return
	var b : bool = gdn_viewer.load_quadrant_data(_pos.x, _pos.y, 0)
	_quadrant_pos = gdn_viewer.get_quadrant_pos()
	
	_logger.debug(str("size=", size, " points_per_size=", points_per_size))
	_plane_mesh = PlaneMesh.new()
	_plane_mesh.size = Vector2(size, size)
	_plane_mesh.subdivide_depth = points_per_size - 1
	_plane_mesh.subdivide_width = points_per_size - 1
	_size = size
	mesh = _plane_mesh
	material_override = _material
	global_transform.origin = Vector3(_quadrant_pos.x + 2048, 0, _quadrant_pos.y + 2048)
	var gt : Transform3D = Transform3D(basis, Vector3(0, 0, 0))	# upper left corner of plane on origin 
	var inv_gt : Transform3D = gt.affine_inverse()
	var normal_basis : Basis = gt.basis.inverse().transposed()
	
	var array : Array = _plane_mesh.surface_get_arrays(0)
	_points_per_size = sqrt(array[0].size())
	_logger.debug(str("size=", size, " points_per_size=", points_per_size, " vertices=", array[0].size()))
	
	#_logger.debug(str("array size = ", array.size()))
	#_logger.debug(str("vertices = ", _points_per_size))
	#_logger.debug(str("AABB = ", get_aabb()))
	#_logger.debug(str("MeshInstance transform = ", global_transform))
	#_logger.debug(str("Shader global transform = ", gt))
	
	var mat : ShaderMaterial = get_active_material(0)
	if mat == null:
		_logger.debug(str("no material active"))
		return
		
	_logger.debug(str("Shader = ", mat.get_shader().get_path()))
	
	var tex : ImageTexture
	
	var image : Image = gdn_viewer.get_quadrant_heightmap_image()
	if image != null:
		tex = ImageTexture.create_from_image(image)
		mat.set_shader_parameter("u_terrain_heightmap", tex)

	image = gdn_viewer.get_quadrant_normalmap_image()
	if image != null:
		tex = ImageTexture.create_from_image(image)
		mat.set_shader_parameter("u_terrain_normalmap", tex)

	image = gdn_viewer.get_quadrant_splatmap_image()
	if image != null:
		tex = ImageTexture.create_from_image(image)
		mat.set_shader_parameter("u_terrain_splatmap", tex)

	image = gdn_viewer.get_quadrant_globalmap_image()
	if image != null:
		tex = ImageTexture.create_from_image(image)
		mat.set_shader_parameter("u_terrain_globalmap", tex)

	image = gdn_viewer.get_quadrant_colormap_image()
	if image != null:
		tex = ImageTexture.create_from_image(image)
		mat.set_shader_parameter("u_terrain_colormap", tex)

	mat.set_shader_parameter("u_terrain_inverse_transform", inv_gt)
	#RenderingServer.global_shader_parameter_set("gu_terrain_inverse_transform", inv_gt)
	_logger.debug(str("u_terrain_inverse_transform = ", inv_gt))

	mat.set_shader_parameter("u_terrain_normal_basis", normal_basis)
	_logger.debug(str("u_terrain_normal_basis = ", normal_basis))

	var step = _viewer.GDN_globals().quadrant_step_in_wus()
	mat.set_shader_parameter("u_grid_step", step)
	#RenderingServer.global_shader_parameter_set("gu_grid_step", step)
	_logger.debug(str("u_grid_step = ", step))

	# low
	tex = gdn_viewer.get_ground_texture_albedo_bump(gdn_viewer.get_ground_texture_name(0))
	if tex != null:
		mat.set_shader_parameter("u_ground_albedo_bump_0", tex)

	tex = gdn_viewer.get_ground_texture_normal_roughness(gdn_viewer.get_ground_texture_name(0))
	if tex != null:
		mat.set_shader_parameter("u_ground_normal_roughness_0", tex)

	# high
	tex = gdn_viewer.get_ground_texture_albedo_bump(gdn_viewer.get_ground_texture_name(1))
	if tex != null:
		mat.set_shader_parameter("u_ground_albedo_bump_1", tex)

	tex = gdn_viewer.get_ground_texture_normal_roughness(gdn_viewer.get_ground_texture_name(1))
	if tex != null:
		mat.set_shader_parameter("u_ground_normal_roughness_1", tex)

	# dirt
	tex = gdn_viewer.get_ground_texture_albedo_bump(gdn_viewer.get_ground_texture_name(2))
	if tex != null:
		mat.set_shader_parameter("u_ground_albedo_bump_2", tex)

	tex = gdn_viewer.get_ground_texture_normal_roughness(gdn_viewer.get_ground_texture_name(2))
	if tex != null:
		mat.set_shader_parameter("u_ground_normal_roughness_2", tex)

	# rocks
	tex = gdn_viewer.get_ground_texture_albedo_bump(gdn_viewer.get_ground_texture_name(3))
	if tex != null:
		mat.set_shader_parameter("u_ground_albedo_bump_3", tex)

	tex = gdn_viewer.get_ground_texture_normal_roughness(gdn_viewer.get_ground_texture_name(3))
	if tex != null:
		mat.set_shader_parameter("u_ground_normal_roughness_3", tex)

	var plane : Plane = gdn_viewer.get_shader_param_ground_uv_scale()
	var v4 : Vector4 = Vector4(plane.normal.x, plane.normal.y, plane.normal.z, plane.d)
	mat.set_shader_parameter("u_ground_uv_scale_per_texture", v4)
	_logger.debug(str("u_ground_uv_scale_per_texture = ", v4))

	b = gdn_viewer.get_shader_param_depth_blending()
	mat.set_shader_parameter("u_depth_blending", b)
	_logger.debug(str("u_depth_blending = ", b))
	
	b = gdn_viewer.get_shader_param_triplanar()
	mat.set_shader_parameter("u_triplanar", b)
	_logger.debug(str("u_triplanar = ", b))
	
	plane = gdn_viewer.get_shader_param_tile_reduction()
	v4 = Vector4(plane.normal.x, plane.normal.y, plane.normal.z, plane.d)
	mat.set_shader_parameter("u_tile_reduction_per_texture", v4)
	_logger.debug(str("u_tile_reduction_per_texture = ", v4))
	
	gdn_viewer.clear_quadrant_data()

func clear_rendering():
	material_override = null
	mesh = null
