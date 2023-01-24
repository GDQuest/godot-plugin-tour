extends Node


###############################################################################
#
# CONSTANTS
#

## Used in `find` to skip processing a node's children
## @see `find`
const SKIP := {"skip": true}
const Overlay = preload("Overlay.gd")
const style_box_highlight = preload("style_box_highlight.tres")
const style_box_block = preload("style_box_block.tres")


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
@onready var editor_root: Node = find(get_tree().root, func (node: Node) -> bool: 
	return node.get_class() == "EditorNode"
)

## The editor window, containing all the controls, popups, and so on
@onready var editor_chrome: Panel = find(
	find(editor_root, func (node: Node) -> bool: return node is Control, 1)
	, func (node: Node) -> bool: return node is Panel
, 1)

###############################################################################
# MENU

## The editor top bar, with the menu and context switches
@onready var editor_title_bar: HBoxContainer = find(editor_chrome, func (node: Node) -> bool: 
	return node.get_parent() is VBoxContainer
, 2)


## The menu to the left, with "scene", "project", and so on
@onready var popout_menu_bar: MenuBar = find(editor_title_bar, func (node: Node) -> bool: 
	return node is MenuBar
, 1)


## The menu in the middle, with "2D", "3D", "Script", "AssetLib"
@onready var context_switcher: HBoxContainer = find(editor_title_bar, func (node: Node) -> bool: 
	return node != editor_title_bar \
		and node is HBoxContainer \
		and node.get_child_count() > 1
, 1)


## The menu to the right, with "Play", "Pause", and so on
@onready var runner_buttons: HBoxContainer = find(editor_title_bar, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)

## The combo box to the right, with "Forward+", "Mobile", "Compatibility"
@onready var renderer_drop_down: OptionButton = find(editor_title_bar, func (node: Node) -> bool: 
	return node is OptionButton \
		and node.get_parent() is HBoxContainer
, 2)


###############################################################################
# MAIN WINDOW NODES

## The editor window's sans the top menu bar
@onready var editor_workspace_area: HSplitContainer = find(editor_chrome, func (node: Node) -> bool: 
	return node is HSplitContainer \
		and node.get_parent() is HSplitContainer
)

## The left column, where the file dock and the scene tree usually reside
@onready var column_left: VSplitContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VSplitContainer
)

## The middle column, with the view and the bottom log
@onready var column_middle: VSplitContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VSplitContainer \
		and node.get_parent() is VBoxContainer \
		and node.get_parent().get_parent() is HSplitContainer
)


## The right column, where the inspector usually resides
@onready var column_right: HSplitContainer = find(editor_workspace_area, func (node: Node) -> bool: 
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
@onready var file_system_dock: FileSystemDock = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is FileSystemDock
)

## The scene tree
## Internal class: SceneTreeDock, but it is not exposed to GDScript
@onready var scene_tree_dock: Node = find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "SceneTreeDock" \
		and node.name == "Scene" \
		and not (node is PopupMenu)
)

## The Import dock, usually situated in the left column, in the same tab container as the scene tree
@onready var import_dock: VBoxContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent().name == "Import" \
		and node.get_parent().get_class() == "ImportDock"
)


###############################################################################
# MIDDLE BOTTOM COLUMN
# Guaranteeed to be in the middle

## The bottom dock, containing debugger, errors, profiler, and so on
@onready var feedback_area: VBoxContainer = find(column_middle, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent() is PanelContainer
, 2)


## Bottom dock tab bar
@onready var feedback_area_tab_bar: HBoxContainer = find(feedback_area, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is HBoxContainer
, 2)

###############################################################################
# MIDDLE TOP COLUMN
# Guaranteeed to be in the middle

## The middle upper dock, containing the main viewport, the scene tabs, and tool menu
@onready var canvas_area: VBoxContainer = find(column_middle, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.get_parent() is VSplitContainer
, 2)


