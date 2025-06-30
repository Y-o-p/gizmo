extends Control

func _ready() -> void:
	User.face_selection_made.connect(_on_selection_made)
	
func _on_selection_made(selection) -> void:
	var surface: Surface = Scenes.surface.instantiate()
	surface.intersection = selection
	surface.vertex_control_created.connect(_on_vertex_control_created)
	add_child(surface)

func _on_vertex_control_created(vertex_control: VertexControl):
	add_child(vertex_control)
