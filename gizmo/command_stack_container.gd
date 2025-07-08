extends VBoxContainer

func _ready() -> void:
	User.stack.command_added.connect(_on_command_added)

func _on_command_added(command: String):
	var label = Label.new()
	label.text = command
	add_child(label)
