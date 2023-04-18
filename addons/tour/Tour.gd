@tool
extends Node


###############################################################################
#
# CONSTANTS
#

const GQuery = preload("GQuery.gd")

###############################################################################
#
# SETTINGS
#

const Settings = preload("settings.gd")

var show_debugger_window_shortcut := Settings.get_show_debugger_window_shortcut()

###############################################################################
#
# CACHED NODES
#
# These are nodes that can be expected to be found in the editor
# TODO: missing a bunch of the important nodes
#


###############################################################################
# MAIN NODES

## Internal class: EditorNode, but it is not exposed to GDScript
@onready var editor_root: Node = GQuery.find(get_tree().root, func (node: Node) -> bool: 
	return node.get_class() == "EditorNode"
)

## The editor window, containing all the controls, popups, and so on
@onready var editor_chrome: Panel = GQuery.find(
	GQuery.find(editor_root, func (node: Node) -> bool: return node is Control, 1)
	, func (node: Node) -> bool: return node is Panel
, 1)

###############################################################################
# MENU

## The editor top bar, with the menu and context switches
@onready var editor_title_bar: HBoxContainer = GQuery.find(editor_chrome, func (node: Node) -> bool: 
	return node.get_parent() is VBoxContainer
, 2)


## The menu to the left, with "scene", "project", and so on
@onready var popout_menu_bar: MenuBar = GQuery.find(editor_title_bar, func (node: Node) -> bool: 
	return node is MenuBar
, 1)


## The menu in the middle, with "2D", "3D", "Script", "AssetLib"
@onready var context_switcher: HBoxContainer = GQuery.find(editor_title_bar, func (node: Node) -> bool: 
	return node != editor_title_bar \
		and node is HBoxContainer \
		and node.get_child_count() > 1
, 1)


## The menu to the right, with "Play", "Pause", and so on
@onready var runner_buttons: HBoxContainer = GQuery.find(editor_title_bar, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)

## The combo box to the right, with "Forward+", "Mobile", "Compatibility"
@onready var renderer_drop_down: OptionButton = GQuery.find(editor_title_bar, func (node: Node) -> bool: 
	return node is OptionButton \
		and node.get_parent() is HBoxContainer
, 2)


###############################################################################
# MAIN WINDOW NODES

## The editor window's sans the top menu bar
@onready var editor_workspace_area: HSplitContainer = GQuery.find(editor_chrome, func (node: Node) -> bool: 
	return node is HSplitContainer \
		and node.get_parent() is HSplitContainer
)

## The left column, where the file dock and the scene tree usually reside
@onready var column_left: VSplitContainer = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VSplitContainer
)

## The middle column, with the view and the bottom log
@onready var column_middle: VSplitContainer = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VSplitContainer \
		and node.get_parent() is VBoxContainer \
		and node.get_parent().get_parent() is HSplitContainer
)


## The right column, where the inspector usually resides
@onready var column_right: HSplitContainer = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node != editor_workspace_area \
		and node is HSplitContainer \
		and node.get_parent() is HSplitContainer \
		and node.get_parent().get_parent() is HSplitContainer \
		and node.get_parent().get_parent().get_parent() is HSplitContainer
, 3)


###############################################################################
# LEFT COLUMN
# Not guaranteed to be in the left column, so they do not depend on it

## The file system dock, showing the various files in the project
@onready var file_system_dock: FileSystemDock = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node is FileSystemDock
)

## The scene tree
## Internal class: SceneTreeDock, but it is not exposed to GDScript
@onready var scene_tree_dock: Node = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "SceneTreeDock" \
		and node.name == "Scene" \
		and not (node is PopupMenu)
)

## The Import dock, usually situated in the left column, in the same tab container as the scene tree
@onready var import_dock: VBoxContainer = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent().name == "Import" \
		and node.get_parent().get_class() == "ImportDock"
)


###############################################################################
# MIDDLE BOTTOM COLUMN
# Guaranteeed to be in the middle

## The bottom dock, containing debugger, errors, profiler, and so on
@onready var feedback_area: VBoxContainer = GQuery.find(column_middle, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent() is PanelContainer
, 2)


## Bottom dock tab bar
@onready var feedback_area_tab_bar: HBoxContainer = GQuery.find(feedback_area, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is HBoxContainer
, 2)

###############################################################################
# MIDDLE TOP COLUMN
# Guaranteeed to be in the middle

