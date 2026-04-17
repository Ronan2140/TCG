extends Node2D

const card_scene = preload("res://prefab/Card.tscn")

var selected_card = null
var off_set_x = 0.0
var off_set_y = 0.0
var screen_size = Vector2.ZERO
var hovering_card = null
var current_hovered_slot = null

# region _ready and _process
func _ready() -> void:
	screen_size = get_viewport_rect().size
	update_card_connections()

func _process(_delta: float) -> void:
	if selected_card != null:
		var new_position = get_global_mouse_position() + Vector2(off_set_x, off_set_y)
		selected_card.global_position = new_position
		
		var hovered_control = get_viewport().gui_get_hovered_control()
		var valid_slot = null
		
		if hovered_control and "card_in_slot" in hovered_control and not hovered_control.card_in_slot:
			valid_slot = hovered_control
			
		if valid_slot != current_hovered_slot:
			if current_hovered_slot != null:
				# Reset visual for the previous slot
				current_hovered_slot.modulate = Color(1, 1, 1)
				
			current_hovered_slot = valid_slot
			
			if current_hovered_slot != null:
				# Highlight the new slot
				current_hovered_slot.modulate = Color(1.5, 1.5, 1.5)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.is_pressed() and selected_card != null:
			undrag_card()

func update_card_connections():
	for child in get_children():
		if child is Control and child.has_signal("hovered"):
			connect_card_signals(child)

func connect_card_signals(card):
	if card.hovered.is_connected(_on_card_hovered):
		card.hovered.disconnect(_on_card_hovered)
	if card.unhovered.is_connected(_on_card_unhovered):
		card.unhovered.disconnect(_on_card_unhovered)
	if card.left_clicked.is_connected(start_drag):
		card.left_clicked.disconnect(start_drag)

	print("Connecting signals for card: ", card.name)
	card.set_meta("base_scale", card.scale)
	
	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)
	card.left_clicked.connect(start_drag)

	if not card.get_meta("exit_connected", false):
		card.tree_exiting.connect(_on_card_tree_exiting.bind(card))
		card.set_meta("exit_connected", true)

# endregion


# region Card interactions

func start_drag(card):
	selected_card = card
	var card_center = card.global_position
	off_set_x = card_center.x - get_global_mouse_position().x
	off_set_y = card_center.y - get_global_mouse_position().y
	release_card_slot(card)
	
	set_card_mouse_filter_recursive(card, Control.MOUSE_FILTER_IGNORE, Control.MOUSE_FILTER_IGNORE)
	print("Mouse filter set to IGNORE for card: ", card.name)
	card.z_index = 100
	print("Card selected: ", card.name)
	highlight_card(card, true, 1.2)

func undrag_card():
	var dropped_card = selected_card
	selected_card = null
	off_set_x = 0
	off_set_y = 0
	
	set_card_mouse_filter_recursive(dropped_card, Control.MOUSE_FILTER_STOP, Control.MOUSE_FILTER_PASS)
	highlight_card(dropped_card, false)
	
	if current_hovered_slot != null:
		dropped_card.global_position = current_hovered_slot.global_position
		assign_card_to_slot(dropped_card, current_hovered_slot)
		
		# Reset visual state of the slot and clear the variable
		print("Carte déposée dans : ", current_hovered_slot.name)
		current_hovered_slot = null
		return

	print("Carte relâchée hors d'un slot disponible.")

func _on_card_hovered(card):
	if selected_card != null and selected_card != card:
		return
		
	if hovering_card == null:
		hovering_card = card
		print("Card hovered: ", card.name)
		highlight_card(card, true)

func _on_card_unhovered(card):
	if selected_card != null:
		return
		
	print("Card unhovered: ", card.name)
	highlight_card(card, false)
	
	if hovering_card == card:
		hovering_card = null
		
		var current_hover = get_viewport().gui_get_hovered_control()
		if current_hover != null and current_hover.has_signal("hovered") and current_hover != card:
			hovering_card = current_hover
			print("New card hovered: ", hovering_card.name)
			highlight_card(hovering_card, true)

func highlight_card(card, hovered, scale_factor = 1.1):
	if hovered:
		card.scale = card.get_meta("base_scale", Vector2(1, 1)) * scale_factor
		card.z_index = 10
	else:
		card.scale = card.get_meta("base_scale", Vector2(1, 1))
		card.z_index = 0


func assign_card_to_slot(card: Control, slot: Control) -> void:
	release_card_slot(card)
	slot.card_in_slot = true
	slot.modulate = Color(1, 1, 1)
	card.set_meta("assigned_slot", slot)


func release_card_slot(card: Control) -> void:
	var assigned_slot = card.get_meta("assigned_slot", null)
	if assigned_slot != null and is_instance_valid(assigned_slot):
		assigned_slot.card_in_slot = false
		assigned_slot.modulate = Color(1, 1, 1)
	card.set_meta("assigned_slot", null)


func _on_card_tree_exiting(card: Control) -> void:
	release_card_slot(card)


func set_card_mouse_filter_recursive(node: Node, mouse_filter, children_filter: Control.MouseFilter) -> void:
	if node is Control and mouse_filter != null:
		node.mouse_filter = mouse_filter

	for child in node.get_children():
		if (child is Control):
			child.mouse_filter = children_filter
			set_card_mouse_filter_recursive(child, null, children_filter)

# endregion

func spawn_card(card_id: int, pos: Vector2):
	var data = CardDatabase.data.get(card_id)
	if data == null:
		print("Erreur : La carte ", card_id, " n'existe pas dans la DB")
		return

	var new_card = card_scene.instantiate()
	new_card.setup_with_data(data)
	new_card.global_position = pos
	add_child(new_card)
	
	connect_card_signals(new_card)
