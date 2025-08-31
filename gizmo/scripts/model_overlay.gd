extends Node
class_name ModelOverlay

@export var interpreter: Interpreter

var _meshes = []
func _process(delta: float) -> void:
	if Engine.get_process_frames() % 5 != 0:
		return
	
	for mesh in _meshes:
		mesh.queue_free()
	
	_meshes.clear()

	var positions := interpreter.mesh.get_face_positions(interpreter.selections.back())
	# Draw the edge line
	_meshes.append(Draw3D.line(
		positions[0],
		positions[1],
		Color("f6cd26"),
		false
	))
	
	_meshes.append(Draw3D.line(
		positions[1],
		positions[2],
		Color("ac6b26"),
		false
	))
	
	_meshes.append(Draw3D.line(
		positions[2],
		positions[0],
		Color("ac6b26"),
		false
	))

	# Draw the point
	_meshes.append(Draw3D.point(positions[0], 0.02, Color("f6cd26"), false))
	
	for mesh in _meshes:
		add_child(mesh)
