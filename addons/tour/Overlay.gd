extends Panel


var stylebox: StyleBox = null:
	set(value):
		set("theme_override_styles/panel", value)
	get:
		return get("theme_override_styles/panel")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fit_control(target_control: Control) -> void:
	size = target_control.size
	global_position = target_control.global_position


func fit_rectangle(target_rectangle: Rect2) -> void:
	size = target_rectangle.size
	global_position = target_rectangle.position

