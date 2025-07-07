extends Node

@export var selection: Selection

func call_command_stack():
	for command_str in User.stack.commands:
		var command = User.stack.string_to_command(command_str)
		if command is Callable:
			command.call(selection)
		else:
			print("Error: ", command)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("down"):
		selection.tool.set_vertex(
			selection.get_selected_vertex(),
			selection.tool.get_vertex(selection.get_selected_vertex()) + Vector3.DOWN
		)
	
		selection.model.mesh.clear_surfaces()
		selection.tool.commit_to_surface(selection.model.mesh)
