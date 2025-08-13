extends RefCounted
class_name DynamicMeshDataTool


var vertex_attribute_flags: int


# ID system to track mesh data
var positions: Dictionary[int, Vector3]         # vertex_id             -> position
var vertex_attributes: Dictionary[int, int]     # vertex_id ^ face_id   -> index
var faces: Dictionary[int, PackedInt32Array]    # face_id               -> 3 vertex_ids
var edges: Dictionary[int, PackedInt32Array]    # vertex_id ^ vertex_id -> face_ids

# Internal surface data
var surface: Array

func get_attrib_id(face_id: int, vertex_id: int) -> int:
	return hash(face_id) ^ hash(vertex_id)

func get_edge_id(vertex_id_a: int, vertex_id_b: int) -> int:
	return hash(vertex_id_a) ^ hash(vertex_id_b)

func commit_to_arrays() -> Array:
	# Positions are lazily evaluated
	var index := 0
	surface[Mesh.ARRAY_VERTEX].resize(3 * faces.size())
	for face_id in faces.keys():
		var vertex_ids = faces[face_id]
		for vertex_id in vertex_ids:
			var position = positions[vertex_id]
			surface[Mesh.ARRAY_VERTEX][index] = position
			index += 1
	
	return surface


func add_vertex(position: Vector3) -> int:
	var id = _new_vertex_id()
	positions[id] = position
	return id

func set_color(face_id: int, vertex_id: int, color: Color) -> void:
	assert(vertex_attribute_flags & 0b100 != 0, "The color flag hasn't been enabled")
	var index = vertex_attributes[get_attrib_id(face_id, vertex_id)]
	surface[Mesh.ARRAY_COLOR][index] = color


var vertex_count := 0
func add_face(vertex_a: int, vertex_b: int, vertex_c: int):
	# Set up new face ID
	var face_id = _new_face_id()
	var vert_ids = PackedInt32Array([vertex_a, vertex_b, vertex_c])
	faces[face_id] = vert_ids
	
	# Per vertex operations
	for i in range(0, 3):
		# Add edge information
		var edge_id = get_edge_id(vert_ids[i], vert_ids[(i + 1) % 3])
		if edges.has(edge_id):
			edges[edge_id].append(face_id)
		else:
			edges[edge_id] = PackedInt32Array([face_id])

		# Add attribute information
		# Normals
		if vertex_attribute_flags & 0b1 != 0:
			surface[Mesh.ARRAY_NORMAL].push_back(Vector3())
		# Tangents
		if vertex_attribute_flags & 0b10 != 0:
			surface[Mesh.ARRAY_TANGENT].push_back(Vector3())
		# Colors
		if vertex_attribute_flags & 0b100 != 0:
			surface[Mesh.ARRAY_COLOR].push_back(Color.WHITE)
		
		var attribute_id = get_attrib_id(face_id, vert_ids[i])
		vertex_attributes[attribute_id] = vertex_count
		vertex_count += 1
	
	return face_id


func update_face_vertex(face_id: int, index: int, new_vertex_id: int):
	var vert_ids = faces[face_id]
	for i in [-1, 1]:
		var old_edge = get_edge_id(vert_ids[(index + i) % 3], vert_ids[index])
		edges[old_edge].erase(face_id)
		var new_edge = get_edge_id(vert_ids[(index + i) % 3], new_vertex_id)
		if edges.has(new_edge):
			edges[new_edge].append(face_id)
		else:
			edges[new_edge] = PackedInt32Array([face_id])
	
	vert_ids[index] = new_vertex_id


func clear():
	positions.clear()
	faces.clear()
	edges.clear()
	surface.clear()
	vertex_count = 0
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	#surface[Mesh.ARRAY_INDEX] = PackedInt32Array()
	
	if vertex_attribute_flags & 0b1 != 0:
		surface[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	if vertex_attribute_flags & 0b10 != 0:
		surface[Mesh.ARRAY_TANGENT] = PackedFloat32Array()
	if vertex_attribute_flags & 0b100 != 0:
		surface[Mesh.ARRAY_COLOR] = PackedColorArray()


func _init() -> void:
	clear()


# Internally tracked ID counters
var _vertex_id := -1
func _new_vertex_id() -> int:
	_vertex_id += 1
	return _vertex_id


var _face_id := -1
func _new_face_id() -> int:
	_face_id += 1
	return _face_id
