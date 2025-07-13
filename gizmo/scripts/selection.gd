extends Node
class_name Selection

@export var model: Model

var face := 0
var edge := 0
var vertex := 0

enum Mode {
	FACE,
	EDGE,
	VERTEX
}
var MODE_TO_STR: Dictionary = {
	Mode.FACE: "j",
	Mode.EDGE: "k",
	Mode.VERTEX: "l",
}
var mode := Mode.FACE

signal face_changed(a: Vector3, b: Vector3, c: Vector3)
signal edge_changed(a: Vector3, b: Vector3)
signal vertex_changed(a: Vector3)

func get_selected_vertices() -> Array:
	match mode:
		Mode.FACE:
			return get_selected_face_vertices()
		Mode.EDGE:
			return get_selected_edge_vertices()
		Mode.VERTEX:
			return [get_selected_vertex()]
	
	return []

func get_selected_face_vertices():
	return [
		model.tool.get_face_vertex(face, 0),
		model.tool.get_face_vertex(face, 1),
		model.tool.get_face_vertex(face, 2),
	]

func get_selected_edge_vertices():
	return [
		model.tool.get_edge_vertex(model.tool.get_face_edge(face, edge), 0),
		model.tool.get_edge_vertex(model.tool.get_face_edge(face, edge), 1),
	]

func get_selected_vertex():
	return get_selected_face_vertices()[(edge + vertex) % 3]

func get_connected_face():
	var edge_idx = model.tool.get_face_edge(face, edge)
	var edge_faces = model.tool.get_edge_faces(edge_idx)
	edge_faces.erase(face)
	return edge_faces[0]

func get_connected_face_vertices():
	var connected_face = get_connected_face()
	return [
		model.tool.get_face_vertex(connected_face, 0),
		model.tool.get_face_vertex(connected_face, 1),
		model.tool.get_face_vertex(connected_face, 2),
	]

func move_selection():
	match mode:
		Mode.FACE:
			var connected_face = get_connected_face()
			var new_face_edge_indices = [
				model.tool.get_face_edge(connected_face, 0),
				model.tool.get_face_edge(connected_face, 1),
				model.tool.get_face_edge(connected_face, 2),
			]
			edge = new_face_edge_indices.find(model.tool.get_face_edge(face, edge))
			face = connected_face
			_emit_face_vertices()
			_emit_edge_vertices()
			_emit_vertex()
		Mode.EDGE:
			edge = (edge + 1) % 3
			_emit_edge_vertices()
			_emit_vertex()
		Mode.VERTEX:
			vertex = (vertex + 1) % 2
			_emit_vertex()

func _emit_face_vertices():
	var a = model.tool.get_vertex(model.tool.get_face_vertex(face, 0))
	var b = model.tool.get_vertex(model.tool.get_face_vertex(face, 1))
	var c = model.tool.get_vertex(model.tool.get_face_vertex(face, 2))
	face_changed.emit(a, b, c)

func _emit_edge_vertices():
	var idx_a = model.tool.get_edge_vertex(model.tool.get_face_edge(face, edge), 0)
	var idx_b = model.tool.get_edge_vertex(model.tool.get_face_edge(face, edge), 1)
	var a = model.tool.get_vertex(idx_a)
	var b = model.tool.get_vertex(idx_b)
	edge_changed.emit(a, b)

func _emit_vertex():
	var indices = [
		model.tool.get_face_vertex(face, 0),
		model.tool.get_face_vertex(face, 1),
		model.tool.get_face_vertex(face, 2),
	]
	vertex_changed.emit(model.tool.get_vertex(indices[(edge + vertex) % 3]))