## The top scene tabs dock, containing the tabs and the expand button
@onready var scene_tabs_area: HBoxContainer = find(canvas_area, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)


## The tab bar containing scenes
@onready var scene_tabs: TabBar = find(scene_tabs_area, func (node: Node) -> bool: 
	return node is TabBar
, 2)


## The plus button at the end of the scenes tabs
@onready var scene_tabs_plus_button: Button = find(scene_tabs, func (node: Node) -> bool: 
	return node is Button
, 1)


## Main screen, containing the top toolbox and the viewport
@onready var main_screen: VBoxContainer = find(canvas_area, func (node: Node) -> bool: 
	return node is VBoxContainer \
		and node.name == "MainScreen"
, 2)

## Main screen toolbar
@onready var scene_toolbar: HFlowContainer = find(main_screen, func (node: Node) -> bool: 
	return node is HFlowContainer \
		and node.get_parent().get_class() == "CanvasItemEditor"
, 2)

## Scene toolbar buttons, which are constant no matter what is selected
@onready var scene_toolbar_buttons: HBoxContainer = find(scene_toolbar, func (node: Node) -> bool: 
	return node is HBoxContainer
, 1)

## Scene toolbar buttons, which change depending on the selected node
@onready var scene_contextual_buttons: HBoxContainer = find(scene_toolbar, func (node: Node) -> bool: 
	return node is HBoxContainer \
		and node.get_parent() is PanelContainer
, 2)

## SubViewportContainer
@onready var viewport: Node = find(canvas_area, func (node: Node) -> bool: 
	return node.get_class() == "SubViewportContainer" \
		and node.get_parent() is Control \
		and node.get_parent().get_parent() is HSplitContainer
)

###############################################################################
# RIGHT COLUMN
# Not guaranteed to be in the left column, so they do not depend on it


## The inspector dock. Real class is "InspectorDock", but it is not exposed.
@onready var inspector_dock: Node = find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "InspectorDock" and node.name == "Inspector"
)

## The Node dock. Real class is "NodeDock", but it is not exposed.
@onready var node_dock: Node = find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "NodeDock" and node.name == "Node"
)

## The History dock. Real class is "HistoryDock", but it is not exposed.
@onready var history_dock: Node = find(editor_workspace_area, func (node: Node) -> bool: 
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
	"editor_root": editor_root,
	"editor_chrome": editor_chrome,
	"editor_title_bar": editor_title_bar,
	"popout_menu_bar": popout_menu_bar,
	"context_switcher": context_switcher,
	"runner_buttons": runner_buttons,
	"renderer_drop_down": renderer_drop_down,
	"editor_workspace_area": editor_workspace_area,
	"column_left": column_left,
	"column_middle": column_middle,
	"column_right": column_right,
	"file_system_dock": file_system_dock,
	"scene_tree_dock": scene_tree_dock,
	"import_dock": import_dock,
	"feedback_area": feedback_area,
	"feedback_area_tab_bar": feedback_area_tab_bar,
	"canvas_area": canvas_area,
	"scene_tabs_area": scene_tabs_area,
	"scene_tabs": scene_tabs,
	"scene_tabs_plus_button": scene_tabs_plus_button,
	"main_screen": main_screen,
	"scene_toolbar": scene_toolbar,
	"scene_toolbar_buttons": scene_toolbar_buttons,
	"scene_contextual_buttons": scene_contextual_buttons,
	"viewport": viewport,
	"inspector_dock": inspector_dock,
	"node_dock": node_dock,
	"history_dock": history_dock,
}

