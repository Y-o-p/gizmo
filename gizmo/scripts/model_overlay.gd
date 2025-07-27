extends Node

@export var selection: Selection

var _meshes = []
func _process(delta: float) -> void:
	if Engine.get_process_frames() % 5 != 0:
		return
	
	for mesh in _meshes:
		mesh.queue_free()
	
	_meshes.clear()

	var face_vertices = selection.get_selected_face_vertices()
	var edge_vertices = selection.get_selected_edge_vertices()

	# Draw the face lines
	for idx in range(len(face_vertices)):
		var a = face_vertices[idx]
		var b = face_vertices[(idx + 1) % len(face_vertices)]
		if a in edge_vertices and b in edge_vertices:
			continue

		_meshes.append(Draw3D.line(
			selection.model.tool.get_vertex(a),
			selection.model.tool.get_vertex(b),
			Color("ac6b26"),
			false
		))

	# Draw the edge line
	_meshes.append(Draw3D.line(
		selection.model.tool.get_vertex(edge_vertices[0]),
		selection.model.tool.get_vertex(edge_vertices[1]),
		Color("f6cd26"),
		false
	))

	# Draw the point
	var vertex = selection.get_selected_vertex()
	_meshes.append(Draw3D.point(selection.model.tool.get_vertex(vertex), 0.02, Color("f6cd26"), false))
	
	# Draw all selected vertices
	for selected_vertex in selection.selected_vertices:
		_meshes.append(Draw3D.point(selection.model.tool.get_vertex(selected_vertex), 0.02, Color("725956")))
	
	for mesh in _meshes:
		add_child(mesh)
	
func find_sequence(array: Array, sequence: Array) -> int:
	for i in range(len(array)):
		if array.slice(i, i + len(sequence)) == sequence:
			return i
	
	return -1
