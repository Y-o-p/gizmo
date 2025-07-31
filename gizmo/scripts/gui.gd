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

func _on_command_started(parameter_callback: Callable, argument_types: Array):
	var edit = LineEdit.new()
	add_child(edit)
	edit.grab_focus()
	edit.text_submitted.connect(func(text: String):
		edit.queue_free()
		var parameters = []
		for type in argument_types:
			match(type):
				TYPE_FLOAT:
					if not text.is_valid_float():
						return

					parameters.append(text.to_float())
				TYPE_VECTOR3:
					var tokens = text.split(" ")
					if tokens.size() != 3:
						return
					
					if !tokens[0].is_valid_float() or !tokens[1].is_valid_float() or !tokens[2].is_valid_float():
						return

					parameters.append(Vector3(tokens[0].to_float(), tokens[1].to_float(), tokens[2].to_float()))
					
		parameter_callback.call(parameters)
	)
	edit.editing_toggled.connect(func(editing: bool):
		if editing:
			return
		
		edit.queue_free()
	)