## The middle upper dock, containing the main viewport, the scene tabs, and tool menu
@onready var canvas_area: VBoxContainer = GQuery.find(column_middle, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent() is VSplitContainer
, 2)


## The top scene tabs dock, containing the tabs and the expand button
@onready var scene_tabs_area: HBoxContainer = GQuery.find(canvas_area, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)


## The tab bar containing scenes
@onready var scene_tabs: TabBar = GQuery.find(scene_tabs_area, func (node: Node) -> bool: 
	return node is TabBar
, 2)


## The plus button at the end of the scenes tabs
@onready var scene_tabs_plus_button: Button = GQuery.find(scene_tabs, func (node: Node) -> bool: 
	return node is Button
, 1)


## Main screen, containing the top toolbox and the viewport
@onready var main_screen: VBoxContainer = GQuery.find(canvas_area, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.name == "MainScreen"
, 2)

## Main screen toolbar
@onready var scene_toolbar: HFlowContainer = GQuery.find(main_screen, func (node: Node) -> bool: 
	return node is HFlowContainer \
		and node.get_parent().get_class() == "CanvasItemEditor"
, 2)

## Scene toolbar buttons, which are constant no matter what is selected
@onready var scene_toolbar_buttons: HBoxContainer = GQuery.find(scene_toolbar, func (node: Node) -> bool: 
	return node is HBoxContainer
, 1)

## Scene toolbar buttons, which change depending on the selected node
@onready var scene_contextual_buttons: HBoxContainer = GQuery.find(scene_toolbar, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)

## SubViewportContainer
@onready var viewport: Node = GQuery.find(canvas_area, func (node: Node) -> bool: 
	return node.get_class() == "SubViewportContainer" \
		and node.get_parent() is Control \
		and node.get_parent().get_parent() is HSplitContainer
)

###############################################################################
# RIGHT COLUMN
# Not guaranteed to be in the left column, so they do not depend on it


## The inspector dock. Real class is "InspectorDock", but it is not exposed.
@onready var inspector_dock: Node = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "InspectorDock" and node.name == "Inspector"
)

## The Node dock. Real class is "NodeDock", but it is not exposed.
@onready var node_dock: Node = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "NodeDock" and node.name == "Node"
)

## The History dock. Real class is "HistoryDock", but it is not exposed.
@onready var history_dock: Node = GQuery.find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "HistoryDock" and node.name == "History"
)

###############################################################################
#
# UTILITY CACHES
#
# Used to verify the nodes have been correctly targeted
#

## All cached elements. If any is added to the `@onready` list, it should also
## be added here.
@onready var _elements := {
	editor_root = editor_root,
	editor_chrome = editor_chrome,
	editor_title_bar = editor_title_bar,
	popout_menu_bar = popout_menu_bar,
	context_switcher = context_switcher,
	runner_buttons = runner_buttons,
	renderer_drop_down = renderer_drop_down,
	editor_workspace_area = editor_workspace_area,
	column_left = column_left,
	column_middle = column_middle,
	column_right = column_right,
	file_system_dock = file_system_dock,
	scene_tree_dock = scene_tree_dock,
	import_dock = import_dock,
	feedback_area = feedback_area,
	feedback_area_tab_bar = feedback_area_tab_bar,
	canvas_area = canvas_area,
	scene_tabs_area = scene_tabs_area,
	scene_tabs = scene_tabs,
	scene_tabs_plus_button = scene_tabs_plus_button,
	main_screen = main_screen,
	scene_toolbar = scene_toolbar,
	scene_toolbar_buttons = scene_toolbar_buttons,
	scene_contextual_buttons = scene_contextual_buttons,
	viewport = viewport,
	inspector_dock = inspector_dock,
	node_dock = node_dock,
	history_dock = history_dock,
}

## Represents the main nodes of interest in the editor.
## Used internally as a list to block all interactable elements in the editor.
## @see `add_overlays_block_all_except`
@onready var _interactables := {
	# top bar
	popout_menu_bar = popout_menu_bar,
	context_switcher = context_switcher,
	runner_buttons = runner_buttons,
	renderer_drop_down = renderer_drop_down,
	
	# Left Column
	file_system_dock = file_system_dock,
	scene_tree_dock = scene_tree_dock,
	import_dock = import_dock,
	
	# Middle Column
	feedback_area = feedback_area,
	canvas_area = canvas_area,
	scene_tabs = scene_tabs, 
	scene_tabs_plus_button = scene_tabs_plus_button, 
	main_screen = main_screen, 
	viewport = viewport, 
	scene_toolbar_buttons = scene_toolbar_buttons, 
	scene_contextual_buttons = scene_contextual_buttons, 
	
	# Right Column
	inspector_dock = inspector_dock, 
	node_dock = node_dock, 
	history_dock = history_dock, 
}

