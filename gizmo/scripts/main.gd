extends Node

func _process(delta: float):
	var face_positions = Array(%Interpreter.mesh.get_face_positions(%Interpreter.selections.back()))
	%Camera3D.desired_position = face_positions.reduce(func(x, y): return x + y) / 3.0
	
	if Engine.get_frames_drawn() % 5 == 0:
		%ModelOverlay.set_face_vertex_positions(face_positions)

func _input(event: InputEvent):
	if event.is_action_pressed("push_selection"):
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
