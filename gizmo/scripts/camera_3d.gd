extends Camera3D

@export var distance: float = 5
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@onready var _camera_pivot = get_parent()
@export var tilt_limit = deg_to_rad(90)
@export var desired_position := Vector3()

var _current_distance := 5.0
var _current_size := 5.0
var RAY_LENGTH := 5000.0

func _process(delta) -> void:
	if Input.is_action_just_released("rotate_mode"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# For perspective mode
	_current_distance = lerp(_current_distance, distance, 10.0 * delta)
	position = _current_distance * Vector3(0.0, 0.0, 1.0)
	
	# For orthogonal mode
	_current_size = lerp(_current_size, distance, 10.0 * delta)
	size = _current_size
	
	# Smoothly interpolate between the current position and the desired position
	_camera_pivot.position = lerp(_camera_pivot.position, desired_position, 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("rotate_mode"):
		if event.is_released():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.is_pressed():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action("zoom_in"):
		distance -= 0.1
	elif event.is_action("zoom_out"):
		distance += 0.1
	elif event.is_action_pressed("swap_projection"):
		projection = (not projection) as int
	elif event is InputEventMouseMotion and Input.is_action_pressed("rotate_mode"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity
