extends Node
class_name Command

@export var model: Model

signal started_command(param_callback: Callable, arg_types: Array)
signal command_completed(command_idx: int)
signal commands_refreshed
signal invalid_command(error: String)

var selection_stack: Array[Selection]

var stack: CommandStack = preload("res://resources/cube.tres")
var commands: Array = []
var finish_line: int = 0:
	set(val):
		finish_line = clamp(val, 0, commands.size())
var macro_recording = null

@onready var KEY_TO_COMMAND: Dictionary = _get_event_to_command_dict()


func interpret_command_resource(command_resource: CommandStack.CommandResource):
	if not KEY_TO_COMMAND.has(command_resource.function_name):
		return "Command doesn't exist"
	
	return KEY_TO_COMMAND[command_resource.function_name].bindv(command_resource.arguments)


func interpret_command_resources(command_strings: Array[CommandStack.CommandResource]) -> Array:
	var result = []
	for command in command_strings:
		result.push_back(interpret_command_resource(command))
	
	return result


func call_commands_thus_far():
	for command in commands:
		if command is String:
			break
		elif command is Callable:
			if not command.is_valid():
				break
			
			if command.call() is String:
				break
	
	# Properties be like: nothing to see here <:^)
	finish_line = finish_line


func load_command_stack(command_stack: CommandStack):
	reset()
	stack = command_stack
	
	commands = interpret_command_resources(command_stack.commands)
	call_commands_thus_far()
	commands_refreshed.emit()


func reset():
	selection_stack.clear()
	var selection = Selection.new()
	selection.model = model
	selection.model.build_initial_model()
	selection_stack.push_back(selection)
	


func export_model_as_gltf():
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.append_from_scene(model, gltf_state_save)
	var path = "user://gizmo_%d.gltf" % int(Time.get_unix_time_from_system())
	gltf_document_save.write_to_filesystem(gltf_state_save, path)


################################################################################
# Command functions
################################################################################


func move_face_selection():
	selection_stack.back().move_face_selection()


func move_edge_selection():
	selection_stack.back().move_edge_selection()


func move_vertex_selection():
	selection_stack.back().move_vertex_selection()


func select_vertex():
	var vertex = selection_stack.back().get_selected_vertex()
	if vertex in selection_stack.back().selected_vertices:
		selection_stack.back().selected_vertices.erase(vertex)
	else:
		selection_stack.back().selected_vertices.push_back(vertex)


func clear_selected_vertices():
	selection_stack.back().selected_vertices.clear()


func translate_arg_types() -> Array:
	return [typeof(Vector3())]


func translate(delta: Vector3):
	if selection_stack.back().selected_vertices.is_empty():
		var index = selection_stack.back().get_selected_vertex()
		selection_stack.back().model.tool.set_vertex(
			index,
			selection_stack.back().model.tool.get_vertex(index) + delta
		)
	else:
		for index in selection_stack.back().selected_vertices:
			selection_stack.back().model.tool.set_vertex(
				index,
				selection_stack.back().model.tool.get_vertex(index) + delta
			)
	
	selection_stack.back().model.rebuild_surface_from_tool()
	selection_stack.back()._emit_face_vertices()


func split_arg_types() -> Array:
	return [typeof(float())]


func split(amount: float):
	if amount < 0.0 or amount > 1.0:
		return "Amount must be between 0.0 and 1.0"

	# Delete the old faces
	for indices in [selection_stack.back().get_selected_face_vertices(), selection_stack.back().get_connected_face_vertices()]:
		var face_index = selection_stack.back().model.find_face(indices)
		if face_index == -1:
			return "Face no longer exists"
		
		for i in range(3):
			selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX].remove_at(face_index)

	# Get the first vertex and second vertex
	var first_vertex = selection_stack.back().get_selected_vertex()
	var edge_vertices = selection_stack.back().get_selected_edge_vertices()
	edge_vertices.erase(first_vertex)
	var second_vertex = edge_vertices[0]

	# Calculate the new vertex and add it
	var new_vertex = (1.0 - amount) * selection_stack.back().model.tool.get_vertex(first_vertex) + amount * selection_stack.back().model.tool.get_vertex(second_vertex)
	selection_stack.back().model.surface_array[Mesh.ARRAY_VERTEX].append(new_vertex)
	var new_vertex_idx = selection_stack.back().model.surface_array[Mesh.ARRAY_VERTEX].size() - 1
	# Nullify the current normals
	selection_stack.back().model.surface_array[Mesh.ARRAY_NORMAL] = null
	selection_stack.back().model.surface_array[Mesh.ARRAY_TANGENT] = null
	
	# Get the starting vertex of the quad
	var selected_face_vertices = selection_stack.back().get_selected_face_vertices()
	selected_face_vertices.erase(first_vertex)
	selected_face_vertices.erase(second_vertex)
	var a = selected_face_vertices[0]
	
	# Get the second to last vertex of the quad
	var connected_face_vertices = selection_stack.back().get_connected_face_vertices()
	connected_face_vertices.erase(first_vertex)
	connected_face_vertices.erase(second_vertex)
	var c = connected_face_vertices[0]
	
	# Create the quad
	selected_face_vertices = selection_stack.back().get_selected_face_vertices()
	var start = selected_face_vertices.find(a)
	var quad: PackedInt32Array = _wrapping_slice(selection_stack.back().get_selected_face_vertices(), start, start + 3)
	quad.insert(2, c)
	
	# Create 4 new faces
	var new_faces := PackedInt32Array()
	for edge_start in range(4):
		new_faces.append(new_vertex_idx)
		new_faces.append_array(_wrapping_slice(quad, edge_start, edge_start + 2))
	
	# Correct the selection
	# The new face is either the first or last one depending on which vertex was selected
	var first_or_last = 3 * selection_stack.back().vertex
	selection_stack.back().face = selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX].size() / 3 + first_or_last
	var new_selected_face_indices = new_faces.slice(3 * first_or_last, 3 * first_or_last + 3)
	selection_stack.back().edge = (new_selected_face_indices.find(first_vertex) - selection_stack.back().vertex) % 3
	
	# Add the new faces and rebuild
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX].append_array(new_faces)
	selection_stack.back().model.rebuild_surface_from_arrays()


