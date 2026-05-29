const cmdline_argument_world_depth_quads := "WorldDepthQuads"
const cmdline_argument_world_cache_quads := "WorldCacheQuads"
const cmdline_argument_strict_to_build_mode := "StrictToBuildMode"

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
const clientstatus_minimal_world_deployed := 5
const clientstatus_str_minimal_world_deployed := "minimal_world_deployed"
const clientstatus_world_deployed := 6
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
const param_key_initial_map_camera_zoom := "initial_map_camera_zoom"
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
const global_shader_param_player_debug_ground_uv_scale := "gu_debug_uv_scale_per_texture"
const global_shader_param_player_debug_texture_overflow := "gu_debug_texture_overflow"
const global_shader_param_player_texture_overflow_size := "gu_texture_overflow_size"
const global_shader_param_player_splatmap_overflow_size := "gu_splatmap_blending_size"
const global_shader_param_player_texture_new_overflow := "gu_texture_new_overflow"
const global_shader_param_ground_roughness_scale := "gu_ground_roughness_scale"
const global_shader_param_ground_normal_scale := "gu_ground_normal_scale"
const global_shader_param_ground_height_displ := "gu_ground_heightmap_displ"
const global_shader_param_ground_ao_light_affect := "gu_ground_ao_light_affect"

const map_camera_initial_zoom_factor := 0.5

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
	elif status == clientstatus_minimal_world_deployed:
		return clientstatus_str_minimal_world_deployed
	elif status == clientstatus_world_deployed:
		return clientstatus_str_world_deployed
	elif status == clientstatus_world_undeploy_in_progress:
		return clientstatus_str_world_undeploy_in_progress
	else:
		return ""
		
static func check_viewpoint_input(event : InputEventKey, dict : Dictionary)-> void:
	if event is InputEventKey && ((event.is_pressed() and not Engine.is_editor_hint()) or (event.is_released() and Engine.is_editor_hint())):
		if event.keycode == KEY_1:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 1
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 1
		elif event.keycode == KEY_2:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 2
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 2
		elif event.keycode == KEY_3:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 3
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 3
		elif event.keycode == KEY_4:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 4
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 4
		elif event.keycode == KEY_5:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 5
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 5
		elif event.keycode == KEY_6:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 6
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 6
		elif event.keycode == KEY_7:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 7
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 7
		elif event.keycode == KEY_8:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 8
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 8
		elif event.keycode == KEY_9:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 9
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 9
		elif event.keycode == KEY_0:
			if (event.ctrl_pressed and not Engine.is_editor_hint()) or (event.ctrl_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_save'] == -1:
					dict['viewpoint_to_save'] = 0
			elif (event.alt_pressed and not Engine.is_editor_hint()) or (event.alt_pressed and event.shift_pressed and Engine.is_editor_hint()):
				if dict['viewpoint_to_load'] == -1:
					dict['viewpoint_to_load'] = 0
