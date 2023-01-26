@tool
extends Window

const ElementsOfNoteDebugScreen = preload("ElementsOfNoteDebugScreen.gd")
const EditorIconsDebugScreen = preload("EditorIconsDebugScreen.gd")
const FileSystemDockDebugScreen = preload("FileSystemDockDebugScreen.gd")

@onready var editor_icons: EditorIconsDebugScreen = %"EditorIconsDebugScreen"
@onready var elements_of_note: ElementsOfNoteDebugScreen = %"ElementsOfNoteDebugScreen"
@onready var file_system_dock: FileSystemDockDebugScreen = %"FileSystemDockDebugScreen"


func _ready() -> void:
	if theme != null:
		editor_icons.populate_icons(theme)


func _input(event: InputEvent) -> void:
	## We need to repeat the logic from the main plugin handler here in case focus is on the window
	## TODO: can we transfer control to the parent so there's no need for duplication?
	if event is InputEventKey \
		and event.pressed \
		and event.keycode == KEY_F9:
			hide()
