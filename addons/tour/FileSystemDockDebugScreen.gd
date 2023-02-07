@tool
extends Control

signal show_dock_requested
signal highlight_addons_requested
signal unlock_tree_requested

@onready var show_file_system_button: Button = %ShowFileSystemButton
@onready var highlight_addons_file_button: Button = %HighlightAddonsFile
@onready var unlock_tree_button: Button = %UnlockTree


func _ready() -> void:
	show_file_system_button.pressed.connect(emit_signal.bind("show_dock_requested"))
	highlight_addons_file_button.pressed.connect(emit_signal.bind("highlight_addons_requested"))
	unlock_tree_button.pressed.connect(emit_signal.bind("unlock_tree_requested"))
