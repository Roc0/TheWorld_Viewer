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

const tw_viewer_node_name := "TWViewer"
const tw_gdn_main_node_name := "GDN_TW_Main"
const tw_gdn_globals_node_name := "GDN_TW_Globals"
const tw_gdn_viewer_node_name := "GDN_TW_Viewer"
const tw_gdn_camera_node_name := "GDN_TW_Camera"
const tw_gdn_edit_mode_ui_node_name := "GDN_TW_EditModeUI"

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
