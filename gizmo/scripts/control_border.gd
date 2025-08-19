extends Control
class_name ControlBorder

@export var target: Control
@export var color := Color.WHITE

func _process(_delta):
	queue_redraw()

func _draw():
	if target == null:
		return

	draw_dashed_line(target.global_position, target.global_position + Vector2(target.size[0], 0.0), color)
	draw_dashed_line(target.global_position, target.global_position + Vector2(0.0, target.size[1]), color)
	draw_dashed_line(target.global_position + target.size, target.global_position + Vector2(target.size[0], 0.0), color)
	draw_dashed_line(target.global_position + target.size, target.global_position + Vector2(0.0, target.size[1]), color)
