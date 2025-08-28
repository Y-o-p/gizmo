extends Node3D

var my_mesh: DynamicMesh

func _ready() -> void:
	my_mesh = DynamicMesh.new()
	my_mesh.add_vertex(Vector3(0, 0, 0))
	my_mesh.add_vertex(Vector3(0, 0, 1))
	my_mesh.add_vertex(Vector3(0, 1, 0))
	my_mesh.add_vertex(Vector3(1, 0, 0))
	
	my_mesh.add_face(0, 2, 1, 8, 10, 3)
	my_mesh.add_face(0, 1, 3, 2, 9, 6)
	my_mesh.add_face(0, 3, 2, 5, 11, 0)
	my_mesh.add_face(3, 1, 2, 4, 1, 7)
	my_mesh.submit()
	add_child(my_mesh)
	

	print(RenderingServer.mesh_surface_get_arrays(my_mesh.mesh_rid, 0))
	print(my_mesh.connections)
