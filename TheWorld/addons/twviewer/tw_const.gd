const clientstatus_error := -1
const clientstatus_str_error := "error"
const clientstatus_uninitialized := 0
const clientstatus_str_uninitialized := "uninitialized"
const clientstatus_initialized := 1
const clientstatus_str_initialized := "initialized"
const clientstatus_connected_to_server := 2
const clientstatus_str_connected_to_server := "connected_to_server"
const clientstatus_session_initialized := 3
const clientstatus_str_session_initialized := "session_initialized"
const clientstatus_world_deploy_in_progress := 4
const clientstatus_str_world_deploy_in_progress := "world_deploy_in_progress"
const clientstatus_world_deployed := 5
const clientstatus_str_world_deployed := "world_deployed"
const clientstatus_world_undeploy_in_progress := 100
const clientstatus_str_world_undeploy_in_progress := "world_undeploy_in_progress"

const tw_viewer_node_name := "TWViewer"
const tw_gdn_main_node_name := "GDN_TW_Main"
const tw_gdn_globals_node_name := "GDN_TW_Globals"
const tw_gdn_viewer_node_name := "GDN_TW_Viewer"
const tw_gdn_camera_node_name := "GDN_TW_Camera"
const tw_gdn_edit_mode_ui_node_name := "GDN_TW_EditModeUI"

const config_file := "user://TheWorldConfig.cfg"
const param_group_camera := "Camera"
const param_key_initial_camera_pos := "initial_position"
const param_key_initial_camera_ypr := "initial_ypr"
const param_key_viewpoint_camera_pos := "viewpoint_position_"
const param_key_viewpoint_camera_ypr := "viewpoint_ypr_"
const param_group_player := "Player"
const param_key_player_pos := "initial_position"
const param_key_player_basis := "initial_basis"

const custom_cameras_group := "TheWorldViewerCustomCameras"
const global_shader_param_grid_step := "gu_grid_step"
const global_shader_param_camera_altitude_from_terrain := "gu_camera_altitude_from_terrain"
const global_shader_param_camera_pos := "gu_camera_pos"
const global_shader_param_player_pos := "gu_player_pos"
const global_shader_param_player_altitude_from_terrain := "gu_player_altitude_from_terrain"
const global_shader_param_player_texture_blending_size := "gu_texture_blending_size"
const global_shader_param_player_splatmap_blending_size := "gu_splatmap_blending_size"

static func status_to_string(status : int) -> String:
	if status == clientstatus_error:
		return clientstatus_str_error
	elif status == clientstatus_uninitialized:
		return clientstatus_str_uninitialized
	elif status == clientstatus_initialized:
		return clientstatus_str_initialized
	elif status == clientstatus_connected_to_server:
		return clientstatus_str_connected_to_server
	elif status == clientstatus_session_initialized:
		return clientstatus_str_session_initialized
	elif status == clientstatus_world_deploy_in_progress:
		return clientstatus_str_world_deploy_in_progress
	elif status == clientstatus_world_deployed:
		return clientstatus_str_world_deployed
	else:
		return ""
		
static func check_viewpoin_input(event : InputEventKey, dict : Dictionary)-> void:
	if event is InputEventKey && event.is_pressed():
		if event.keycode == KEY_1:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 1
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 1
		elif event.keycode == KEY_2:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 2
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 2
		elif event.keycode == KEY_3:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 3
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 3
		elif event.keycode == KEY_4:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 4
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 4
		elif event.keycode == KEY_5:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 5
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 5
		elif event.keycode == KEY_6:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 6
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 6
		elif event.keycode == KEY_7:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 7
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 7
		elif event.keycode == KEY_8:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 8
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 8
		elif event.keycode == KEY_9:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == 0:
					dict['viewpoint_to_save'] = 9
			elif event.alt_pressed:
				if dict['viewpoint_to_load'] == 0:
					dict['viewpoint_to_load'] = 9

static func save_current_position(viewpoint : int, camera : Camera3D, config : ConfigFile, config_file_name : String) -> void:
	# Warning this static func does not save player pos / transform
	if camera != null && camera.has_method("get_yaw") && camera.has_method("get_pitch") && camera.has_method("get_roll"):
		#var config = ConfigFile.new()
		#@warning_ignore("unused_variable")
		#var err = config.load(config_file_name)
		@warning_ignore("unassigned_variable")
		var camera_ypr : Vector3
		camera_ypr.x = camera.get_yaw(false)
		camera_ypr.y = camera.get_pitch(false)
		camera_ypr.z = camera.get_roll(false)
		var param_key_camera_pos := ""
		var param_key_camera_ypr := ""
		if viewpoint == 0:
			param_key_camera_pos = param_key_initial_camera_pos
			param_key_camera_ypr = param_key_initial_camera_ypr
		else:
			param_key_camera_pos = param_key_viewpoint_camera_pos + str(viewpoint)
			param_key_camera_ypr = param_key_viewpoint_camera_ypr + str(viewpoint)
		config.set_value(param_group_camera, param_key_camera_pos, camera.global_transform.origin)
		config.set_value(param_group_camera, param_key_camera_ypr, camera_ypr)
		config.save(config_file_name)

static func load_position(viewpoint : int, config : ConfigFile, viewer) -> void:
	var param_key_camera_pos := ""
	var param_key_camera_ypr := ""
	if viewpoint == 0:
		param_key_camera_pos = param_key_initial_camera_pos
		param_key_camera_ypr = param_key_initial_camera_ypr
	else:
		param_key_camera_pos = param_key_viewpoint_camera_pos + str(viewpoint)
		param_key_camera_ypr = param_key_viewpoint_camera_ypr + str(viewpoint)
	var camera_position : Variant = config.get_value(param_group_camera, param_key_camera_pos)
	var camera_ypr : Variant = config.get_value(param_group_camera, param_key_camera_ypr)
	if camera_position != null and camera_ypr != null:
		viewer._set_camera_param_initial_pos(camera_position)
		viewer._set_camera_param_initial_yaw_pitch_roll(camera_ypr)
