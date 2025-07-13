extends MeshInstance3D
class_name Model

var tool := MeshDataTool.new()
var surface_array = []
var vertices: PackedVector3Array = []
var indices: PackedInt32Array = []

signal geometry_added

func _ready() -> void:
	build_initial_model()

func build_initial_model():
	# Reset all internal data
	mesh.clear_surfaces()
	tool.clear()
	surface_array.clear()
	vertices.clear()
	indices.clear()
	surface_array.resize(Mesh.ARRAY_MAX)
	
	# Data for the initial tetrahedron
	vertices = [
		Vector3(0, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 0, 0),
	]
	indices = [
		0, 2, 1,
		0, 1, 3,
		0, 3, 2,
		3, 1, 2,
	]

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	tool.create_from_surface(mesh, 0)
	
	generate_normals()

func generate_normals():
	var surface_mesh_tool := SurfaceTool.new()
	surface_mesh_tool.create_from(mesh, 0)
	surface_mesh_tool.generate_normals()
	surface_mesh_tool.commit(mesh)
	geometry_added.emit()

func rebuild_surface_from_arrays():
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	generate_normals()
	tool.clear()
	tool.create_from_surface(mesh, 0)

func rebuild_surface_from_tool():
	mesh.clear_surfaces()
	tool.commit_to_surface(mesh)
	generate_normals()

func find_face(search: PackedInt32Array):
	for i in range(0, indices.size(), 3):
		var face = indices.slice(i, i + 3)
		if face == search:
			return i
	
	return -1
