extends MeshInstance3D
class_name Model

@export_flags(
	"Normals:2",
	"Tangents:4",
	"Colors:8",
	"Texture UV:16",
	"Texture UV2:32",
) var vertex_attribute_flags := 0
var tool: DynamicMeshDataTool = DynamicMeshDataTool.new()

func _ready() -> void:
	tool.vertex_attribute_flags = vertex_attribute_flags
	reset()

func reset():
	tool.clear()
	
	# Data for the initial tetrahedron
	var v: PackedInt32Array = [
		tool.add_vertex(Vector3(0, 0, 0)),
		tool.add_vertex(Vector3(0, 0, 1)),
		tool.add_vertex(Vector3(0, 1, 0)),
		tool.add_vertex(Vector3(1, 0, 0)),
	]
	tool.add_face(v[0], v[2], v[1])
	tool.add_face(v[0], v[1], v[3])
	tool.add_face(v[0], v[3], v[2])
	tool.add_face(v[3], v[1], v[2])

	rebuild_model()


#func generate_normals():
	#var number_of_vertices = surface_array[Mesh.ARRAY_VERTEX].size()
	#surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array([])
	#surface_array[Mesh.ARRAY_NORMAL].resize(number_of_vertices)
	#var index_to_face_count := PackedInt32Array([])
	#index_to_face_count.resize(number_of_vertices)
	#var index_to_normal_sum := PackedVector3Array([])
	#index_to_normal_sum.resize(number_of_vertices)
	#
	#var number_of_indices = surface_array[Mesh.ARRAY_INDEX].size()
	#for i in range(0, number_of_indices, 3):
		#var face = [
			#surface_array[Mesh.ARRAY_INDEX][i],
			#surface_array[Mesh.ARRAY_INDEX][i + 1],
			#surface_array[Mesh.ARRAY_INDEX][i + 2],
		#]
		#var a = surface_array[Mesh.ARRAY_VERTEX][face[0]]
		#var b = surface_array[Mesh.ARRAY_VERTEX][face[1]]
		#var c = surface_array[Mesh.ARRAY_VERTEX][face[2]]
		#var face_normal = (b - a).cross(c - a)
		#for index in face:
			#index_to_face_count[index] += 1
			#index_to_normal_sum[index] += face_normal
	#
	#for index in range(surface_array[Mesh.ARRAY_VERTEX].size()):
		#surface_array[Mesh.ARRAY_NORMAL][index] = index_to_normal_sum[index] / index_to_face_count[index]


var _clear_wireframe: Callable = func(): pass
func rebuild_wireframe():
	_clear_wireframe.call()

	var lines_to_clear = []
	var incomplete_edges: Array = tool.edges.keys().duplicate()
	incomplete_edges.sort()
	for face_verts in tool.faces.values():
		for i in range(3):
			var a = face_verts[i]
			var b = face_verts[(i + 1) % 3]
			var edge_id_index = incomplete_edges.find(tool.get_edge_id(a, b))
			if edge_id_index == -1:
				continue
			
			lines_to_clear.append(Draw3D.line(tool.positions[a], tool.positions[b], Color("#725956")))
			add_child(lines_to_clear.back())
			incomplete_edges.remove_at(edge_id_index)
	
	_clear_wireframe = func():
		for line in lines_to_clear:
			line.queue_free()


func rebuild_model():
	# Clear the mesh
	mesh.clear_surfaces()
	
	# Rebuild the surface
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tool.commit_to_arrays())
	rebuild_wireframe()
