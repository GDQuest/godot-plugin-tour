@tool
extends Control
###############################################################################
#
# HELPER for FILE SYSTEM DOCK
#
# Manages the file system dock, shows, hides, and highlights files
#

const GQuery = preload("GQuery.gd")

###############################################################################
#
# OVERLAYS
#

var highlights := preload("OverlayManager.gd").create_highlights_layer()

func _on_ready_add_overlay() -> void:
	file_system_tree.add_child(highlights)

###############################################################################
#
# ELEMENTS OF INTEREST
#

var file_system_dock: FileSystemDock
var file_system_tabs: TabContainer
var file_system_tree: Tree
var search_input: LineEdit

## Creates references to UI elements that we might need
func _setup_elements_of_interest() -> void:
	file_system_tabs = GQuery.find_ancestor(file_system_dock, func (node: Node) -> bool: 
		return node is TabContainer
	)

	file_system_tree = GQuery.find(file_system_dock, func (node: Node) -> bool: 
		return node is Tree
	)

	search_input = GQuery.find(file_system_dock, func (node: Node) -> bool:
		return node is LineEdit \
		and node.get_parent() is HBoxContainer \
		and node.get_parent().get_parent() is VBoxContainer
	)


###############################################################################
#
# HIGHLIGHTS and SELECTION
#

## Creates a temporary highlight around the file, selects it, 
## @param file_path a path in the form `res://path/to/file.gd`
## @param prepare   if true, the dock will be shown, and any previously selected 
##                  file will be deselected
## @param scroll_to if true, the file will be scrolled to
## @param delay_before if above 0, the overlay will wait that time before showing up
func highlight_file(file_path: String, prepare := true, scroll_to := true, delay_before := 0.0) -> void:
	if prepare == true:
		prepare_dock_for_selection()
	var item := find_file(file_path)
	if item == null:
		return
	await ensure_visible(item, scroll_to)
	var rect := get_item_rect(item, false)
	if rect.size == Vector2.ZERO:
		push_error("Could not find %s"%[file_path])
		return
	var panel := highlights.add_overlay_rectangle(file_path, rect)
	highlights.fade_in_panel(panel, 0.3, 0.1, delay_before)
	item.set_selectable(0, true)
	item.select(0)


## TODO: DOES NOT WORK
## Creates a temporary highlight around several files, selects them, 
## and deselects everything else
## @param file_paths a set of paths in the form `res://path/to/file.gd`
## @param prepare    if true, the dock will be shown, and any previously selected 
##                   file will be deselected
func highlight_file_set(file_paths: PackedStringArray, prepare := true) -> void:
	push_warning("This method does not work correctly yet")
	if prepare == true:
		prepare_dock_for_selection()
	for index in file_paths.size():
		var file_path := file_paths[index]
		var delay_before := float(index) * 0.1
		var scroll_to := index == 0
		await highlight_file(file_path, false, scroll_to, delay_before)


## Removes all highlights
func remove_highlights() -> void:
	highlights.clean_all_overlays()


## Ensures the dock is visible and that all files are deselected
## Locks all files from manual selection, which means you need to make them
## selectable yourself
func prepare_dock_for_selection() -> void:
	show_filesystem_dock()
	remove_highlights()
	file_system_tree.deselect_all()
	make_tree_unselectable()


func make_tree_unselectable() -> void:
	var root := get_or_find_root()
	root.call_recursive("set_selectable", 0, false)


func make_tree_selectable() -> void:
	var root := get_or_find_root()
	root.call_recursive("set_selectable", 0, true)

###############################################################################
#
# TREE CACHING
#

## The node marked "res://"
var root: TreeItem

## Finds the core file node in the filesystem dock
func get_or_find_root(refresh := false) -> TreeItem:
	if root == null or not is_instance_valid(root) or refresh == true:
		root = find_item_by_predicate(
			file_system_tree.get_root(), 
			func (item: TreeItem) -> bool: 
				return item.get_text(0) == "res://"
		)
	return root


###############################################################################
#
# UTILITY METHODS
#

## Makes sure the dock is selected and visible in its tab container
func show_filesystem_dock() -> void:
	var idx := file_system_tabs.get_tab_idx_from_control(file_system_dock)
	file_system_tabs.current_tab = idx


## Debug method retrieving metadata and info about a FileSystemDock TreeItem. Does
## not work with generic TreeItems, but only with those used by the FileTree
func get_tree_item_summary(item: TreeItem) -> Dictionary:
	if item == null:
		return {"[no item found]": true }
	var meta_list := Array(item.get_meta_list())\
		.reduce(
			func (obj: Dictionary, key: String) -> Dictionary: 
				obj[key] = item.get_meta(key)
				return obj\
			, {}
		)
	return {
		child = item,
		icon = item.get_icon(0),
		text = item.get_text(0),
		column_metadata = item.get_metadata(0),
		# access this with get_meta, not get_metadata
		meta = meta_list,
		children_count = item.get_child_count(),
	}


## Ensures the item has all parents uncollapsed, and item is in view 
## Waits two frames, one for all parents to open, and one to ensure the item's
## rectangle is available.
func ensure_visible(item: TreeItem, scroll_to := true) -> void:
	if item == null:
		return
	var parent := item.get_parent()
	while parent != null:
		parent.collapsed = false
		parent = parent.get_parent()
	# rectangles get created in the next frame
	await get_tree().process_frame
	if scroll_to:
		file_system_tree.scroll_to_item(item, true)
	await get_tree().process_frame


## Returns the rectangle the encloses a file in the FileSystem dock file tree. 
## This *only* works for the file tree and makes assumptions that a regular Tree
## will not fullfill.
## This function requires the item to be visible and expanded
func get_item_rect(item: TreeItem, global := false) -> Rect2:
	if item == null:
		return Rect2()
	var rect := item.get_meta("__focus_rect") as Rect2
	if global:
		rect.position += file_system_tree.global_position
	return rect


## Finds a file TreeItem in the file tree. Pass a path in the format
# "res://path/to/my/file"
func find_file(file_path: String) -> TreeItem:
	var path_chunks := file_path.simplify_path().split("/", false)
	
	if path_chunks[0] == "res:":
		path_chunks = path_chunks.slice(1)
	
	var root := get_or_find_root()
	
	return find_item_by_column_text(root.get_children(), path_chunks)


###############################################################################
#
# STATIC HELPERS
#
# These could be generically helpful with trees, but at the moment the file tree
# is the only tree we're interested in manipulating, so it's fine to keep them
# here
#

static func find_item_by_column_text(items: Array[TreeItem], file_path: PackedStringArray, column := 0) -> TreeItem:
	var current_path := file_path[0]
	var remaining := file_path.slice(1)
	for child in items:
		if child.get_text(column) == current_path:
			if file_path.size() == 1:
				return child
			return find_item_by_column_text(child.get_children(), remaining, column)
	return null


static func find_item_by_predicate(target: TreeItem, predicate: Callable, max_depth := 40, min_depth := 0, _current_depth := 0) -> TreeItem:
	if _current_depth > max_depth or target == null:
		return null
	if _current_depth >= min_depth:
		var result = predicate.call(target)
		if result == true:
			return target
	for child in target.get_children():
		var found := find_item_by_predicate(child, predicate, max_depth, min_depth, _current_depth + 1)
		if found != null:
			return found
	return null


###############################################################################
#
# BOOSTRAP
#


func setup() -> void:
	_setup_elements_of_interest()
	_on_ready_add_overlay()


func _exit_tree() -> void:
	if highlights.is_inside_tree():
		file_system_tree.remove_child(highlights)
	highlights.queue_free()
