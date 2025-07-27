extends VBoxContainer

func _ready() -> void:
	User.command.command_completed.connect(_on_command_completed)
	User.command.commands_refreshed.connect(_on_commands_refreshed)

func _on_command_completed(command: String):
	var label = Label.new()
	label.text = command
	add_child(label)

func _on_commands_refreshed(stack: PackedStringArray):
	for child in get_children():
		child.queue_free()
	
	for string in stack:
		_on_command_completed(string)
