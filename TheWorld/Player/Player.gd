extends CharacterBody3D
var _camera_tracking_player : bool = false

var _world_camera : Camera3D = null
var _back_camera : Camera3D = null
var _back_camera_container : SubViewportContainer = null
var _satellite_camera : Camera3D = null
var _satellite_camera_container : SubViewportContainer = null
var _previous_position : Vector3
var _is_stopped : bool = true

var tw_const = preload("res://addons/twviewer/tw_const.gd")

@export var gravity = -9.8
@export var acceleration_speed = 20
@export var inertia_factor = 10
@export var rot_speed = 1.5		#0.85
@export var jump_speed = 10
@export var max_velocity = 200		# m/s
@export var height_from_floor = 3.0
@export var height_from_floor_tolerance = 0.5
@export var player_dist_from_terrain : float = 0:
	get = get_player_dist_from_terrain
func get_player_dist_from_terrain() -> float:
	return _player_dist_from_terrain

var _is_at_correct_height_from_floor := false
var _previous_collision_point : Vector3 = Vector3(0, 0, 0)
var _moving_forward : bool

var _target_velocity := Vector3.ZERO
var _player_dist_from_terrain : float = -1
var _def_vert_raycast_target_dist = (height_from_floor + height_from_floor_tolerance) * 2
var _cur_vert_raycast_target_dist = _def_vert_raycast_target_dist
var _player_in_world : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	floor_snap_length = height_from_floor + height_from_floor_tolerance
	#motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	_target_velocity = Vector3.ZERO
	$RayCast3DVert.set_target_position(to_local(global_position + Vector3(0, -_cur_vert_raycast_target_dist, 0)))		# Vertical ray
	visible = _player_in_world
		
func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_toggle_track_player") && visible:
			var camera : Camera3D = get_viewport().get_camera_3d()
			if camera.has_method("track_player") && camera.has_method("untrack_player"):
				if (_camera_tracking_player):
					camera.untrack_player()
					_camera_tracking_player = false
				else:
					camera.track_player(self)
					_camera_tracking_player = true

