extends MeshInstance3D
class_name Model

var tool: MeshDataTool
var surface_array = []
var vertices: PackedVector3Array = []
var indices: PackedInt32Array = []
var edges: Dictionary = {}

signal geometry_added

func _ready() -> void:
	surface_array.resize(Mesh.ARRAY_MAX)
	
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
	create_trimesh_collision()
	
	var surface_mesh_tool := SurfaceTool.new()
	surface_mesh_tool.create_from(mesh, 0)
	surface_mesh_tool.generate_normals()
	surface_mesh_tool.commit(mesh)
	geometry_added.emit()
	
	tool = MeshDataTool.new()
	tool.create_from_surface(mesh, 0)
