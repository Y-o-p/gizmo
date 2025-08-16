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
	for argument in stored_command.callable.get_bound_arguments():
		var container := HBoxContainer.new()
		if argument is float:
			var arg_name := Label.new()
			arg_name.text = "Amount"
			container.add_child(arg_name)
			
			var float_edit := ValueEdit.new(argument)
			float_edit.value_changed.connect(func (new_float: float):
				stored_command.callable = Callable(User.command, _command_name).bind(new_float)
				parameters_changed.emit()
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
					var current_vector: Vector3 = stored_command.callable.get_bound_arguments()[0]
					current_vector[i] = new_float
					stored_command.callable = Callable(User.command, _command_name).bind(current_vector)
					parameters_changed.emit()
				)
				container.add_child(float_edit)

		%ParameterContainer.add_child(container)