func pull():
	# Create a new vertex on top of the currently selected vertex
	var selected_vertex = selection_stack.back().get_selected_vertex()
	selection_stack.back().model.surface_array[Mesh.ARRAY_VERTEX].push_back(selection_stack.back().model.tool.get_vertex(selected_vertex))
	var new_vertex_idx = selection_stack.back().model.surface_array[Mesh.ARRAY_VERTEX].size() - 1
	
	# Connect the currently selected face to the new vertex
	var index_to_replace = selection_stack.back().face * 3 + selection_stack.back().edge + selection_stack.back().vertex
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_to_replace] = new_vertex_idx
	
	# Create the side faces
	var index_array_size = selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX].size()
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX].resize(index_array_size + 6)
	
	var face_vertices = selection_stack.back().get_selected_face_vertices()
	face_vertices.erase(selected_vertex)
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size] = new_vertex_idx
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size + 1] = selected_vertex
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size + 2] = face_vertices[0]
	
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size + 3] = new_vertex_idx
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size + 4] = face_vertices[1]
	selection_stack.back().model.surface_array[Mesh.ARRAY_INDEX][index_array_size + 5] = selected_vertex
	
	# Rebuild the model
	selection_stack.back().model.rebuild_surface_from_arrays()


func run_macro():
	return func(macro_name: String):
		var macro
		if macro_name in Macros.STANDARD_MACROS.keys():
			macro = Macros.STANDARD_MACROS[macro_name]
		elif macro_name in stack.macros.keys():
			macro = stack.macros[macro_name]
		else:
			return "Macro doesn't exist"


################################################################################


func pop():
	if finish_line == 0:
		return
	
	finish_line -= 1
	commands.remove_at(finish_line)
	stack.commands.remove_at(finish_line)
	if macro_recording is PackedStringArray:
		macro_recording.remove_at(macro_recording.size() - 1)

	reset()
	call_commands_thus_far()
	commands_refreshed.emit()


func _load():
	var dialog = FileDialog.new()
	dialog.visible = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = ProjectSettings.globalize_path("user://")
	dialog.add_filter("*.tres, *.res", "Resource")
	var on_selected = func(file):
		var command_stack_or_macro = load(file)
		if command_stack_or_macro is CommandStack:
			load_command_stack(command_stack_or_macro)
		elif command_stack_or_macro is Macro:
			stack.macros[command_stack_or_macro.macro_name] = command_stack_or_macro.commands
		else:
			return
			
		commands_refreshed.emit()
	
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
	# Set up the first selection which depends on model
	var selection := Selection.new()
	selection.model = model
	selection_stack.push_back(selection)

	# Tell the singleton to set the command to self
	User.command = self
	call_deferred("load_command_stack", stack)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_macros"):
		for macro_name in stack.macros:
			var macro := Macro.new()
			macro.macro_name = macro_name
			macro.commands = stack.macros[macro_name]
			var path = "user://%s.tres" % macro_name
			ResourceSaver.save(macro, path)
	elif event.is_action_pressed("save"):
		var path = "user://gizmo_%d.tres" % int(Time.get_unix_time_from_system())
		ResourceSaver.save(stack, path)
	elif event.is_action_pressed("undo_command"):
		pop()
	elif event.is_action_pressed("export"):
		export_model_as_gltf()
	elif event.is_action_pressed("load"):
		_load()
	elif event.is_action_pressed("macro"):
		if macro_recording is PackedStringArray:
			started_command.emit(func(macro_name: String):
				stack.macros[macro_name] = macro_recording
				macro_recording = null
			)
		elif macro_recording == null:
			macro_recording = PackedStringArray([])
	elif event.is_action_pressed("ui_up"):
		finish_line -= 1
	elif event.is_action_pressed("ui_down"):
		finish_line += 1
	else:
		_command_input(event)


func _command_input(event: InputEvent):
	var input_text = event.as_text()
	if not KEY_TO_COMMAND.has(input_text):
		return
	
	var callable: Callable = KEY_TO_COMMAND[input_text]
	var command_name = callable.get_method()
	if not Input.is_action_just_pressed(command_name):
		return

	if callable.get_argument_count() > 0:
		started_command.emit(
			func(parameters: Array):
				callable = callable.bindv(parameters)
				var result = callable.call()
				if result is String:
					invalid_command.emit(result)
					return
				
				_completed_command(callable),
			self.call(command_name + "_arg_types")
		)
	else:
		callable.call()
		_completed_command(callable)


func _completed_command(command: Callable):
	if macro_recording is PackedStringArray:
		macro_recording.append(command.get_method())
	
	stack.commands.insert(finish_line, CommandStack.CommandResource.from_callable(command))
	commands.insert(finish_line, command)
	command_completed.emit(finish_line)
	finish_line += 1
	


func _wrapping_slice(array: Variant, start: int, end: int):
	var new_array = []
	for offset in range(abs(end - start)):
		new_array.append(array[(start + offset) % array.size()])
	
	return new_array
