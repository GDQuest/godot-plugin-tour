@tool
extends Control
###############################################################################
#
# HELPER for FILE SYSTEM DOCK
#

const GQuery = preload("GQuery.gd")

var file_system_dock: FileSystemDock
var file_system_tabs: TabContainer
var file_system_tree: Tree
var root: TreeItem

func setup() -> void:
	file_system_tabs = GQuery.find_ancestor(file_system_dock, func (node: Node) -> bool: return node is TabContainer)
	file_system_tree = GQuery.find(file_system_dock, func (node: Node) -> bool: return node is Tree)

func show() -> void:
	var idx := file_system_tabs.get_tab_idx_from_control(file_system_dock)
	file_system_tabs.current_tab = idx


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



func get_or_find_root() -> TreeItem:
	if not root:
		root = find_item_by_predicate(
			file_system_tree.get_root(), 
			func (item: TreeItem) -> bool: 
				return item.get_text(0) == "res://"
		)
	return root


func get_file_rect(file_path: String, global := true) -> Rect2:
	var rect := get_item_rect(find_file(file_path))
	if global:
		rect.position += file_system_dock.global_position
	return rect


func get_item_rect(item: TreeItem) -> Rect2:
	if item == null:
		return Rect2()
	return item.get_meta("__focus_rect") as Rect2


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


