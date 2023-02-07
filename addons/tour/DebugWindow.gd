@tool
extends Window

###############################################################################
#
# SETTINGS
#

const Settings = preload("settings.gd")

var show_debugger_window_shortcut := Settings.get_show_debugger_window_shortcut()
var preferences := Settings.get_preferences("DebugWindow")

###############################################################################
#
# TABS
#

@onready var tab_container: TabContainer = $TabContainer

const ElementsOfNoteDebugScreen = preload("ElementsOfNoteDebugScreen.gd")
@onready var elements_of_note: ElementsOfNoteDebugScreen = %"ElementsOfNoteDebugScreen"

const EditorIconsDebugScreen = preload("EditorIconsDebugScreen.gd")
@onready var editor_icons: EditorIconsDebugScreen = %"EditorIconsDebugScreen"

const FileSystemDockDebugScreen = preload("FileSystemDockDebugScreen.gd")
@onready var file_system_dock: FileSystemDockDebugScreen = %"FileSystemDockDebugScreen"


###############################################################################
#
# BOOSTRAP
#


func _ready() -> void:
	close_requested.connect(hide)
	if theme != null:
		editor_icons.populate_icons(theme)
	tab_container.tab_changed.connect(_on_tab_changed)
	tab_container.current_tab = preferences.get_value("tab_idx", 1)


func _input(event: InputEvent) -> void:
	## We need to repeat the logic from the main plugin handler here in case focus is on the window
	## TODO: can we transfer control to the parent so there's no need for duplication?
	if show_debugger_window_shortcut.matches_event(event) \
	and (event as InputEventKey).pressed:
		hide()


func _on_tab_changed(tab_idx: int) -> void:
	preferences.set_value("tab_idx", tab_idx)
