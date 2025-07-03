extends Node
class_name Selection

var tool: MeshDataTool
@export var model: Model:
	set(value):
		model = value
		_refresh_tool()

var face := 0
@export_range(0, 2) var edge: int = 0
@export_range(0, 1) var vertex: int = 0

enum Mode {
	FACE,
	EDGE,
	VERTEX
}
var mode = Mode.FACE

signal face_changed(a: Vector3, b: Vector3, c: Vector3)
signal edge_changed(a: Vector3, b: Vector3)
signal vertex_changed(a: Vector3)

func _ready() -> void:
	model.geometry_added.connect(_refresh_tool)
	for command_str in User.stack.commands:
		var command = User.stack.string_to_command(command_str)
		if command is Callable:
			command.call(self, model)
		else:
			print("Error: ", command)
	
	print("Mode: ", mode)

func _refresh_tool():
	tool = MeshDataTool.new()
	tool.create_from_surface(model.mesh, 0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("face"):
		var edge_idx = tool.get_face_edge(face, edge)
		var edge_faces = tool.get_edge_faces(edge_idx)
		edge_faces.erase(face)
		var new_face_edge_indices = [
			tool.get_face_edge(edge_faces[0], 0),
			tool.get_face_edge(edge_faces[0], 1),
			tool.get_face_edge(edge_faces[0], 2),
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
	var a = tool.get_vertex(tool.get_face_vertex(face, 0))
	var b = tool.get_vertex(tool.get_face_vertex(face, 1))
	var c = tool.get_vertex(tool.get_face_vertex(face, 2))
	face_changed.emit(a, b, c)

func _emit_edge_vertices():
	var idx_a = tool.get_edge_vertex(tool.get_face_edge(face, edge), 0)
	var idx_b = tool.get_edge_vertex(tool.get_face_edge(face, edge), 1)
	var a = tool.get_vertex(idx_a)
	var b = tool.get_vertex(idx_b)
	edge_changed.emit(a, b)

func _emit_vertex():
	var indices = [
		tool.get_face_vertex(face, 0),
		tool.get_face_vertex(face, 1),
		tool.get_face_vertex(face, 2),
	]
	vertex_changed.emit(tool.get_vertex(indices[(edge + vertex) % 3]))
