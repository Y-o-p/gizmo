extends PanelContainer


func _get_command_from_input_event(event: InputEvent):
	var input_text = event.as_text()
	if not User.command.KEY_TO_COMMAND.has(input_text):
		return null
	
	var command = User.command.KEY_TO_COMMAND[input_text]
	var arg_fetcher = command.get_method() + "_default_args"
	var ref := CallableReference.new(command)
	if User.command.has_method(arg_fetcher):
		ref.callable = ref.callable.bindv(User.command.call(arg_fetcher))

	return ref


func _ready() -> void:
	%FocusHereToAddCommands.gui_input.connect(func (event: InputEvent):
		if not event.is_released():
			return
		
		var command_or_rule = _get_command_from_input_event(event)
		if command_or_rule is CallableReference:
			var command_editor = Scenes.COMMAND_EDITOR.instantiate()
			command_editor.stored_command = command_or_rule
			%CommandContainer.add_child(command_editor)
	)
