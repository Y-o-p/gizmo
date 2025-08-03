extends LineEdit
class_name ValueEdit

signal value_changed(new_value)

var value

func _init(initial_value: Variant) -> void:
	max_length = 7
	
	var value_to_string: Callable
	var string_to_value: Callable
	var type = typeof(initial_value)
	match type:
		TYPE_FLOAT:
			value_to_string = func (new_value: float) -> String:
				return String.num_scientific(new_value)
			string_to_value = func (string: String) -> float:
				return string.to_float()
		_:
			push_error("value_edit doesn't support type %s" % type)
			return

	self.value = initial_value
	text = value_to_string.call(value)
	self.text_changed.connect(func(new_text: String):
		value = string_to_value.call(new_text)
		value_changed.emit(value)
	)
	
	self.editing_toggled.connect(func(editing: bool):
		if editing:
			return

		text = value_to_string.call(value)
	)
