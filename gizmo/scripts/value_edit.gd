extends Control
class_name ValueEdit

signal value_changed(new_value)

var value

func _init(initial_value: Variant) -> void:
	var type = typeof(initial_value)
	self.value = initial_value
	match type:
		TYPE_STRING:
			var line_edit := LineEdit.new()
			line_edit.text = value
			line_edit.text_changed.connect(func(val):
				value = val
				value_changed.emit(val)
			)
			add_child(line_edit)
		TYPE_FLOAT:
			var spin_box := SpinBox.new()
			spin_box.value = value
			spin_box.min_value = 0.0
			spin_box.max_value = 1.0
			spin_box.step = 0.01
			spin_box.value_changed.connect(func(val):
				value = val
				value_changed.emit(val)
			)
			add_child(spin_box)
		TYPE_INT:
			var spin_box := SpinBox.new()
			spin_box.value = value
			spin_box.value_changed.connect(func(val):
				value = val
				value_changed.emit(val)
			)
			add_child(spin_box)
		TYPE_VECTOR3:
			var labels := [Label.new(), Label.new(), Label.new()]
			labels[0].text = "x"
			labels[1].text = "y"
			labels[2].text = "z"
			
			
			var spin_boxes := [SpinBox.new(), SpinBox.new(), SpinBox.new()]
			var hbox := HBoxContainer.new()
			for i in range(3):
				hbox.add_child(labels[i])
				
				spin_boxes[i].value = initial_value[i]
				spin_boxes[i].step = 0.01
				
				spin_boxes[i].value_changed.connect(func (val):
					value[i] = val
					value_changed.emit(value)
				)
				hbox.add_child(spin_boxes[i])
			
			add_child(hbox)
		_:
			push_error("value_edit doesn't support type %s" % type)
			return
