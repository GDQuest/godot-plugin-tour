@tool
###############################################################################
#
# OVERLAY MANAGER
# Adds overlays to controls.
#
# Requires: a stylebox
#
extends Control

const Overlay = preload("Overlay.gd")
const GQuery = preload("GQuery.gd")

## Will hold all overlays
var _overlays_cache := {}

## Required to determine how overlays look
var overlay_style_box: StyleBox
var overlay_mouse_filter: MouseFilter = MOUSE_FILTER_STOP


func maximize() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	assert(overlay_style_box != null, "there's no style box, overlays cannot be drawn")


## Creates an overlay over an element.
## If the element is not a control, will attempt to find the closest control node.
## ---
## @param node the node to create an overlay over
## @param style_box the style of the overlay
## @returns {Overlay | null}
func add_overlay(node: Node) -> Overlay:
	if _overlays_cache.has(node):
		return
	var control: Control = GQuery.find(node, func (node: Node) -> bool: return node is Control)
	if control == null:
		return null
	var panel := Overlay.new()
	panel.stylebox = overlay_style_box
	panel.fit_control(control)
	panel.mouse_filter = overlay_mouse_filter
	_overlays_cache[node] = panel
	add_child(panel)
	return panel


## Removes all overlays
func clean_all_overlays() -> void:
	for child in get_children():
		child.queue_free()
	_overlays_cache = {}


## Removes the highlights overlays of a specific node you were highlighting
func clean_overlay_of(target: Node) -> void:
	if not _overlays_cache.has(target):
		return
	(_overlays_cache[target] as Overlay).queue_free()
	_overlays_cache.erase(target)


## Toggles an overlay off or on. Mostly used in debug functions, to make sure the proper
## nodes are targeted.
## returns a boolean that represents if the overlay is on or off
func toggle_overlay_of(node: Node) -> bool:
	if _overlays_cache.has(node):
		clean_overlay_of(node)
		return false
	else:
		add_overlay(node)
		return true


## Highlights an element.
## If the element is not a control, will attempt to find the closest control node.
##
## Optionally fades out the highlight if `fade` is provided.
## ---
## @param node the node to highlight
## @param fade if this value is above 0, the highlighter will fade in over that many
##             seconds.
## @param delay if this value is above 0 and if `fade` is also above 0, the highlighter
##              will fade out and remove the node after `delay` seconds.
func add_overlay_fade_in(node: Node, fade_in := 1.0, delay:= 0.0) -> void:
	var panel := add_overlay(node)	
	if panel and fade_in > 0:
		var tween := create_tween()\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN_OUT)
		panel.modulate.a = 0
		tween.tween_property(panel, "modulate:a", 1, fade_in)
		if delay > 0:
			tween.tween_interval(delay)
			tween.tween_property(panel, "modulate:a", 0, fade_in)
			tween.tween_callback(panel.queue_free)


## Overlays all elements except the one specified.
## If the element is not a control, will attempt to find the closest control node.
##
## ---
## @param node the node to skip blocking
## @param nodes all the other nodes
func add_funnel(node: Node, all: Array[Node]) -> void:
	clean_all_overlays()
	for node_to_block in all:
		if node_to_block == node:
			continue
		add_overlay(node_to_block)
