extends Node
class_name Command

signal started_command(param_callback: Callable)
signal command_completed(command_as_string: String)

@export var selection: Selection

var stack: CommandStack = preload("res://resources/cube.tres")

@onready var KEY_TO_COMMAND: Dictionary = _get_event_to_command_dict()

func load_command_stack(command_stack: CommandStack):
	stack = command_stack
	for command_str in stack.commands:
		var command = stack.string_to_command(command_str)
		if command is Callable:
			command.call(self)
		else:
			print("Error: ", command)

func face_mode():
	selection.mode = Selection.Mode.FACE

func edge_mode():
	selection.mode = Selection.Mode.EDGE
	
func vertex_mode():
	selection.mode = Selection.Mode.VERTEX

func move_selection():
	selection.move_selection()

func start_translate():
	print("STARTED TRANSLATE")
	return func(parameters: String):
		var tokens: PackedStringArray = parameters.split(" ")
		if tokens.size() < 3:
			return
		
		if not (tokens[0].is_valid_float() and tokens[1].is_valid_float() and tokens[2].is_valid_float()):
			return

		translate(Vector3(tokens[0].to_float(), tokens[1].to_float(), tokens[2].to_float()))

func translate(delta: Vector3):
	for vertex in selection.get_selected_vertices():
		selection.model.tool.set_vertex(
			vertex,
			selection.model.tool.get_vertex(vertex) + delta
		)
	
	selection.model.rebuild_surface()

func _get_event_to_command_dict():
	var event_to_command = {}
	for method in get_method_list():
		if not InputMap.has_action(method.name):
			continue

		var events = InputMap.action_get_events(method.name)
		for input_event in events:
			event_to_command[input_event.as_text()] = Callable(self, method.name)

	return event_to_command

func _ready() -> void:
	User.command = self
	call_deferred("load_command_stack", stack)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		ResourceSaver.save(stack)
		print(stack.commands)
		return
	
	var input_text = event.as_text()
	if not KEY_TO_COMMAND.has(input_text):
		return
	
	var callable: Callable = KEY_TO_COMMAND[input_text]
	if not Input.is_action_just_pressed(callable.get_method()):
		return
	
	# Either the callable returns a new callable that takes in a string as input
	# or it's a command that requires no parameters.
	var maybe_callable = callable.call()
	if maybe_callable is Callable:
		started_command.emit(func(parameters: String):
			maybe_callable.call(parameters)
			var command_as_string = "%s %s" % [callable.get_method(), parameters]
			command_completed.emit(command_as_string)
			stack.commands.append(command_as_string)
		)
	else:
		command_completed.emit(callable.get_method())
		stack.commands.append(callable.get_method())
