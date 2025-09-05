extends VBoxContainer

@export var editable = false

var command_id = null

signal finish_line_changed(command_editor)

func get_command_editor():
	var index = %FinishLine.get_index()
	if index == 0:
		return null
	
	var command_editor = get_child(index - 1)
	if command_editor is CommandEditor:
		return command_editor

func _input(event: InputEvent):
	if not editable:
		return
	
	var num_children = get_children().size()
	var new_index := 0
	if event.is_action_pressed("ui_up"):
		new_index = max(0, %FinishLine.get_index() - 1)
	elif event.is_action_pressed("ui_down"):
		new_index = min(num_children - 1, %FinishLine.get_index() + 1)
	else:
		return
	
	move_child(%FinishLine, new_index)

	finish_line_changed.emit(get_command_editor())
