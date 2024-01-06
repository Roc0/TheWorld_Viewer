extends CharacterBody3D
var _camera_tracking_player : bool = false

@export var gravity = -9.8
@export var speed = 4
@export var rot_speed = 0.85
@export var jump_speed = 4.5
#@export var player_velocity : Vector3 = Vector3.ZERO:
#	get = get_player_velocity
#func get_player_velocity() -> Vector3:
#	return velocity

var _velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	floor_snap_length = 2
	velocity = Vector3.ZERO
	
func _input(event):
	pass
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
				
func get_input(delta):
	pass
	if !_camera_tracking_player:
		return
		
	var vy = _velocity.y
	#_velocity = Vector3.ZERO
	if Input.is_action_pressed("ui_forward"):
		_velocity += -transform.basis.z * speed
	if Input.is_action_pressed("ui_backward"):
		_velocity += transform.basis.z * speed
	if Input.is_action_pressed("ui_right"):
		rotate_y(-rot_speed * delta)
	if Input.is_action_pressed("ui_left"):
		rotate_y(rot_speed * delta)
	_velocity.y = vy

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _physics_process(delta):
	pass
	move_player(delta)
		
func move_player (delta):
	_velocity = velocity
	
	# Add the gravity.
	if not is_on_floor():
		_velocity.y += gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		_velocity.y += jump_speed * delta
		
	get_input(delta)
	velocity = _velocity
	var b : bool = move_and_slide()
	# align with surface
	if is_on_floor():
		var n : Vector3 = $RayCast3D.get_collision_normal()
		if n.length() > 0:
			var xform = align_with_y(global_transform, n)
			global_transform = global_transform.interpolate_with(xform, 0.2)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	#var space_state = get_world_3d().direct_space_state
	#var query = PhysicsRayQueryParameters3D.create(global_position, Vector3(global_position.x, global_position.y - 5, global_position.z))
	#var result = space_state.intersect_ray(query)
	#if result:
	#	var n : Vector3 = result.normal
	#	var dist : float = (global_transform.origin - result.position).length()
	#	if (dist < 5):
	#		var t : Transform3D = global_transform
