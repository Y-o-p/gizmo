extends PanelContainer
class_name CommandEditor

signal parameters_changed(command_id: int, command_arg_values: Array)

var command_id: int
var command_name: String
var command_args: Dictionary

func _ready():
	%NameLabel.text = command_name
	
	# Add all parameters
	for arg_name in command_args:
		var container := HBoxContainer.new()
		var arg_name_label := Label.new()
		arg_name_label.text = arg_name
		container.add_child(arg_name_label)
		
		var arg_value = command_args[arg_name]
		var value_edit = ValueEdit.new(arg_value)
		value_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		value_edit.value_changed.connect(func (new_value: Variant):
			command_args[arg_name] = new_value
			parameters_changed.emit(command_id, command_args.values())
		)
		container.add_child(value_edit)
		
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		%ParameterContainer.add_child(container)
