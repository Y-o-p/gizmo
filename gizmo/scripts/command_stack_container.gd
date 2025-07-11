extends VBoxContainer

func _ready() -> void:
	User.command.command_completed.connect(_on_command_completed)
	User.command.started_command.connect(_on_command_started)

func _on_command_completed(command: String):
	var label = Label.new()
	label.text = command
	add_child(label)

func _on_command_started(parameter_callback: Callable):
	var edit = LineEdit.new()
	add_child(edit)
	edit.grab_focus()
	edit.text_submitted.connect(func(parameters: String):
		edit.queue_free()
		parameter_callback.call(parameters)
	)