func _physics_process(_delta):
	#if _player_in_world:
	if _camera_tracking_player:
		move_player(_delta)
		if _previous_position == global_position:
			_is_stopped = true
		else:
			_is_stopped = false
		RenderingServer.global_shader_parameter_set(tw_const.global_shader_param_player_altitude_from_terrain, _player_dist_from_terrain)
		RenderingServer.global_shader_parameter_set(tw_const.global_shader_param_player_pos, global_position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _back_camera != null and _back_camera_container != null:
		if _back_camera_container.visible:
			_back_camera.global_transform = _world_camera.global_transform
			_back_camera.far = _world_camera.far
			_back_camera.near = _world_camera.near
			if _camera_tracking_player:
				_back_camera.rotate_y(PI)
			else:
				var world_camera_direction : Vector3 = -_world_camera.get_global_transform().basis.z
				_back_camera.look_at(_back_camera.position - world_camera_direction)

	if _satellite_camera != null and _satellite_camera_container != null:
		if _satellite_camera_container.visible:
			_satellite_camera.far = 40000
			_satellite_camera.global_transform.origin = (_world_camera.global_position * Vector3(1, 0, 1)) + Vector3(0, 15000, 0)
			_satellite_camera.global_transform.basis = Basis.IDENTITY.rotated(Vector3(1, 0, 0), -PI / 2)	# fixed pointing on north direction
			var _b : Basis = _satellite_camera.global_transform.basis
			_b = Basis.IDENTITY.rotated(Vector3(1, 0, 0), -PI / 2)
			_satellite_camera.far = 40000
			#_satellite_camera.global_transform.basis = _satellite_camera.global_transform.basis.rotated(Vector3(0, 1 ,0), deg_to_rad(-_world_camera.get_angle_from_north_degree()))

func toggle_back_camera_visibility() -> void:
	if _back_camera_container != null:
		_back_camera_container.visible = !_back_camera_container.visible
		_back_camera_container.visible = false

func toggle_satellite_view_visibility() -> void:
	if _satellite_camera_container != null:
		_satellite_camera_container.visible = !_satellite_camera_container.visible
		_satellite_camera_container.visible = false

func set_camera(world_camera : Camera3D, back_camera : Camera3D, back_camera_container : SubViewportContainer, satellite_camera : Camera3D, satellite_camera_container : SubViewportContainer) -> void:
	_world_camera = world_camera
	_back_camera = back_camera
	_back_camera_container = back_camera_container 
	_back_camera_container.visible = false
	_satellite_camera = satellite_camera
	_satellite_camera_container = satellite_camera_container 
	_satellite_camera_container.visible = false

func set_player_in_world(value : bool) -> void:
	_player_in_world = value
	visible = _player_in_world
	_is_at_correct_height_from_floor = false

func get_input(delta) -> bool:
	var input_received : bool = false
	
	if !_camera_tracking_player:
		return input_received
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and _is_at_correct_height_from_floor:
		_target_velocity.y += jump_speed
		input_received = true
		
	var dot = transform.basis.z.dot(_target_velocity)	# velocity on forward/backward direction 

	var velocity_boost : int = 1
	var acceleration_speed_boost : int = 1
	if (Input.is_key_pressed(KEY_CTRL)):
		velocity_boost = 5
		acceleration_speed_boost = 2
		if _world_camera != null:
			_world_camera.set_camera_tracking_speed(20 * velocity_boost)
	else:
		if _world_camera != null:
			_world_camera.set_camera_tracking_speed(20)

	var accelerating := false
	if Input.is_action_pressed("ui_forward"):
		var change_dir_increment := 1.0
		if dot > 0:		# going backward
			change_dir_increment = 3.0
		_target_velocity += -transform.basis.z * (acceleration_speed * acceleration_speed_boost) * change_dir_increment * delta
		accelerating = true
		input_received = true
		#print("ui_forward pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_backward"):
		var change_dir_increment := 1.0
		if dot < 0:		# going forward
			change_dir_increment = 3.0
		_target_velocity += transform.basis.z * (acceleration_speed * acceleration_speed_boost) * change_dir_increment * delta
		accelerating = true
		input_received = true
		#print("ui_backward pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_right"):
		rotate_y(-rot_speed * delta)
		input_received = true
		#print("ui_right pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_left"):
		rotate_y(rot_speed * delta)
		input_received = true
		#print("ui_left pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
		
	var vy = _target_velocity.y
	_target_velocity.y = 0
	
	var velocity_length = _target_velocity.length()
	if not accelerating:
		velocity_length -= inertia_factor * 100 * delta
	
	velocity_length = clamp(velocity_length, 0, max_velocity * velocity_boost)
	
	dot = transform.basis.z.dot(_target_velocity)	# velocity on forward/backward direction 
	if dot < 0:		# going forward
		#_target_velocity = -transform.basis.z * velocity_length
		_target_velocity = _target_velocity.lerp(-transform.basis.z * velocity_length, 0.05)
		_moving_forward = true
	elif dot > 0:	# going backward
		#_target_velocity = transform.basis.z * velocity_length
		_target_velocity = _target_velocity.lerp(transform.basis.z * velocity_length, 0.05)
		_moving_forward = false
		
	_target_velocity.y = vy
	
	return input_received

func align_with_y(xform : Transform3D, new_y : Vector3, rotated_angle : float):
	if rotated_angle != 0:
		new_y = new_y.rotated(xform.basis.x, rotated_angle)
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func move_player (delta):
	_previous_position = global_position
	
	#var t3_debug : Transform3D = global_transform
	var collision_normal : Vector3 = Vector3.ZERO
	var collision_point : Vector3 = Vector3.ZERO
	var point_to_terrain = false
	$RayCast3DVert.set_target_position(to_local(global_position + Vector3(0, -_cur_vert_raycast_target_dist, 0)))		# Vertical ray

	var have_collision_vert : bool = false
	if $RayCast3DVert.is_colliding():
		collision_normal = $RayCast3DVert.get_collision_normal()
		collision_point = $RayCast3DVert.get_collision_point()
		_player_dist_from_terrain = (global_position - collision_point).length()
		if _cur_vert_raycast_target_dist / 2 > _def_vert_raycast_target_dist:
			_cur_vert_raycast_target_dist /= 2
		else:
			_cur_vert_raycast_target_dist = _def_vert_raycast_target_dist
		have_collision_vert = true
	
	if have_collision_vert:
		# TODO: implement check if the collider is really the terrain
		if _player_dist_from_terrain < 0:
			#print(str("1 ", _player_dist_from_terrain, " ", global_transform.origin, " ", global_transform.basis))
			global_position = Vector3(global_position.x, collision_point.y + height_from_floor + height_from_floor_tolerance, global_position.z)
			_target_velocity.y = 0
			_is_at_correct_height_from_floor = false
			_previous_collision_point =  Vector3(0, 0, 0)
		elif _player_dist_from_terrain < (height_from_floor - height_from_floor_tolerance):
			#print(str("2 ", _player_dist_from_terrain, " ", global_transform.origin, " ", global_transform.basis))
			var xform : Transform3D
			xform = Transform3D(global_transform.basis, Vector3(global_position.x, collision_point.y + height_from_floor, global_position.z))
			global_transform = global_transform.interpolate_with(xform, 0.2)
			_target_velocity.y = 0
			_is_at_correct_height_from_floor = false
			_previous_collision_point =  Vector3(0, 0, 0)
		elif _player_dist_from_terrain < (height_from_floor + height_from_floor_tolerance):
			if abs(_previous_collision_point.y - collision_point.y) > 0.1:	
				#print(str("3 ", _player_dist_from_terrain, " ", global_transform.origin, " ", global_transform.basis))
				var xform : Transform3D
				xform = Transform3D(global_transform.basis, Vector3(global_position.x, collision_point.y + height_from_floor, global_position.z))
				global_transform = global_transform.interpolate_with(xform, 0.1)
			else:
				global_transform.origin.y = collision_point.y + height_from_floor
			_previous_collision_point = collision_point
			_is_at_correct_height_from_floor = true
			if (_target_velocity.y < 0):
				_target_velocity.y = 0
		else:
			#print(str("4 ", _player_dist_from_terrain, " ", global_transform.origin, " ", global_transform.basis))
			if _is_at_correct_height_from_floor:
				point_to_terrain = true
			_target_velocity.y += gravity * delta
			_is_at_correct_height_from_floor = false
			_previous_collision_point =  Vector3(0, 0, 0)
	else:
		#print(str("5 ", global_position))
		if _is_at_correct_height_from_floor:
			point_to_terrain = true
			#print("rotate")
		_target_velocity.y += gravity * delta
		_player_dist_from_terrain = -1
		_cur_vert_raycast_target_dist *= 2
		_is_at_correct_height_from_floor = false
		_previous_collision_point =  Vector3(0, 0, 0)
		
	var input_received := get_input(delta)
	#var t_debug : Transform3D = global_transform
	if input_received or not _is_at_correct_height_from_floor or _target_velocity.length() > 2.0:
		velocity = _target_velocity
		var _b : bool = move_and_slide()
		#print(str("5 ", _player_dist_from_terrain, " ", global_transform.origin, " ", global_transform.basis, " ", _b, " ", _target_velocity, " ", _target_velocity.length()))
	else:
		velocity = Vector3.ZERO
		
	#var t1_debug : Transform3D = global_transform
	_target_velocity = velocity

	#return
	# align with surface
	if collision_normal.length() > 0:
		var rotated_angle : float = 0
		var weight : float = 0.05
		var xform : Transform3D
		point_to_terrain = false
		var angleToNewY : float = global_transform.basis.y.angle_to(collision_normal)
		if (angleToNewY > 0.05):
			#print (str("Angle to new Y = ", angleToNewY))
			if point_to_terrain:
				weight = 1
				if _moving_forward:
					rotated_angle = -PI / 12
					#print("rotate forward")
				else:
					rotated_angle = PI / 12
					#print("rotate backward")
				xform = align_with_y(global_transform, collision_normal, rotated_angle)
			else:
				xform = align_with_y(global_transform, collision_normal, rotated_angle)
			global_transform = global_transform.interpolate_with(xform, weight)
	#var t2_debug : Transform3D = global_transform
	#t2_debug = global_transform

func camera_tracking_player() -> bool:
	return _camera_tracking_player

func is_stopped() -> bool:
	return _is_stopped
