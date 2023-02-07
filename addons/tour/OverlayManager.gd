@tool
###############################################################################
##
## OVERLAY MANAGER
## Adds highlights or blocks to controls.
##
extends Control
const Overlay = preload("Overlay.gd")
const GQuery = preload("GQuery.gd")

var debug_helper := preload("DebugHelper.gd").new()

## Will hold all overlays
var highlights := create_highlights_layer()
var blocks := create_blocks_layer(debug_helper.is_debug_mode)

## Add the overlay layers
func _init() -> void:
	maximize(self)
	add_child(highlights)
	add_child(blocks)


## Factory function. Is abstracted because it can be used independently
## Returns an OverlayLayer with the "block" style box set (stops mouse)
static func create_blocks_layer(is_debug_mode: bool) -> OverlayLayer:
	var blocks := OverlayLayer.new()
	blocks.overlay_mouse_filter = Control.MOUSE_FILTER_STOP
	var style_box := preload("style_box_block.tres")
	style_box.bg_color.a = 0.8 if is_debug_mode else 0.0
	blocks.overlay_style_box = style_box
	maximize(blocks)
	return blocks


## Factory function. Is abstracted because it can be used independently
## Returns an OverlayLayer with the "highlight" style box set (lets mouse clicks pass)
static func create_highlights_layer() -> OverlayLayer:
	var highlights := OverlayLayer.new()
	highlights.overlay_mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlights.overlay_style_box =preload("style_box_highlight.tres")
	maximize(highlights)
	return highlights


static func maximize(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.anchor_top = Control.ANCHOR_BEGIN
	control.anchor_left = Control.ANCHOR_BEGIN
	control.anchor_bottom = Control.ANCHOR_END
	control.anchor_right = Control.ANCHOR_END
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


###############################################################################
##
## OVERLAY LAYER
## Adds overlays to controls.
##
## Requires: styleboxes
##
class OverlayLayer extends Control:
	
	## Will hold all overlays
	## @type Dictionary[Node|String, Overlay]
	var _overlays_cache := {}


	## Required to determine how overlays look
	var overlay_style_box: StyleBox
	var overlay_mouse_filter: MouseFilter = MOUSE_FILTER_STOP


	func _ready() -> void:
		assert(overlay_style_box != null, "there's no style box, overlays cannot be drawn")

	## Creates an overlay using the set stylebox
	## Never creates the same overlay twice. If an overlay for the given key already
	## exists, it will be returned instead
	##
	## ---
	## @param key either a node, or a string
	func dispense_overlay(key: Variant, rectangle: Rect2) -> Overlay:
		if _overlays_cache.has(key):
			return _overlays_cache[key]
		var panel := Overlay.new()
		panel.stylebox = overlay_style_box
		panel.fit_rectangle(rectangle)
		panel.mouse_filter = overlay_mouse_filter
		_overlays_cache[key] = panel
		add_child(panel)
		return panel


	## Creates an overlay over an element.
	## If the element is not a control, will attempt to find the closest control node.
	## If no control is found, `null` is returned.
	##
	## ---
	## @param node the node to create an overlay over
	## @returns {Overlay | null}
	func add_overlay_to_node(node: Node) -> Overlay:
		if _overlays_cache.has(node):
			return _overlays_cache[node]
		var control: Control = GQuery.find(node, func (node: Node) -> bool: return node is Control)
		if control == null:
			return null
		var panel := dispense_overlay(node, control.get_global_rect())
		return panel



	func add_overlay_rectangle(rect_name: String, rectangle: Rect2) -> Overlay:
		var panel := dispense_overlay(rect_name, rectangle)
		return panel


	## Removes all overlays
	func clean_all_overlays() -> void:
		for child in get_children():
			child.queue_free()
		_overlays_cache = {}


	## Removes the highlights overlays of a specific node or string
	##
	## ---
	## @param key either a node, or a string
	func clean_overlays_of(key: Variant) -> void:
		if not _overlays_cache.has(key):
			return
		(_overlays_cache[key] as Overlay).queue_free()
		_overlays_cache.erase(key)

	
	## Removes a panel by reference (instead of using keys)
	## This is used internally to remove a panel after animating it
	func remove_panel(panel: Overlay) -> void:
		var key: Variant = _overlays_cache.find_key(panel)
		if key == null:
			return
		(_overlays_cache[key] as Overlay).queue_free()
		_overlays_cache.erase(key)


	## Toggles an overlay off or on. Mostly used in debug functions, to make sure the proper
	## nodes are targeted.
	## returns a boolean that represents if the overlay is on or off
	func toggle_overlay_of_node(node: Node) -> bool:
		if _overlays_cache.has(node):
			clean_overlays_of(node)
			return false
		else:
			add_overlay_to_node(node)
			return true


	## Overlays an element slwly over time
	## If the element is not a control, will attempt to find the closest control node.
	## 
	## @see fade_in_panel
	## ---
	## @param node the node to highlight
	## @param fade if this value is above 0, the highlighter will fade in over that many
	##             seconds.
	## @param delay if this value is above 0 and if `fade` is also above 0, the highlighter
	##              will fade out and remove the node after `delay` seconds.
	func add_overlay_fade_in_to_node(node: Node, fade_in := 1.0, delay:= 0.0) -> Overlay:
		var panel := add_overlay_to_node(node)	
		fade_in_panel(panel, fade_in, delay)
		return panel


	## Fades in an overlay over time
	##
	## Optionally fades out the overlay if `fade` is provided.
	##
	## ---
	## @param panel the overlay to fade in
	## @param fade if this value is above 0, the highlighter will fade in over that many
	##             seconds.
	## @param delay if this value is above 0 and if `fade` is also above 0, the highlighter
	##              will fade out and remove the node after `delay` seconds.
	## @param delay_before if above 0, will wait that time before showing up
	func fade_in_panel(panel: Overlay, fade_in := 1.0, delay:= 0.0, delay_before := 0.0) -> Tween:
		if panel and fade_in > 0:
			var tween := create_tween()\
				.set_trans(Tween.TRANS_EXPO)\
				.set_ease(Tween.EASE_IN_OUT)
			panel.modulate.a = 0
			if delay_before > 0:
				tween.tween_interval(delay_before)
			tween.tween_property(panel, "modulate:a", 1, fade_in)
			if delay > 0:
				tween.tween_interval(delay)
				tween.tween_property(panel, "modulate:a", 0, fade_in + fade_in / 4)
				tween.tween_callback(remove_panel.bind(panel))
			return tween
		return null


	## Overlays all elements except the one specified.
	## If the element is not a control, will attempt to find the closest control node.
	##
	## ---
	## @param node the node to skip blocking
	## @param nodes all the other nodes
	func add_funnel_to_node(node: Node, all: Array[Node]) -> void:
		clean_all_overlays()
		for node_to_block in all:
			if node_to_block == node:
				continue
			add_overlay_to_node(node_to_block)
