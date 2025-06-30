extends MeshInstance2D
class_name Surface

var intersection

signal vertex_control_created(vertex_control: VertexControl)

var _face_basis: Basis
var _inverse_face_basis: Basis
var _SCALING_FACTOR := 100

func _ready() -> void:
	var collider = intersection.collider
	var collider_mesh: ArrayMesh = collider.get_parent().mesh
	
	var tool = MeshDataTool.new()
	print(intersection)
	tool.create_from_surface(collider_mesh, intersection.face_index)
	
	mesh.clear_surfaces()
	
	# Begin draw.
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Get all three vertices of the selected triangle
	var a := tool.get_vertex(0)
	var b := tool.get_vertex(1)
	var c := tool.get_vertex(2)
	
	# Create a basis from said vertices
	var x_axis = b - a
	var z_axis = (b - a).cross(c - a)
	var y_axis = x_axis.cross(z_axis)
	_face_basis = Basis(x_axis, y_axis, z_axis).orthonormalized() * 1.0 / _SCALING_FACTOR
	_inverse_face_basis = _face_basis.inverse()

	for vertex_index in range(tool.get_vertex_count()):
		mesh.surface_set_color(Color.AQUAMARINE)
		var vertex = tool.get_vertex(vertex_index)
		var vertex_screen_position = _inverse_face_basis * vertex
		mesh.surface_add_vertex(vertex_screen_position)
		
		var vertex_control: VertexControl = Scenes.vertex_control.instantiate()
		vertex_control.position = Vector2(vertex_screen_position[0], vertex_screen_position[1])
		vertex_control.update_vertex = func(control_position: Vector2):
			var view_position = Vector3(control_position[0], control_position[1], 0.0)
			var world_position = _face_basis * view_position
			tool.set_vertex(vertex_index, world_position)
			
			# Remove the old surface and replace it with the new surface
			collider_mesh.surface_remove(intersection.face_index)
			tool.commit_to_surface(collider_mesh)
		
		vertex_control_created.emit(vertex_control)

	# End drawing.
	mesh.surface_end()
