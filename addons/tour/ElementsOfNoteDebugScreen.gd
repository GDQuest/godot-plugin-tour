@tool
extends Control

const METADATA_NODE_REFERENCE := "METADATA_NODE_PATH"
const ROW_BUTTON_DISABLE = 1000

signal remove_highlights_requested
signal remove_blocks_requested

@onready var _elements_tree: Tree = %Tree
@onready var _remove_all_highlights_button: Button = %RemoveAllHighlights
@onready var _remove_all_blocks_button: Button = %RemoveAllBlocks

var _actions: Array[RowAction] = []
var _tree_root: TreeItem

func _ready() -> void:
	_remove_all_highlights_button.pressed.connect(emit_signal.bind("remove_highlights_requested"))
	_remove_all_blocks_button.pressed.connect(emit_signal.bind("remove_blocks_requested"))
	
	_tree_root = _elements_tree.create_item()
	_elements_tree.hide_root = true
	_elements_tree.button_clicked.connect(_on_tree_button_clicked)


func _on_tree_button_clicked(row: TreeItem, column: int, id: int, _mouse_button_index: int) -> void:
	if id == ROW_BUTTON_DISABLE:
		return
	var element: Node = row.get_meta(METADATA_NODE_REFERENCE)
	var action := _actions[id]
	action.run(element)
	row.set_button(column, id, get_theme_icon(action.icon, "EditorIcons"))


## Adds an element to the element list, with optionally buttons
func add_element(key: String, element: Node) -> void:
	var row := _elements_tree.create_item(_tree_root)
	
	row.set_text(0,"%s(%s#%s)"%[key, element.name, element.get_class()])
	row.set_tooltip_text(0, "\n".join(['Tour name: "%s"'%[key], 'Node name: "%s'%[element.name], 'Class: %s'%[element.get_class()]]))
	row.set_meta(METADATA_NODE_REFERENCE, element)
	row.set_icon_max_width(0, 32)
	for id in _actions.size():
		var action = _actions[id]
		if action.name == "visible" and not ("visible" in element):
			id = ROW_BUTTON_DISABLE
		var icon := get_theme_icon(action.get_initial_icon(element), "EditorIcons")
		row.add_button(0, icon, id, false, action.tooltip)
		


func add_action(props: Dictionary) -> void:
	var row_action := RowAction.new().setup(props)
	_actions.append(row_action)


class RowAction:
	var name := ""
	var tooltip := ""
	var icon_on := ""
	var icon_off := ""
	var icon := ""
	var is_toggle := true
	## The callable receives a node and should return a boolean indicating the icon to use
	var action: Callable

	func setup(props: Dictionary) -> RowAction:
		for key in props:
			assert(key in self)
			self[key] = props[key]
		return self

	func get_initial_icon(node: Node) -> String:
		if is_toggle:
			run(node)
			run(node)
		return icon

	func run(node: Node) -> void:
		var result: Variant = action.call(node)
		if is_toggle and result is bool:
			icon = icon_on if (result == true and icon_on != "") else icon_off
