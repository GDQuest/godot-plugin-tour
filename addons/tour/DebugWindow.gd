###############################################################################
#
# DEBUG WINDOW
# 
# Run godot with the custom command line argument --tour-debug:
# ```
# godot --editor . -- --tour-debug
# ```
# Then, show or hide the window with F9
#

class_name SomethingRandomLetsTry
extends Window

@onready var buttons_container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	print("window ready")
	add_element("ptoato", $ScrollContainer)


func _input(event: InputEvent) -> void:
	if event is InputEventKey \
		and event.pressed \
		and event.keycode == KEY_F9:
			print("hey!")
			visible = not visible


func _make_editor_button(icon: String, text := "", toggle_mode := true) -> Button:
	var btn := Button.new()
	btn.size.y = 32
	btn.icon = theme.get_icon(icon, "EditorIcons") if theme else null
	btn.toggle_mode = toggle_mode
	btn.text = text
	return btn


func _toggle_element_visibility(element: Node) -> void:
	element.visible = not element.visible


## Adds an element to the element list, with a highlight and a hide button
func add_element(key: String, element: Node, on_highlight := Callable()) -> void:
	var row:= HBoxContainer.new()
	
	var label := Label.new()
	label.text = "%s(%s#%s)"%[key, element.name, element.get_class()]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	if on_highlight.is_valid():
		var highlight_button: Button = _make_editor_button("GizmoLight", "", true)
		highlight_button.toggled.connect(on_highlight)
		row.add_child(highlight_button)

	var visible_button: Button = _make_editor_button("GuiVisibilityVisible", "", true)
	visible_button.toggled.connect(_toggle_element_visibility.bind(element))
	row.add_child(visible_button)
	
	buttons_container.add_child(row)
