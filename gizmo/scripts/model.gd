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
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	rebuild_surface_from_arrays()


func generate_normals():
	var surface_mesh_tool := SurfaceTool.new()
	print("SURFACE ARRAY: ", surface_array)
	surface_mesh_tool.create_from_arrays(surface_array)
	surface_mesh_tool.generate_normals()
	surface_array = surface_mesh_tool.commit_to_arrays()


var _clear_wireframe: Callable = func(): pass
func rebuild_wireframe():
	_clear_wireframe.call()

	var lines_to_clear = []
	for edge_idx in range(tool.get_edge_count()):
		var a = tool.get_vertex(tool.get_edge_vertex(edge_idx, 0))
		var b = tool.get_vertex(tool.get_edge_vertex(edge_idx, 1))
		lines_to_clear.append(await Draw3D.line(a, b, Color("#725956")))
	
	_clear_wireframe = func():
		for line in lines_to_clear:
			line.queue_free()


func rebuild_surface_from_arrays():
	mesh.clear_surfaces()
	generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	tool.clear()
	tool.create_from_surface(mesh, 0)
	rebuild_wireframe()


func rebuild_surface_from_tool():
	mesh.clear_surfaces()
	#generate_normals()
	tool.commit_to_surface(mesh)
	rebuild_wireframe()


func find_face(search: PackedInt32Array):
	for i in range(0, surface_array[Mesh.ARRAY_INDEX].size(), 3):
		var face = surface_array[Mesh.ARRAY_INDEX].slice(i, i + 3)
		if face == search:
			return i
	
	return -1
