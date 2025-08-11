extends Node
class_name Selection

@export var model: Model

var face_id: int
var edge := 0
var vertex := 0
var selected_vertices := PackedInt32Array([])

## Returns the vertex IDs of the currently selected face
func get_selected_face_vertices() -> PackedInt32Array:
	return model.tool.faces[face_id]


## Returns the vertex IDs of the currently selected edge
func get_selected_edge_vertices() -> PackedInt32Array:
	return Helpers.wrapping_slice(get_selected_face_vertices(), edge, edge + 2)


## Returns the vertex ID of the currently selected vertex
func get_selected_vertex() -> int:
	return get_selected_edge_vertices()[vertex]


## Returns the connected face ID
func get_connected_face():
	var a = model.tool.faces[face_id][edge]
	var b = model.tool.faces[face_id][(edge + 1) % 3]
	var edge_id = model.tool.get_edge_id(a, b)
	var face_ids_from_edge = model.tool.edges[edge_id]
	return face_ids_from_edge[0 if face_ids_from_edge[0] != face_id else 1]


## Returns a list vertex IDs of the connected face
func get_connected_face_vertices():
	var connected_face_id = get_connected_face()
	return model.tool.faces[connected_face_id]


## Moves the face selection to the face connected by the selected edge
func move_face_selection():
	var connected_face = get_connected_face()
	var connected_face_vertices = get_connected_face_vertices()
	edge = connected_face_vertices.find(get_selected_edge_vertices()[1])
	move_vertex_selection()
	face_id = connected_face


## Moves the edge selection clockwise
func move_edge_selection():
	edge = (edge + 1) % 3


## Flips the vertex selection about the selected edge
func move_vertex_selection():
	vertex = (vertex + 1) % 2
