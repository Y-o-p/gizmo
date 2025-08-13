extends Node
class_name Command

@export var model: Model

signal started_command(param_callback: Callable, arg_types: Array)
signal command_completed(command_idx: int)
signal commands_refreshed
signal invalid_command(error: String)

var selection_stack: Array[Selection]
var selection: Selection

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
	model.reset()
	
	selection_stack.clear()
	selection = Selection.new()
	selection.model = model
	selection.face_id = model.tool.faces.keys()[0]


func export_model_as_gltf():
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.append_from_scene(model, gltf_state_save)
	var path = "user://gizmo_%d.gltf" % int(Time.get_unix_time_from_system())
	gltf_document_save.write_to_filesystem(gltf_state_save, path)


################################################################################
# Command functions
################################################################################


func push_selection():
	selection_stack.push_back(selection.duplicate())


func pop_selection():
	if selection_stack.is_empty():
		return

	selection = selection_stack.pop_back()


func move_face_selection():
	selection.move_face_selection()


func move_edge_selection():
	selection.move_edge_selection()


func move_vertex_selection():
	selection.move_vertex_selection()


func select_vertex():
	var selection: Selection = selection
	var vertex = selection.get_selected_vertex()
	if vertex in selection.selected_vertices:
		selection.selected_vertices.erase(vertex)
	else:
		selection.selected_vertices.push_back(vertex)


func clear_selected_vertices():
	selection.selected_vertices.clear()


func translate_arg_types() -> Array:
	return [typeof(Vector3())]


func translate(delta: Vector3):
	var selection: Selection = selection
	
	if selection.selected_vertices.is_empty():
		var id = selection.get_selected_vertex()
		selection.model.tool.positions[id] += delta
	else:
		for id in selection.selected_vertices:
			selection.model.tool.positions[id] += delta
	
	selection.model.rebuild_model()


func split_arg_types() -> Array:
	return [typeof(float())]


func split(amount: float):
	if amount < 0.0 or amount > 1.0:
		return "Amount must be between 0.0 and 1.0"

	# Get the first vertex and second vertex
	var first_vertex = selection.get_selected_vertex()
	var second_vertex = selection.get_unselected_vertex()

	# Calculate the new vertex and add it
	var new_vertex_position = (1.0 - amount) * model.tool.positions[first_vertex] + amount * model.tool.positions[second_vertex]
	var new_vertex_id = model.tool.add_vertex(new_vertex_position)
	
	# Get metadata
	var original_edge_vertices = selection.get_selected_edge_vertices()
	var original_face_vertices = selection.get_selected_face_vertices()
	var original_connected_face_vertices = selection.get_connected_face_vertices()
	
	# Build two new faces
	var left_midpoint = original_face_vertices.find(original_edge_vertices[1])
	var left_end = original_face_vertices[(left_midpoint + 1) % 3]
	model.tool.add_face(new_vertex_id, original_edge_vertices[1], left_end)
	var right_midpoint = original_connected_face_vertices.find(original_edge_vertices[1])
	var right_end = original_connected_face_vertices[(right_midpoint - 1) % 3]
	model.tool.add_face(original_edge_vertices[1], new_vertex_id, right_end)
	
	# Update the metadata
	var connected_face_id = selection.get_connected_face()
	model.tool.update_face_vertex(selection.face_id, left_midpoint, new_vertex_id)
	model.tool.update_face_vertex(connected_face_id, right_midpoint, new_vertex_id)

func pull():
	# Create a new vertex on top of the currently selected vertex
	var selected_vertex_id = selection.get_selected_vertex()
	var new_vertex_id = model.tool.add_vertex(model.tool.positions[selected_vertex_id])

	# Connect the selected face to the new vertex
	model.tool.faces[selection.face_id][(selection.edge + selection.vertex) % 3] = new_vertex_id
	
	# The other two vertices
	var other_ids = selection.get_selected_face_vertices().duplicate()
	other_ids.erase(new_vertex_id)

	# Remove the old edges
	model.tool.edges[model.tool.get_edge_id(other_ids[0], selected_vertex_id)].erase(selection.face_id)
	model.tool.edges[model.tool.get_edge_id(other_ids[1], selected_vertex_id)].erase(selection.face_id)

	# Create the side faces
	model.tool.add_face(new_vertex_id, selected_vertex_id, other_ids[0])
	model.tool.add_face(new_vertex_id, other_ids[1], selected_vertex_id)

	# Add the new edges
	model.tool.edges[model.tool.get_edge_id(other_ids[0], new_vertex_id)].append(selection.face_id)
	model.tool.edges[model.tool.get_edge_id(other_ids[1], new_vertex_id)].append(selection.face_id)

	# Rebuild the model
	selection.model.rebuild_model()


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
