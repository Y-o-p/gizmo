extends Node


func _process(delta: float):
	var face_positions = Array(%Interpreter.mesh.get_face_positions(%Interpreter.selections.back()))
	%Camera3D.desired_position = face_positions.reduce(func(x, y): return x + y) / 3.0
	
	if Engine.get_frames_drawn() % 5 == 0:
		%ModelOverlay.set_face_vertex_positions(face_positions)

func _input(event: InputEvent):
	if event.is_action_pressed("save"):
		%CommandFileWriter.visible = true
	elif event.is_action_pressed("load"):
		%CommandFileReader.visible = true
	elif event.is_action_pressed("undo_command"):
		var editor: CommandEditor = %CommandStackContainer.get_command_editor()
		if editor != null:
			editor.queue_free()
			%Interpreter.undo_command(editor.command_id)
	elif event.is_action_pressed("push_selection"):
		%Interpreter.push_selection()
	elif event.is_action_pressed("pop_selection"):
		%Interpreter.pop_selection()
	elif event.is_action_pressed("move_face_selection"):
		%Interpreter.move_face_selection()
	elif event.is_action_pressed("move_edge_selection"):
		%Interpreter.move_edge_selection()
	elif event.is_action_pressed("translate"):
		%Interpreter.translate(Vector3(1, 0, 0))
	elif event.is_action_pressed("split"):
		%Interpreter.split(0.5)
	elif event.is_action_pressed("pull"):
		%Interpreter.pull()
	elif event.is_action_pressed("color"):
		%Interpreter.color(Color(1.0, 1.0, 1.0))
	
func _on_interpreter_command_executed(command_id:  int, command_name:  String, command_args:  Dictionary) -> void:
	var command_editor = Scenes.COMMAND_EDITOR.instantiate()
	command_editor.command_id = command_id
	command_editor.command_name = command_name
	command_editor.command_args = command_args
	command_editor.parameters_changed.connect(%Interpreter.update_command)
	%CommandStackContainer.add_child(command_editor)


func _on_command_file_writer_file_selected(path:  String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(%Interpreter.commands_as_json_string())
		file.close()
		print("Saved a command stack to: %s" % path)
	else:
		push_error("Failed to save command stack to: %s", path)


func _on_command_file_reader_file_selected(path:  String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		print(file.get_as_text())
		%Interpreter.load_commands_from_json_string(file.get_as_text())
		file.close()
		print("Loaded a command stack from: %s" % path)
	else:
		push_error("Failed to load command stack from: %s", path)


func _on_command_stack_container_finish_line_changed(id) -> void:
	print(id)
