extends Node2D


var _set_3d_axis_visibility := func(_enabled: bool): pass

func _ready():
	_create_3d_axes()

func _create_3d_axes():
	var x_start = 10000 * Vector3.RIGHT
	var x_end = 10000 * Vector3.LEFT
	var x_line = Draw3D.line(x_start, x_end, Color("393939"), false)
	add_child(x_line)
	var y_start = 10000 * Vector3.UP
	var y_end = 10000 * Vector3.DOWN
	var y_line = Draw3D.line(y_start, y_end, Color("393939"), false)
	add_child(y_line)
	var z_start = 10000 * Vector3.BACK
	var z_end = 10000 * Vector3.FORWARD
	var z_line = Draw3D.line(z_start, z_end, Color("bb7f57"), false)
	add_child(z_line)
	_set_3d_axis_visibility = func(enabled: bool):
		x_line.visible = enabled
		y_line.visible = enabled
		z_line.visible = enabled

func _process(_delta):
	queue_redraw()

func _draw():
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera.projection == Camera3D.ProjectionType.PROJECTION_ORTHOGONAL:
		_set_3d_axis_visibility.call(false)
		var x_start = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.RIGHT)
		var x_end = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.LEFT)
		draw_line(x_start, x_end, Color("393939"))
		var y_start = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.UP)
		var y_end = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.DOWN)
		draw_line(y_start, y_end, Color("393939"))
		var z_start = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.BACK)
		var z_end = get_viewport().get_camera_3d().unproject_position(10000 * Vector3.FORWARD)
		draw_line(z_start, z_end, Color("bb7f57"))
	else:
		_set_3d_axis_visibility.call(true)
