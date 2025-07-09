extends Node
class_name Command

signal started_command(param_callback: Callable)

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
	User.stack.add_command("w %f %f %f" % [delta[0], delta[1], delta[2]])

func _ready() -> void:
	User.command = self

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("translate"):
		started_command.emit(func(parameters: String):
			var tokens: PackedStringArray = parameters.split(" ")
			if tokens.size() < 3:
				return
			
			if not (tokens[0].is_valid_float() and tokens[1].is_valid_float() and tokens[2].is_valid_float()):
				return

			translate(Vector3(tokens[0].to_float(), tokens[1].to_float(), tokens[2].to_float()))
		)
