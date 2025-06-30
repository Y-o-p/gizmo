extends Camera3D

@export var selection: Selection
@export var distance: float = 5
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@onready var _camera_pivot = get_parent()
@export var tilt_limit = deg_to_rad(90)

var _current_distance := 5.0
var _current_size := 5.0
var RAY_LENGTH := 5000.0

func _ready() -> void:
	selection.face_changed.connect(_on_face_changed)
	selection.edge_changed.connect(_on_edge_changed)
	selection.vertex_changed.connect(_on_vertex_changed)

func _on_face_changed(a, b, c):
	draw_face_selection(a, b, c)
	#var desired_pos: Vector3 = center + 10 * normal
	#_camera_pivot.rotation.x = desired_pos.angle_to(Vector3.RIGHT)
	#_camera_pivot.rotation.y = desired_pos.angle_to(Vector3.UP)
	
var _clear_face_selection: Callable = func(): pass
func draw_face_selection(a, b, c):
	_clear_face_selection.call()
	
	var center = (a + b + c) / 3.0
	var normal = -(b - a).cross(c - a).normalized()
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

	var normal: Vector3 = selection.tool.get_face_normal(selection.face)
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
	

func _process(delta) -> void:
	if Input.is_action_just_released("rotate_mode"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# For perspective mode
	_current_distance = lerp(_current_distance, distance, 10.0 * delta)
	position = _current_distance * Vector3(0.0, 0.0, 1.0)
	
	# For orthogonal mode
	_current_size = lerp(_current_size, distance, 10.0 * delta)
	size = _current_size

func _input(event: InputEvent) -> void:
	if event.is_action("rotate_mode"):
		if event.is_released():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.is_pressed():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action("zoom_in"):
		distance -= 0.1
	elif event.is_action("zoom_out"):
		distance += 0.1
	elif event.is_action_released("select"):
		select()
	elif event.is_action_pressed("swap_projection"):
		projection = (not projection) as int

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("rotate_mode"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity

func select():
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()

	var origin = project_ray_origin(mouse_position)
	var end = origin + project_ray_normal(mouse_position) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)

	var collision: Dictionary = space_state.intersect_ray(query)
	if not collision.is_empty():
		User.face_selection_made.emit(collision)
