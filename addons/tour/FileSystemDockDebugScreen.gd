@tool
extends Control

signal show_dock_requested

@onready var show_file_system_button: Button = %ShowFileSystemButton

func _ready() -> void:
	show_file_system_button.pressed.connect(emit_signal.bind("show_dock_requested"))
