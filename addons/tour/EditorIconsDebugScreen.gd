@tool
extends Control

@onready var _icons_grid: Control = %IconsGrid
@onready var _icons_search_bar: LineEdit = %IconsSearchBar
@onready var _copy_full_code_toggle: CheckButton = %CopyFullCodeToggle

func populate_icons(theme: Theme, icon_list_name := "EditorIcons") -> void:
	
	var buttons: Array[BaseButton] = []
	
	for name in theme.get_icon_list(icon_list_name):
		var btn := Button.new()
		btn.size = Vector2(1, 1) * 32
		btn.custom_minimum_size = btn.size
		btn.icon = get_theme_icon(name, icon_list_name)
		btn.expand_icon = true
		btn.tooltip_text = name
		btn.name = name
		var acquire_string := 'get_theme_icon("%s", "%s")'%[name, icon_list_name]
		btn.pressed.connect(func _on_button_pressed():
			var clipboard := acquire_string if _copy_full_code_toggle.button_pressed else name
			DisplayServer.clipboard_set(clipboard)
		)
		_icons_grid.add_child(btn, true)
		buttons.append(btn)
	
	_icons_search_bar.text_changed.connect(func _on_text_changed(text: String) -> void:
		text = text.to_lower()
		for button in buttons:
			var name = button.name.to_lower()
			button.visible = (text == "" or text.similarity(name) > 0.5 or name.contains(text))
	)
