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
# SCROLL TRACKING
#

var hscrollbar: HScrollBar
var vscrollbar: VScrollBar

# Result of scroll
var pane_position := Vector2.ZERO

func _setup_scrolling_handlers() -> void:
	# TODO: doesn't work with either value_changed or scrolling
	hscrollbar.scrolling.connect(_on_scrollbar_scroll.bind(hscrollbar, vscrollbar))
	vscrollbar.scrolling.connect(_on_scrollbar_scroll.bind(hscrollbar, vscrollbar))


func _on_scrollbar_scroll(hscroll: HScrollBar, vscroll: VScrollBar) -> void:
	print("sdsffs")
	var x := hscroll.value
	var y := vscroll.value
	if x != pane_position.x or y != pane_position.y:
		pane_position = Vector2(x, y)
	print(pane_position)

###############################################################################
#
# ELEMENTS OF INTEREST
#

var file_system_dock: FileSystemDock
var file_system_tabs: TabContainer
var file_system_tree: Tree
var search_input: LineEdit

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
	
	hscrollbar = GQuery.find(file_system_tree, func (node: Node) -> bool: 
		return node is HScrollBar
	, 100, 1, true)
	vscrollbar = GQuery.find(file_system_tree, func (node: Node) -> bool: 
		return node is VScrollBar
	, 100, 1, true)


###############################################################################
#
# TREE CACHING
#

## The node marked "res://"
var root: TreeItem

## Finds the core file node in the filesystem dock
func get_or_find_root(refresh := false) -> TreeItem:
	if root == null or refresh == true:
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


## Returns the rectangle the encloses a file in the FileSystem dock file tree. 
## This *only* works for the file tree and makes assumptions that a regular Tree
## will not fullfill.
func get_file_rect(file_path: String, global := true) -> Rect2:
	var file := find_file(file_path)
	if file == null:
		return Rect2()
	var parent := file.get_parent()
	while parent != null:
		parent.collapsed = false
		parent = parent.get_parent()
	# rectangles get created in the next frame
	await get_tree().process_frame
	file_system_tree.scroll_to_item(file)
	await get_tree().process_frame
	var rect := get_item_rect(file)
	if global:
		rect.position += file_system_tree.global_position
		## TODO: add scroll and remove masked parts
	return rect


## Returns the rectangle the encloses a file in the FileSystem dock file tree. 
## This *only* works for the file tree and makes assumptions that a regular Tree
## will not fullfill.
## This function requires the item to be visible and expanded
func get_item_rect(item: TreeItem) -> Rect2:
	if item == null:
		return Rect2()
	return item.get_meta("__focus_rect") as Rect2


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
	_setup_scrolling_handlers()
