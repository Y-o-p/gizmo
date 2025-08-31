extends Node

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
