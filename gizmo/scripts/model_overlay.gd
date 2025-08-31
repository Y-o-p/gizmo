extends Node
class_name ModelOverlay


var _meshes = []
func set_face_vertex_positions(positions: PackedVector3Array):
	for mesh in _meshes:
		mesh.queue_free()
	
	_meshes.clear()

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
