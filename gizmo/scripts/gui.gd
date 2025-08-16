extends MarginContainer

func _ready() -> void:
	User.command.invalid_command.connect(_on_invalid_command)
	User.command.started_command.connect(_on_command_started)

func _on_invalid_command(error: String):
	var label = Label.new()
	label.text = error
	add_child(label)
	
	var tween = get_tree().create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate", Color(label.modulate.r, label.modulate.g, label.modulate.b, 0), 1.0)
	tween.finished.connect(func():
		label.queue_free()
	)

func _on_command_started(ref: CallableReference, submit: Callable):
	var command_editor: CommandEditor = Scenes.COMMAND_EDITOR.instantiate()
	command_editor.stored_command = ref
	command_editor.focus_mode = Control.FOCUS_ALL
	add_child(command_editor)
	command_editor.grab_focus()
	command_editor.gui_input.connect(func (event: InputEvent):
		if event.is_action_pressed("ui_accept"):
			submit.call()
			command_editor.queue_free()
	)
