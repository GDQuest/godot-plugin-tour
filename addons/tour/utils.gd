extends Node


static func get_text_edit_lines_rect(text_edit: TextEdit, starting_line: int, ending_line: int) -> Rect2:
	var line_rect := text_edit.get_rect_at_line_column(starting_line,0)
	var lines_width = range(starting_line, ending_line + 1).map(
		func(l):
			return text_edit.get_line_width(l)
			)
	
	return Rect2(
		Vector2(line_rect.position) + text_edit.global_position,
		Vector2(
			lines_width.max(),
			line_rect.size.y * (ending_line - starting_line + 1)
		)
	)