## Represents the main nodes of interest in the editor.
## Used internally as a list to block all interactable elements in the editor.
## @see `add_overlays_block_all_except`
@onready var _interactables := {
	# top bar
	"popout_menu_bar": popout_menu_bar,
	"context_switcher": context_switcher,
	"runner_buttons": runner_buttons,
	"renderer_drop_down": renderer_drop_down,
	
	# Left Column
	"file_system_dock": file_system_dock,
	"scene_tree_dock": scene_tree_dock,
	"import_dock": import_dock,
	
	# Middle Column
	"feedback_area": feedback_area,
	"canvas_area": canvas_area,
	"scene_tabs": scene_tabs, 
	"scene_tabs_plus_button": scene_tabs_plus_button, 
	"main_screen": main_screen, 
	"viewport": viewport, 
	"scene_toolbar_buttons": scene_toolbar_buttons, 
	"scene_contextual_buttons": scene_contextual_buttons, 
	
	# Right Column
	"inspector_dock": inspector_dock, 
	"node_dock": node_dock, 
	"history_dock": history_dock, 
}

###############################################################################
#
# DEBUG UTILITIES
# 
# Run godot with the custom command line argument --tour-debug:
# ```
# godot --editor . -- --tour-debug
# ```
# Then, show or hide the window with F9
#

var command_line_arguments := get_command_line_arguments()
var is_debug_mode: bool = command_line_arguments.has("tour-debug") and command_line_arguments["tour-debug"] == true
var debug_window: Window = null

static func get_command_line_arguments() -> Dictionary:
	var arguments := {}
	for argument in OS.get_cmdline_user_args():
		argument = argument.lstrip("--").to_lower()
		if argument.find("=") > -1:
			var arg_tuple := argument.split("=")
			var key := arg_tuple[0]
			var value := arg_tuple[1].strip_edges()
			arguments[key] = value
		else:
			var key := argument
			var value := true
			if argument.begins_with("no-"):
				value = false
				key = argument.lstrip("no-")
			arguments[key] = value
	return arguments

func _input(event: InputEvent) -> void:
	if is_debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		print("hey!")
		debug_window.visible = not debug_window.visible

func _make_editor_button(icon: String, text := "", toggle_mode := true) -> Button:
	var btn := Button.new()
	btn.icon = get_tree().root.theme.get_icon(icon, "EditorIcons")
	btn.toggle_mode = toggle_mode
	btn.text = text
	return btn

## Checks that all the basic elements are there
func _on_ready_verify_integrity() -> bool:
	if not Engine.is_editor_hint():
		printerr("This script is editor only")
		return false
	
	if not is_debug_mode:
		return true
	
	debug_window = Window.new()
	debug_window.size = Vector2i(1,1) * 300
	#debug_window.always_on_top = true
	debug_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN
	debug_window.transient = true
	add_child(debug_window)

	var buttons_container := VBoxContainer.new()
	buttons_container.anchor_bottom = 1
	buttons_container.anchor_right = 1
	
	var buttons_container_scroller := ScrollContainer.new()
	buttons_container_scroller.add_child(buttons_container)
	buttons_container_scroller.anchor_bottom = 1
	buttons_container_scroller.anchor_right = 1

	debug_window.add_child(buttons_container_scroller)

	var all_found := true
	#for name in get_tree().root.theme.get_icon_list("EditorIcons"):
	#	buttons_container.add_child(make_button(name, name))

	for key in _elements:
		var element: Node = _elements[key]
		if element == null:
			push_error("%s was not found"%[key])
			all_found = false
		else:
			var row:= HBoxContainer.new()
			
			var label := Label.new()
			label.text = "%s(%s#%s)"%[key, element.name, element.get_class()]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)

			var highlight_button: Button = _make_editor_button("GizmoLight", "", true)
			highlight_button.toggled.connect(toggle_overlay_highlight.bind(element))
			row.add_child(highlight_button)

			var visible_button: Button = _make_editor_button("GuiVisibilityVisible", "", true)
			visible_button.toggled.connect(func(): element.visible = not element.visible)
			row.add_child(visible_button)

			buttons_container.add_child(row)
	return all_found


###############################################################################
#
# OVERLAYS
#
#

## Will hold all overlays
var overlays_layer: Control


