extends VBoxContainer


func _ready() -> void:
	User.command.command_completed.connect.call_deferred(_on_command_completed)
	User.command.commands_refreshed.connect.call_deferred(_on_commands_refreshed)


func _on_commands_refreshed():
	for child in get_children():
		child.queue_free()
	
	for idx in range(User.command.commands.size()):
		_on_command_completed(idx)


func _on_command_completed(command_idx: int):
	add_child(construct_command_node(command_idx))


func construct_command_node(command_idx: int):
	var command = User.command.commands[command_idx]
	var panel_container := PanelContainer.new()
	
	var margin_container := MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	panel_container.add_child(margin_container)
	
	var vbox_container := VBoxContainer.new()
	margin_container.add_child(vbox_container)
	
	var label := Label.new()
	label.text = command.get_method()
	vbox_container.add_child(label)
	
	for argument in command.get_bound_arguments():
		var container := HBoxContainer.new()
		if argument is float:
			var arg_name := Label.new()
			arg_name.text = "Amount"
			container.add_child(arg_name)
			
			var float_edit := ValueEdit.new(argument)
			float_edit.value_changed.connect(func (new_float: float):
				User.command.commands[command_idx] = Callable(User.command, command.get_method()).bind(new_float)
				User.command.reset()
				User.command.call_commands_thus_far()
			)
			container.add_child(float_edit)
		elif argument is Vector3:
			var args: Array = ["Δx", "Δy", "Δz"]
			
			for i in range(args.size()):
				var arg_name := Label.new()
				arg_name.text = args[i]
				container.add_child(arg_name)
			
				var float_edit := ValueEdit.new(argument[i])
				float_edit.value_changed.connect(func (new_float: float):
					var current_vector: Vector3 = User.command.commands[command_idx].get_bound_arguments()[0]
					current_vector[i] = new_float
					User.command.commands[command_idx] = Callable(User.command, command.get_method()).bind(current_vector)
					User.command.reset()
					User.command.call_commands_thus_far()
				)
				container.add_child(float_edit)

		vbox_container.add_child(container)

	return panel_container
