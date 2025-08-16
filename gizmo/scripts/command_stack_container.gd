extends VBoxContainer

@export var finish_line: Panel


func _ready() -> void:
	User.command.command_completed.connect.call_deferred(_on_command_completed)
	User.command.commands_refreshed.connect.call_deferred(_on_commands_refreshed)


func _process(delta: float) -> void:
	move_child(finish_line, User.command.finish_line)


func _on_commands_refreshed():
	for child in get_children():
		if child == finish_line:
			continue

		remove_child(child)
		child.queue_free()
	
	for command_reference in User.command.commands:
		_on_command_completed(command_reference)


func _on_command_completed(ref: CallableReference):
	var command_editor: CommandEditor = Scenes.COMMAND_EDITOR.instantiate()
	command_editor.stored_command = ref
	command_editor.parameters_changed.connect(func ():
		User.command.reset()
		User.command.call_commands_thus_far()
	)
	add_child(command_editor)