## Add the overlay layer
## TODO: make sure the overlay is always on top?
func _on_ready_add_overlays_layer() -> void:
	overlays_layer = Control.new()
	editor_root.add_child(overlays_layer)
	overlays_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlays_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlays_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Remove the overlay layer
func _on_exit_remove_overlays_layer() -> void:
	if overlays_layer != null:
		overlays_layer.queue_free()


## Creates an overlay over an element.
## If the element is not a control, will attempt to find the closest control node.
## ---
## @param node the node to create an overlay over
## @param style_box the style of the overlay
## @returns {Overlay | null}
func add_overlay(node: Node, style_box: StyleBox) -> Overlay:
	var control: Control = find(node, func (node: Node) -> bool: return node is Control)
	if control == null:
		return null
	var panel := Overlay.new()
	panel.stylebox = style_box
	panel.target = node
	panel.fit_control(control)
	overlays_layer.add_child(panel)
	return panel


## Removes all overlays
func clean_overlays() -> void:
	for child in overlays_layer.get_children():
		child.queue_free()


## Removes the overlays of a specific node you were highlighting or blocking
func clean_overlays_of(target: Node) -> void:
	for child in overlays_layer.get_children():
		if child is Overlay and child.target == target:
			child.queue_free()


## Highlights an element.
## If the element is not a control, will attempt to find the closest control node.
##
## Optionally fades out the highlight if `fade` is provided.
## ---
## @param node the node to highlight
## @param fade if this value is above 0, the highlighter will fade over that many
##             seconds.
## @param delay if this valud is above 0 and if fade is also above 0, the highlighter
##              will delay fading out over that many seconds.
func add_overlay_highlight(node: Node, fade := 0.0, delay:= 0.0) -> void:
	var panel := add_overlay(node, style_box_highlight)
	if panel and fade > 0:
		var tween := create_tween()\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), fade)\
				.set_delay(delay)
		tween.tween_callback(panel.queue_free)


## Toggles an overlay of or on. Mostly used in debug functions, to make sure the proper
## nodes are targeted.
func toggle_overlay_highlight(toggled: bool, node: Node) -> void:
	if toggled:
		add_overlay_highlight(node)
	else:
		clean_overlays_of(node)

## Blocks an Element
## If the element is not a control, will attempt to find the closest control node.
##
## ---
## @param node the node to block
func add_overlay_block(node: Node) -> void:
	var panel := add_overlay(node, style_box_block)


## Blocks all editor elements except the one specified.
## If the element is not a control, will attempt to find the closest control node.
##
## ---
## @param node the node to skip blocking
func add_overlays_block_all_except(node: Node) -> void:
	for key in _interactables:
		var node_to_block: Node = _interactables[key]
		if node_to_block == node:
			continue
		add_overlay_block(node_to_block)


###############################################################################
#
# STATIC UTILITIES
#


## Finds a nested node in the given tree, with a given predicate. The predicate
## receives the node as an argumebnt and:
## - *must* return true if you want to select the node.
## - *may* return the constant `SKIP` if you do not want its children to be processed.
##
## @param target the start of the search. This root _is_ passed to the predicate
## @param {Node -> bool}
## @param max_depth use this to limit the search's depth. Defaults to 40
static func find(target: Node, predicate: Callable, max_depth := 40) -> Control:
	if max_depth < 0 or target == null:
		return null
	var result = predicate.call(target)
	if result == true:
		return target
	if result is Dictionary and result == SKIP:
		return null
	for child in target.get_children():	
		var found := find(child, predicate, max_depth - 1)
		if found != null:
			return found
	return null


###############################################################################
#
# BOOTSTRAP
#


func _ready() -> void:
	_on_ready_verify_integrity()
	_on_ready_add_overlays_layer()


func _exit_tree() -> void:
	_on_exit_remove_overlays_layer()


func temp_test():
	#clean_overlays()
	#add_overlays_block_all_except(runner_buttons)
	pass