extends CanvasLayer

var click_position = Vector2.ZERO
var draw_click = false
var draw_node: Control

func _ready():
	layer = 128
	
	# Create a Control node dynamically to handle the drawing
	draw_node = Control.new()
	
	# Ensure this new node does not block mouse clicks
	draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connect the draw signal to our custom function
	draw_node.draw.connect(_on_draw_node_draw)
	
	add_child(draw_node)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_control = get_viewport().gui_get_hovered_control()
		
		if clicked_control:
			print("Click intercepted by: ", clicked_control.name, " | Path: ", clicked_control.get_path())
		else:
			print("Click in empty space or handled by 2D/3D physics.")

		click_position = event.position
		draw_click = true
		draw_node.queue_redraw()

		await get_tree().create_timer(0.2).timeout
		draw_click = false
		draw_node.queue_redraw()

func _on_draw_node_draw():
	if draw_click:
		# Draw a red circle at the click position using the Control node
		draw_node.draw_circle(click_position, 15.0, Color.RED)