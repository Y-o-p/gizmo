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
var mode = Mode.FACE

signal face_changed(a: Vector3, b: Vector3, c: Vector3)
signal edge_changed(a: Vector3, b: Vector3)
signal vertex_changed(a: Vector3)

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("face"):
		var edge_idx = model.tool.get_face_edge(face, edge)
		var edge_faces = model.tool.get_edge_faces(edge_idx)
		edge_faces.erase(face)
		var new_face_edge_indices = [
			model.tool.get_face_edge(edge_faces[0], 0),
			model.tool.get_face_edge(edge_faces[0], 1),
			model.tool.get_face_edge(edge_faces[0], 2),
		]
		edge = new_face_edge_indices.find(edge_idx)
		face = edge_faces[0]
		_emit_face_vertices()
		_emit_edge_vertices()
		_emit_vertex()
	elif event.is_action_pressed("edge"):
		edge = (edge + 1) % 3
		_emit_edge_vertices()
		_emit_vertex()
	elif event.is_action_pressed("vertex"):
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
