extends Node3D

var my_mesh: DynamicMesh

var face: int

func _ready() -> void:
	my_mesh = DynamicMesh.new()
	add_child(my_mesh)
	my_mesh.add_vertex(Vector3(0, 0, 0))
	my_mesh.add_vertex(Vector3(0, 0, 1))
	my_mesh.add_vertex(Vector3(0, 1, 0))
	my_mesh.add_vertex(Vector3(1, 0, 0))
	
	my_mesh.add_face(0, 2, 1, 8, 10, 3)
	my_mesh.add_face(0, 1, 3, 2, 9, 6)
	my_mesh.add_face(0, 3, 2, 5, 11, 0)
	my_mesh.add_face(3, 1, 2, 4, 1, 7)
	my_mesh.submit_new_geometry()
	face = my_mesh.track_index(1)
	
	#print(RenderingServer.mesh_surface_get_arrays(my_mesh.mesh_rid, 0))
	#print(my_mesh.connections)i

func _process(delta: float) -> void:
	print(Engine.get_frames_per_second())

var time = 0.0
func _physics_process(delta: float) -> void:
	time += delta
	my_mesh.modify_vertex(face, Vector3(0, 1.0 + sin(time), 0))
	print(my_mesh.positions[2])
	my_mesh.submit_updated_positions(my_mesh.indices[my_mesh.get_meta_index(face)], 1)
