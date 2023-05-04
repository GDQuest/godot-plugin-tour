@tool
extends Control

@export var outline_style_box : StyleBoxFlat
var highlighted_nodes := [] : set = set_highlighted_nodes
var is_highlighting : bool = false : set = set_is_highlighting

var highlight_ref = []

@onready var outline_container = %OutlineContainer
@onready var rects_holder = %RectsHolder
@onready var dark_zone = %DarkZone


func _ready():
	dark_zone.color.a = 0.0


func set_highlighted_nodes(nodes : Array):
	var added_nodes = nodes.filter(
		func(node): 
			return !highlighted_nodes.has(node)
			)
	
	var removed_nodes = highlighted_nodes.filter(
		func(node): 
			return !nodes.has(node)
			)
	
	highlighted_nodes = nodes
	
	for node in added_nodes:
		var color_rect = ColorRect.new()
		color_rect.color = Color.BLACK
		color_rect.size = node.get_rect().size
		color_rect.position = node.get_global_transform_with_canvas().origin
		rects_holder.add_child(color_rect)
	
		var t = create_tween()
		t.tween_property(color_rect, "modulate:a", 1.0, 0.4).from(0.0)
		
		highlight_ref.append({"color_rect": color_rect, "node": node})
		
	for node in removed_nodes:
		var ref_index = highlight_ref.filter(func(el): return el.node == node)
		if ref_index.size() == 0: continue
		var ref = ref_index[0]
		var color_rect = ref.color_rect
		var t = create_tween()
		t.tween_property(color_rect, "modulate:a", 0.0, 0.4)
		t.tween_callback(func(): color_rect.queue_free())
		highlight_ref.erase(ref)
	
	for child in outline_container.get_children():
		child.queue_free()
	
	for node in nodes:
		var panel = Panel.new()
		panel.size = node.get_rect().size
		panel.position = node.get_global_transform_with_canvas().origin
		panel.add_theme_stylebox_override("panel", outline_style_box)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline_container.add_child(panel)
	
	is_highlighting = highlighted_nodes.size() > 0


func set_is_highlighting(state : bool):
	if is_highlighting == state: return
	is_highlighting = state
	var opacity = float(is_highlighting) * 0.7
	var t = create_tween()
	t.tween_property(dark_zone, "color:a", opacity, 0.25)