@onready var _interactables_array: Array[Node]

###############################################################################
#
# ANIMATION HELPERS
#


const FileSystemManager = preload("FileSystemManager.gd")
var file_system_dock_manager := FileSystemManager.new()


func _on_ready_setup_file_system_manager() -> void:
	file_system_dock_manager.name = "FileSystemDockManager"
	add_child(file_system_dock_manager, true)
	file_system_dock_manager.file_system_dock = file_system_dock
	file_system_dock_manager.setup()


func _on_exit_remove_file_system_manager() -> void:
	file_system_dock_manager.queue_free()


###############################################################################
#
# DEBUG HELPERS
#
# For developing this plugin
#

var debug_helper := preload("DebugHelper.gd").new()

const DebugWindow = preload("DebugWindow.gd")
var debug_window: DebugWindow


## Checks that all the basic elements are there
func _on_ready_verify_integrity() -> bool:
	if not Engine.is_editor_hint():
		printerr("This script is editor only")
		return false
	
	if not debug_helper.is_debug_mode:
		return true

	debug_window = preload("DebugWindow.tscn").instantiate()
	
	# This is necessary to access editor icons
	# TODO: maybe there's a way to access the default theme from children windows?
	debug_window.theme = get_tree().root.theme
	
	add_child(debug_window)

	var file_system_dock := debug_window.file_system_dock
	var elements_of_note := debug_window.elements_of_note

	file_system_dock.show_dock_requested.connect(file_system_dock_manager.show)
	file_system_dock.highlight_addons_requested.connect(
		func highlight_addon_file() -> void:
			var self_path := (get_script() as GDScript).resource_path
			file_system_dock_manager.fade_in_file(self_path)
	)
	file_system_dock.unlock_tree_requested.connect(file_system_dock_manager.make_tree_selectable)

	elements_of_note.remove_highlights_requested.connect(
		func clean_all_highlights():
			overlays.highlights.clean_all_overlays()
			file_system_dock_manager.remove_highlights()
	)
	elements_of_note.remove_blocks_requested.connect(overlays.blocks.clean_all_overlays)

	elements_of_note.on_element_block_toggle_requested = overlays.blocks.toggle_overlay_of_node
	elements_of_note.on_element_funnel_requested = overlays.blocks.add_funnel_to_node.bind(_interactables_array)
	elements_of_note.on_element_highlight_toggle_requested = overlays.highlights.toggle_overlay_of_node
	elements_of_note.on_element_visible_toggle_requested = toggle_element_visibility
	
	elements_of_note.setup_actions()
	
	var all_found := true
	for key in _elements:
		var element: Node = _elements[key]
		if element == null:
			push_error("%s was not found"%[key])
			all_found = false
		else:
			debug_window.elements_of_note.add_element(key, element)
	return all_found


func _input(event: InputEvent) -> void:
	if debug_helper.is_debug_mode \
	and show_debugger_window_shortcut.matches_event(event)\
	and (event as InputEventKey).pressed:
		debug_window.visible = not debug_window.visible


###############################################################################
#
# OVERLAYS
#

var overlays := preload("OverlayManager.gd").new()


## Add the overlay layers
func _on_ready_add_overlays_layer() -> void:
	get_tree().root.call_deferred("add_child", overlays)


## Remove the overlay layers
func _on_exit_remove_overlays_layer() -> void:
	overlays.queue_free()


## Toggles an element from visible to invisible.
## Returns a boolean that represents if the element is visible or invisible
func toggle_element_visibility(element: Node) -> bool:
	if not ('visible' in element):
		return true
	element.visible = not element.visible
	return element.visible


###############################################################################
#
# BOOTSTRAP
#


func _ready() -> void:
	_interactables_array.assign(_interactables.values())

	_on_ready_add_overlays_layer()
	_on_ready_verify_integrity()
	_on_ready_setup_file_system_manager()


func _exit_tree() -> void:
	_on_exit_remove_overlays_layer()
	_on_exit_remove_file_system_manager()
