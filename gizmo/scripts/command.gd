extends Node

@export var selection: Selection

func call_command_stack():
	for command_str in User.stack.commands:
		var command = User.stack.string_to_command(command_str)
		if command is Callable:
			command.call(selection)
		else:
			print("Error: ", command)

func translate(delta: Vector3):
	for vertex in selection.get_selected_vertices():
		selection.model.tool.set_vertex(
			vertex,
			selection.model.tool.get_vertex(vertex) + delta
		)
	
	selection.model.rebuild_surface()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("down"):
		translate(Vector3.DOWN)
	elif event.is_action_pressed("up"):
		translate(Vector3.UP)
	elif event.is_action_pressed("left"):
		translate(Vector3.LEFT)
	elif event.is_action_pressed("right"):
		translate(Vector3.RIGHT)
	elif event.is_action_pressed("out"):
		translate(Vector3.BACK)
	elif event.is_action_pressed("in"):
		translate(Vector3.FORWARD)
