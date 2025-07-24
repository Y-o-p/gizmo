extends MeshInstance3D
class_name Model

var tool := MeshDataTool.new()
var surface_array = []

signal geometry_added

func _ready() -> void:
	build_initial_model()

func build_initial_model():
	# Data for the initial tetrahedron
	var vertices: PackedVector3Array = [
		Vector3(0, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 0, 0),
	]
	var indices: PackedInt32Array = [
		0, 2, 1,
		0, 1, 3,
		0, 3, 2,
		3, 1, 2,
	]

	# Assign arrays to surface array.
	surface_array.clear()
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	rebuild_surface_from_arrays()


func generate_normals():
	var number_of_vertices = surface_array[Mesh.ARRAY_VERTEX].size()
	surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array([])
	surface_array[Mesh.ARRAY_NORMAL].resize(number_of_vertices)
	var index_to_face_count := PackedInt32Array([])
	index_to_face_count.resize(number_of_vertices)
	var index_to_normal_sum := PackedVector3Array([])
	index_to_normal_sum.resize(number_of_vertices)
	
	var number_of_indices = surface_array[Mesh.ARRAY_INDEX].size()
	for i in range(0, number_of_indices, 3):
		var face = [
			surface_array[Mesh.ARRAY_INDEX][i],
			surface_array[Mesh.ARRAY_INDEX][i + 1],
			surface_array[Mesh.ARRAY_INDEX][i + 2],
		]
		var a = surface_array[Mesh.ARRAY_VERTEX][face[0]]
		var b = surface_array[Mesh.ARRAY_VERTEX][face[1]]
		var c = surface_array[Mesh.ARRAY_VERTEX][face[2]]
		var face_normal = (b - a).cross(c - a)
		for index in face:
			index_to_face_count[index] += 1
			index_to_normal_sum[index] += face_normal
	
	for index in range(surface_array[Mesh.ARRAY_VERTEX].size()):
		surface_array[Mesh.ARRAY_NORMAL][index] = index_to_normal_sum[index] / index_to_face_count[index]


var _clear_wireframe: Callable = func(): pass
func rebuild_wireframe():
	_clear_wireframe.call()

	var lines_to_clear = []
	for edge_idx in range(tool.get_edge_count()):
		var a = tool.get_vertex(tool.get_edge_vertex(edge_idx, 0))
		var b = tool.get_vertex(tool.get_edge_vertex(edge_idx, 1))
		lines_to_clear.append(Draw3D.line(a, b, Color("#725956")))
		add_child(lines_to_clear.back())
	
	_clear_wireframe = func():
		for line in lines_to_clear:
			line.queue_free()


func rebuild_surface_from_arrays():
	mesh.clear_surfaces()
	# Nullify the current normals
	surface_array[Mesh.ARRAY_NORMAL] = null
	surface_array[Mesh.ARRAY_TANGENT] = null
	generate_normals()
	print(surface_array)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	tool.clear()
	tool.create_from_surface(mesh, 0)
	rebuild_wireframe()


func rebuild_surface_from_tool():
	mesh.clear_surfaces()
	# NOTE: MetaDataTool doesn't have a commit_to_arrays() so I'm stuck doing this for now
	tool.commit_to_surface(mesh)
	surface_array = mesh.surface_get_arrays(0)
	generate_normals()
	rebuild_surface_from_arrays()


func find_face(search: PackedInt32Array):
	for i in range(0, surface_array[Mesh.ARRAY_INDEX].size(), 3):
		var face = surface_array[Mesh.ARRAY_INDEX].slice(i, i + 3)
		if face == search:
			return i
	
	return -1
