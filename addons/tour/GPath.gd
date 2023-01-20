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

## Internal class: EditorNode, but it is not exposed to GDScript
@onready var editor_root: Node = find(get_tree().root, func (node: Node) -> bool: 
	return node.get_class() == "EditorNode"
)

## The editor window, containing all the controls, popups, and so on
@onready var editor_chrome: Panel = find(
	find(editor_root, func (node: Node) -> bool: return node is Control, 1)
	, func (node: Node) -> bool: return node is Panel
, 1)

## The editor top bar, with the menu and context switches
@onready var editor_title_bar: Node = find(editor_chrome, func (node: Node) -> bool: 
	return node.get_parent() is VBoxContainer
, 2)


## The menu to the left, with "scene", "project", and so on
@onready var menu_bar: MenuBar = find(editor_title_bar, func (node: Node) -> bool: 
	return node is MenuBar
, 1)


## The menu to the left, with "scene", "project", and so on
@onready var context_switcher: HBoxContainer = find(editor_title_bar, func (node: Node) -> bool: 
	return node is HBoxContainer and node.get_child_count() > 1
, 1)


## The menu to the left, with "scene", "project", and so on
@onready var runner_buttons: HBoxContainer = find(editor_title_bar, func (node: Node) -> bool: 
	return node is HBoxContainer and node.get_parent() is PanelContainer
, 2)

## The menu to the left, with "scene", "project", and so on
@onready var renderer_drop_down: OptionButton = find(editor_title_bar, func (node: Node) -> bool: 
	return node is OptionButton and node.get_parent() is HBoxContainer
, 2)


## The editor window's sans the top menu bar
@onready var editor_workspace_area: HSplitContainer = find(editor_chrome, func (node: Node) -> bool: 
	return node is HSplitContainer and node.get_parent() is HSplitContainer
)

## The left column, where the file dock and the scene tree usually reside
@onready var column_left: VSplitContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VSplitContainer
)

## The middle column, with the view and the bottom log
@onready var column_middle: VBoxContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is VBoxContainer and node.get_parent() is HSplitContainer
, 2)

## The right column, where the inspector usually resides
@onready var column_right: HSplitContainer = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is HSplitContainer and node.get_parent() is HSplitContainer
, 2)

## The file system dock, showing the various files in the project
@onready var file_system_dock: FileSystemDock = find(editor_workspace_area, func (node: Node) -> bool: 
	return node is FileSystemDock
)

## The scene tree
## Internal class: SceneTreeDock, but it is not exposed to GDScript
@onready var scene_tree_dock: Node = find(editor_workspace_area, func (node: Node) -> bool: 
	return node.get_class() == "SceneTreeDock" and node.name == "Scene" and not (node is PopupMenu)
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
	"menu_bar": menu_bar,
	"context_switcher": context_switcher,
	"runner_buttons": runner_buttons,
	"renderer_drop_down": renderer_drop_down,
	"editor_workspace_area": editor_workspace_area,
	"column_left": column_left,
	"column_middle": column_middle,
	"column_right": column_right,
	"file_system_dock": file_system_dock,
	"scene_tree_dock": scene_tree_dock,
}

## Used to block all interactable elements in the editor.
## @see `add_overlays_block_all_except`
@onready var _interactables := {
	# top bar
	"menu_bar": menu_bar,
	"context_switcher": context_switcher,
	"runner_buttons": runner_buttons,
	"renderer_drop_down": renderer_drop_down,
	# Left Column
	"file_system_dock": file_system_dock,
	"scene_tree_dock": scene_tree_dock,
}


## Checks that all the basic elements are there
func _verify_integrity() -> bool:
	if not Engine.is_editor_hint():
		printerr("This script is editor only")
		return false
	var all_found := true
	for key in _elements:
		var element = _elements[key]
		if element == null:
			push_error("%s was not found"%[key])
			all_found = false
	return all_found


###############################################################################
#
# OVERLAYS
#
#

## Will hold all overlays
var overlays_layer := Control.new()


## Add the overlay layer
## TODO: make sure the overlay is always on top?
func _on_ready_add_overlays_layer() -> void:
	editor_root.add_child(overlays_layer)
	overlays_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlays_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlays_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
		if child is Overlay and child.target == node:
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
	_verify_integrity()
	_on_ready_add_overlays_layer()


func temp_test():
	clean_overlays()
	add_overlays_block_all_except(runner_buttons)