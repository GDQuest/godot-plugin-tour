@tool
extends Window

const ElementOfNoteHelper = preload("ElementsOfNoteHelper.gd")
const EditorIconsHelper = preload("EditorIconsHelper.gd")
const RowAction = ElementOfNoteHelper.RowAction

@onready var editor_icons: EditorIconsHelper = %"Editor Icons"
@onready var elements_of_note: ElementOfNoteHelper = %"Elements of Note"

func _ready() -> void:
	if theme != null:
		editor_icons.populate_icons(theme)

func _input(event: InputEvent) -> void:
	## We need to repeat the logic from the main plugin handler here in case focus is on the window
	if event is InputEventKey \
		and event.pressed \
		and event.keycode == KEY_F9:
			hide()
