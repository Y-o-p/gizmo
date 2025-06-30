extends Button
class_name VertexControl

var update_vertex: Callable

func _process(delta: float) -> void:
	if button_pressed:
		position = get_global_mouse_position()
		update_vertex.call(position)
