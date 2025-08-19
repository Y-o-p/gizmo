extends PanelContainer
class_name CommandEditor

signal parameters_changed

var stored_command: CallableReference
var _command_name := "":
	set(val):
		_command_name = val
		%NameLabel.text = _command_name.capitalize()


func _ready():
	if stored_command == null:
		push_error("No command specified")
		return

	_command_name = stored_command.callable.get_method()

	# Add all parameters
	var args: Array = stored_command.callable.get_bound_arguments()
	for i in range(args.size()):
		var argument = args[i]
		var container := HBoxContainer.new()
		if argument is String:
			var arg_name := Label.new()
			arg_name.text = "Name"
			container.add_child(arg_name)
			
			var line_edit := LineEdit.new()
			line_edit.text = argument
			line_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			line_edit.text_changed.connect(func (new_text: String):
				var new_args = stored_command.callable.get_bound_arguments()
				new_args[i] = new_text
				stored_command.callable = Callable(User.command, _command_name).bindv(new_args)
				parameters_changed.emit()
				print(stored_command.callable.get_bound_arguments())
			)
			container.add_child(line_edit)
		elif argument is int:
			var arg_name := Label.new()
			arg_name.text = "Iterations"
			container.add_child(arg_name)
			
			var int_edit := ValueEdit.new(argument)
			int_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			int_edit.value_changed.connect(func (new_int: int):
				var new_args = stored_command.callable.get_bound_arguments()
				new_args[i] = new_int
				stored_command.callable = Callable(User.command, _command_name).bindv(new_args)
				parameters_changed.emit()
			)
			container.add_child(int_edit)
		elif argument is float:
			var arg_name := Label.new()
			arg_name.text = "Amount"
			container.add_child(arg_name)
			
			var float_edit := ValueEdit.new(argument)
			float_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			float_edit.value_changed.connect(func (new_float: float):
				var new_args = stored_command.callable.get_bound_arguments()
				new_args[i] = new_float
				stored_command.callable = Callable(User.command, _command_name).bindv(new_args)
				parameters_changed.emit()
			)
			container.add_child(float_edit)
		elif argument is Vector3:
			var arg_names: Array = ["Δx", "Δy", "Δz"]
			
			for j in range(arg_names.size()):
				var arg_name := Label.new()
				arg_name.text = arg_names[j]
				container.add_child(arg_name)
			
				var float_edit := ValueEdit.new(argument[j])
				float_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
				float_edit.value_changed.connect(func (new_float: float):
					var current_vector: Vector3 = stored_command.callable.get_bound_arguments()[i]
					current_vector[j] = new_float
					args[i] = current_vector
					stored_command.callable = Callable(User.command, _command_name).bindv(args)
					parameters_changed.emit()
				)
				container.add_child(float_edit)
		
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		%ParameterContainer.add_child(container)
