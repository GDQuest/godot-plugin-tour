@tool
extends Control

signal show_dock_requested
signal highlight_addons_requested

@onready var show_file_system_button: Button = %ShowFileSystemButton
@onready var highlight_addons_directory: Button = %HighlightAddonsDirectory

func _ready() -> void:
	show_file_system_button.pressed.connect(emit_signal.bind("show_dock_requested"))
	highlight_addons_directory.pressed.connect(emit_signal.bind("highlight_addons_requested"))
