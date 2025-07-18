extends Node
class_name Command

signal started_command(param_callback: Callable)
signal command_completed(command_as_string: String)
signal commands_refreshed(commands: PackedStringArray)

@export var selection: Selection

var stack: CommandStack = preload("res://resources/cube.tres")

@onready var KEY_TO_COMMAND: Dictionary = _get_event_to_command_dict()

func load_command_stack(command_stack: CommandStack):
	selection.face = 0
	selection.edge = 0
	selection.vertex = 0
	selection.mode = Selection.Mode.FACE
	selection.model.build_initial_model()
	stack = command_stack
	for command_str in stack.commands:
		var command = stack.string_to_command(command_str)
		if command is Callable:
			command.call(self)
		else:
			print("Error: ", command)

func export_model_as_gltf():
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.append_from_scene(selection.model, gltf_state_save)
	var path = "user://gizmo_%d.gltf" % int(Time.get_unix_time_from_system())
	gltf_document_save.write_to_filesystem(gltf_state_save, path)

################################################################################
# Command functions
################################################################################

func face_mode():
	selection.mode = Selection.Mode.FACE

func edge_mode():
	selection.mode = Selection.Mode.EDGE
	
func vertex_mode():
	selection.mode = Selection.Mode.VERTEX

func move_selection():
	selection.move_selection()

func translate():
	return func(parameters: String):
		var tokens: PackedStringArray = parameters.split(" ")
		if tokens.size() < 3:
			return
		
		if not (tokens[0].is_valid_float() and tokens[1].is_valid_float() and tokens[2].is_valid_float()):
			return

		_translate(Vector3(tokens[0].to_float(), tokens[1].to_float(), tokens[2].to_float()))

func split():
	return func(parameters: String):
		if not parameters.is_valid_float():
			return

		_split(parameters.to_float())
		

################################################################################

func _split(amount: float):
	if amount < 0.0 or amount > 1.0:
		return
	
	# Delete the old faces
	for indices in [selection.get_selected_face_vertices(), selection.get_connected_face_vertices()]:
		var face_index = selection.model.find_face(indices)
		if face_index == -1:
			return
		
		for i in range(3):
			selection.model.surface_array[Mesh.ARRAY_INDEX].remove_at(face_index)

	# Get the first vertex and second vertex
	var first_vertex = selection.get_selected_vertex()
	var edge_vertices = selection.get_selected_edge_vertices()
	edge_vertices.erase(first_vertex)
	var second_vertex = edge_vertices[0]
	
	# Calculate the new vertex and add it
	var new_vertex = (1.0 - amount) * selection.model.tool.get_vertex(first_vertex) + amount * selection.model.tool.get_vertex(second_vertex)
	selection.model.surface_array[Mesh.ARRAY_VERTEX].append(new_vertex)
	var new_vertex_idx = selection.model.surface_array[Mesh.ARRAY_VERTEX].size() - 1
	
	# Nullify the current normals
	selection.model.surface_array[Mesh.ARRAY_NORMAL] = null
	selection.model.surface_array[Mesh.ARRAY_TANGENT] = null
	
	# Get the starting vertex of the quad
	var selected_face_vertices = selection.get_selected_face_vertices()
	selected_face_vertices.erase(first_vertex)
	selected_face_vertices.erase(second_vertex)
	var a = selected_face_vertices[0]
	
	# Get the second to last vertex of the quad
	var connected_face_vertices = selection.get_connected_face_vertices()
	connected_face_vertices.erase(first_vertex)
	connected_face_vertices.erase(second_vertex)
	var c = connected_face_vertices[0]
	
	# Create the quad
	selected_face_vertices = selection.get_selected_face_vertices()
	var start = selected_face_vertices.find(a)
	var quad: PackedInt32Array = _wrapping_slice(selection.get_selected_face_vertices(), start, start + 3)
	quad.insert(2, c)
	
	# Create 4 new faces
	var new_faces := PackedInt32Array()
	for edge_start in range(4):
		new_faces.append(new_vertex_idx)
		new_faces.append_array(_wrapping_slice(quad, edge_start, edge_start + 2))
	
	# Correct the selection
	# The new face is either the first or last one depending on which vertex was selected
	var first_or_last = 3 * selection.vertex
	selection.face = selection.model.surface_array[Mesh.ARRAY_INDEX].size() / 3 + first_or_last
	var new_selected_face_indices = new_faces.slice(3 * first_or_last, 3 * first_or_last + 3)
	selection.edge = (new_selected_face_indices.find(first_vertex) - selection.vertex) % 3
	
	# Add the new faces and rebuild
	selection.model.surface_array[Mesh.ARRAY_INDEX].append_array(new_faces)
	selection.model.rebuild_surface_from_arrays()


func _translate(delta: Vector3):
	for vertex in selection.get_selected_vertices():
		selection.model.tool.set_vertex(
			vertex,
			selection.model.tool.get_vertex(vertex) + delta
		)
	
	selection.model.rebuild_surface_from_tool()
	selection._emit_face_vertices()

func pop():
	stack.commands.remove_at(stack.commands.size() - 1)
	selection.face = 0
	selection.edge = 0
	selection.vertex = 0
	selection.mode = Selection.Mode.FACE
	selection.model.build_initial_model()
	load_command_stack(stack)
	commands_refreshed.emit(stack.commands)

func _load():
	var dialog = FileDialog.new()
	dialog.visible = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = ProjectSettings.globalize_path("user://")
	dialog.add_filter("*.tres, *.res", "Resource")
	var on_selected = func(file):
		load_command_stack(load(file))
		commands_refreshed.emit(stack.commands)
	
	dialog.file_selected.connect(on_selected)
	get_tree().get_root().add_child(dialog)


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
		var path = "user://gizmo_%d.tres" % int(Time.get_unix_time_from_system())
		ResourceSaver.save(stack, path)
		return
	elif event.is_action_pressed("pop_command_stack"):
		pop()
		return
	elif event.is_action_pressed("export"):
		export_model_as_gltf()
		return
	elif event.is_action_pressed("load"):
		_load()
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

func _wrapping_slice(array: Variant, start: int, end: int):
	var new_array = []
	for offset in range(abs(end - start)):
		new_array.append(array[(start + offset) % array.size()])
	
	return new_array
