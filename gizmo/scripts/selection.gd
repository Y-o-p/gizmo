extends Node
class_name Selection

@export var model: Model

var face := 0
var edge := 0
var vertex := 0
var selected_vertices := PackedInt32Array([])

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


func move_face_selection():
	var connected_face = get_connected_face()
	var new_face_edge_indices = [
		model.tool.get_face_edge(connected_face, 0),
		model.tool.get_face_edge(connected_face, 1),
		model.tool.get_face_edge(connected_face, 2),
	]
	edge = new_face_edge_indices.find(model.tool.get_face_edge(face, edge))
	face = connected_face


func move_edge_selection():
	edge = (edge + 1) % 3


func move_vertex_selection():
	vertex = (vertex + 1) % 2
