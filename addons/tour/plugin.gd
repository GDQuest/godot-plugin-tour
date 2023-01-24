@tool
extends EditorPlugin

const GPath = preload("GPath.gd")
var inst: GPath

func _ready() -> void:
	inst = GPath.new()
	get_editor_interface().add_child(inst)
	inst.temp_test()


func _exit_tree() -> void:
	inst.queue_free()
