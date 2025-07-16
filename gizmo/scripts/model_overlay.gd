extends Node

@export var selection: Selection

var _meshes = []
func _process(delta: float) -> void:
	for mesh in _meshes:
		mesh.queue_free()
	
	_meshes.clear()

	var face_vertices = selection.get_selected_face_vertices()
	var edge_vertices = selection.get_selected_edge_vertices()

	# Draw the face lines
	var normal: Vector3 = selection.model.tool.get_face_normal(selection.face)
	var normal_offset := normal * 0.001
	for idx in range(len(face_vertices)):
		var a = face_vertices[idx]
		var b = face_vertices[(idx + 1) % len(face_vertices)]
		if a in edge_vertices and b in edge_vertices:
			continue

		_meshes.append(await Draw3D.line(
			normal_offset + selection.model.tool.get_vertex(a),
			normal_offset + selection.model.tool.get_vertex(b),
			Color("ac6b26")
		))

	# Draw the edge line
	_meshes.append(await Draw3D.line(
		normal_offset + selection.model.tool.get_vertex(edge_vertices[0]),
		normal_offset + selection.model.tool.get_vertex(edge_vertices[1]),
		Color("f6cd26")
	))

	# Draw the point
	var vertex = selection.get_selected_vertex()
	_meshes.append(await Draw3D.point(selection.model.tool.get_vertex(vertex), 0.02, Color("f6cd26")))
	
func find_sequence(array: Array, sequence: Array) -> int:
	for i in range(len(array)):
		if array.slice(i, i + len(sequence)) == sequence:
			return i
	
	return -1
