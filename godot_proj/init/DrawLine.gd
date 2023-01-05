extends Node2D

class Line:
	var id : int
	var color : Color
	var thickness : float
	var a := Vector2()
	var b := Vector2()

var Lines : Array

func _ready():
	Lines = []
	set_process(true)

func _draw():
	for line in Lines:
		draw_line(line.a, line.b, line.color, line.thickness)

func _process(_delta):
	update()

func Draw_Line3D(id : int, vector_a : Vector3, vector_b : Vector3, color : Color, thickness : float):
	var Camera_Node := get_viewport().get_camera()
	for line in Lines:
		if line.id == id:
			line.color = color
			var start : Vector2 = Camera_Node.unproject_position(vector_a)
			var end : Vector2 = Camera_Node.unproject_position(vector_b)
			line.a = start
			line.b = end
			line.thickness = thickness
			return

	var new_line = Line.new()
	new_line.id = id
	new_line.color = color
	var start : Vector2 = Camera_Node.unproject_position(vector_a)
	var end : Vector2 = Camera_Node.unproject_position(vector_b)
	new_line.a = start
	new_line.b = end
	new_line.thickness = thickness
	Lines.append(new_line)

func Remove_Line(id):
	var i = 0
	var found = false
	for line in Lines:
		if line.id == id:
			found = true
			break
		i += 1
	if found:
		Lines.remove(i)
