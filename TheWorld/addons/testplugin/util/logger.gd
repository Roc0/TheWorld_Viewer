# thanks to Zylann (godot_heightmap_plugin)
class HT_LoggerBase:
	var _context := ""
	var verbose : bool = false
	
	func _init(p_context):
		_context = p_context
	
	func get_context() -> String:
		return _context
	
	func is_verbose() -> bool:
		return verbose
	
	func debug(msg: String):
		pass

	func warn(msg: String):
		push_warning("{0}: {1}".format([_context, msg]))
	
	func error(msg: String):
		push_error("{0}: {1}".format([_context, msg]))

	func info(msg: String):
		print(_context, ": ", msg)

class HT_LoggerVerbose extends HT_LoggerBase:
	func _init(p_context: String):
		super(p_context)
		verbose = true
		
	func debug(msg: String):
		print(_context, ": ", msg)


static func get_for(owner: Object) -> HT_LoggerBase:
	# Note: don't store the owner. If it's a Reference, it could create a cycle
	var context = owner.get_script().resource_path.get_file()
	if OS.is_stdout_verbose():
		return HT_LoggerVerbose.new(context)
	return HT_LoggerBase.new(context)

