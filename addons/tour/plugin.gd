@tool
extends EditorPlugin

const GPath = preload("GPath.gd")

func _ready() -> void:
	var inst := GPath.new()
	get_editor_interface().add_child(inst)
	inst.temp_test()
