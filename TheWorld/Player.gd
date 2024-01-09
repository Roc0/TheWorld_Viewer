extends CharacterBody3D
var _camera_tracking_player : bool = false

@export var gravity = -9.8
@export var acceleration_speed = 20
@export var inertia_factor = 10
@export var rot_speed = 1.5		#0.85
@export var jump_speed = 10
@export var max_velocity = 200
@export var height_from_floor = 3
@export var height_from_floor_tolerance = 0.5
@export var player_dist_from_terrain : float = 0:
	get = get_player_dist_from_terrain
func get_player_dist_from_terrain() -> float:
	return _player_dist_from_terrain

var _is_at_correct_heigth_from_floor := false
var _target_velocity := Vector3.ZERO
var _player_dist_from_terrain : float = -1
var _def_vert_raycast_target_dist = (height_from_floor + height_from_floor_tolerance) * 2
var _cur_vert_raycast_target_dist = _def_vert_raycast_target_dist
var _player_in_world : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	floor_snap_length = height_from_floor + height_from_floor_tolerance
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
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_player_in_world(value : bool):
	_player_in_world = value
	visible = _player_in_world
	
func get_input(delta):
	if !_camera_tracking_player:
		return
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and _is_at_correct_heigth_from_floor:
		_target_velocity.y += jump_speed
		
	var dot = transform.basis.z.dot(_target_velocity)	# velocity on forward/backward direction 

	var accelerating := false
	if Input.is_action_pressed("ui_forward"):
		var change_dir_increment := 1.0
		if dot > 0:		# going backward
			change_dir_increment = 3.0
		_target_velocity += -transform.basis.z * acceleration_speed * change_dir_increment * delta
		accelerating = true
		#print("ui_forward pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_backward"):
		var change_dir_increment := 1.0
		if dot < 0:		# going forward
			change_dir_increment = 3.0
		_target_velocity += transform.basis.z * acceleration_speed * change_dir_increment * delta
		accelerating = true
		#print("ui_backward pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_right"):
		rotate_y(-rot_speed * delta)
		#print("ui_right pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
	if Input.is_action_pressed("ui_left"):
		rotate_y(rot_speed * delta)
		#print("ui_left pressed ... velocity = " + str(_target_velocity) + " length = " + str(_target_velocity.length()))
		
	var vy = _target_velocity.y
	_target_velocity.y = 0
	
	var velocity_length = _target_velocity.length()
	if not accelerating:
		velocity_length -= inertia_factor * 100 * delta
	
	velocity_length = clamp(velocity_length, 0, max_velocity)
	
	dot = transform.basis.z.dot(_target_velocity)	# velocity on forward/backward direction 
	if dot < 0:		# going forward
		#_target_velocity = -transform.basis.z * velocity_length
		_target_velocity = _target_velocity.lerp(-transform.basis.z * velocity_length, 0.05)
	elif dot > 0:	# going backward
		#_target_velocity = transform.basis.z * velocity_length
		_target_velocity = _target_velocity.lerp(transform.basis.z * velocity_length, 0.05)
		
	_target_velocity.y = vy

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func move_player (delta):
	_is_at_correct_heigth_from_floor = false
	var collision_normal : Vector3 = Vector3.ZERO
	var collision_point : Vector3 = Vector3.ZERO
	
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
			global_position = Vector3(global_position.x, collision_point.y + height_from_floor + height_from_floor_tolerance, global_position.z)
			_target_velocity.y = 0
		elif _player_dist_from_terrain < (height_from_floor - height_from_floor_tolerance):
			var xform : Transform3D
			xform = Transform3D(global_transform.basis, Vector3(global_position.x, collision_point.y + height_from_floor, global_position.z))
			global_transform = global_transform.interpolate_with(xform, 0.2)
			_target_velocity.y = 0
		elif _player_dist_from_terrain < (height_from_floor + height_from_floor_tolerance):
			var xform : Transform3D
			xform = Transform3D(global_transform.basis, Vector3(global_position.x, collision_point.y + height_from_floor, global_position.z))
			global_transform = global_transform.interpolate_with(xform, 0.1)
			_is_at_correct_heigth_from_floor = true
			if (_target_velocity.y < 0):
				_target_velocity.y = 0
		else:
			_target_velocity.y += gravity * delta
	else:
		_target_velocity.y += gravity * delta
		_player_dist_from_terrain = -1
		_cur_vert_raycast_target_dist *= 2
		
	get_input(delta)
	velocity = _target_velocity
	var _b : bool = move_and_slide()
	_target_velocity = velocity

	# align with surface
	if collision_normal.length() > 0:
		var xform = align_with_y(global_transform, collision_normal)
		global_transform = global_transform.interpolate_with(xform, 0.05)
