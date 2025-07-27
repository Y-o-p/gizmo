extends CanvasLayer

func _ready() -> void:
	User.command.invalid_command.connect(_on_invalid_command)
	
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
