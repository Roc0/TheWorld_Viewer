extends MarginContainer

class Property:
	var num_format := "%4.2f"
	var object : Object # The object being tracked.

	var property : NodePath  # The property to display (NodePath).

	var label_ref : Label # A reference to the Label.

	var display  : String # Display option (rounded, etc.)

	func _init(_object : Object, _property : NodePath, _label : Label, _display : String):
		object = _object
		property = _property
		label_ref = _label
		display = _display

	func set_label():
		# Sets the label's text.
		var s = object.name + "/" + property + " : "
		var p = object.get_indexed(property)
		match display:
			"":
				s += str(p)
			"length":
				s += num_format % p.length()
			"round":
				match typeof(p):
					TYPE_INT, TYPE_REAL:
						s += num_format % p
					TYPE_VECTOR2, TYPE_VECTOR3:
						s += str(p.round())
		label_ref.text = s

var props = []  # An array of the tracked properties.

func _process(_delta):
	if not visible:
		return
	for prop in props:
		prop.set_label()
		
func add_property(object : Object, property : NodePath, display : String):
	var label := Label.new()
	label.add_color_override("font_color", Color(1, 0, 0))	# red
	label.add_color_override("font_color", Color(1, 1, 1))	# white
	label.add_color_override("font_color", Color(0, 0, 0))	# black
	#label.set("custom_fonts/font", load("res://debug/roboto_16.tres"))
	$Column.add_child(label)
	props.append(Property.new(object, property, label, display))

func remove_property(object : Object, property : NodePath):
	for prop in props:
		if prop.object == object and prop.property == property:
			if is_instance_valid(prop.label_ref):
				prop.label_ref.queue_free()
			props.erase(prop)
