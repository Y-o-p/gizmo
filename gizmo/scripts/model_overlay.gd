extends Node

@export var selection: Selection

func _ready() -> void:
	selection.face_changed.connect(_on_face_changed)
	selection.edge_changed.connect(_on_edge_changed)
	selection.vertex_changed.connect(_on_vertex_changed)

func _on_face_changed(a, b, c):
	draw_face_selection(a, b, c)
	
var _clear_face_selection: Callable = func(): pass
func draw_face_selection(a, b, c):
	_clear_face_selection.call()

	var line_a: MeshInstance3D = await Draw3D.line(a, b, Color.YELLOW)
	var line_b: MeshInstance3D = await Draw3D.line(b, c, Color.YELLOW)
	var line_c: MeshInstance3D = await Draw3D.line(c, a, Color.YELLOW)
	
	_clear_face_selection = func():
		line_a.queue_free()
		line_b.queue_free()
		line_c.queue_free()

func _on_edge_changed(a, b):
	draw_edge_selection(a, b)

var _clear_edge_selection: Callable = func(): pass
func draw_edge_selection(a, b):
	_clear_edge_selection.call()

	var normal: Vector3 = selection.model.tool.get_face_normal(selection.face)
	var line_a: MeshInstance3D = await Draw3D.line(normal * 0.01 + a, normal * 0.01 + b, Color.ORANGE_RED)
	_clear_edge_selection = func():
		line_a.queue_free()

func _on_vertex_changed(a):
	draw_vertex_selection(a)

var _clear_vertex_selection: Callable = func(): pass
func draw_vertex_selection(a):
	_clear_vertex_selection.call()
	
	var point: MeshInstance3D = await Draw3D.point(a)
	_clear_vertex_selection = func():
		point.queue_free()
