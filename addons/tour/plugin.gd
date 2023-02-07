@tool
extends EditorPlugin

const Tour = preload("Tour.gd")
var tour: Tour

func _ready() -> void:
	tour = Tour.new()
	get_editor_interface().add_child(tour)


func _exit_tree() -> void:
	tour.queue_free()
