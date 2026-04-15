extends Node2D


const COLLISION_MASK = 1
const COLLISION_MASK_SLOT = 2

var selected_card = null
var off_set_x = -1
var off_set_y = -1
var screen_size = Vector2(0, 0)
var hovering_card = null

func _input(event):
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			selected_card = _raycast_check_for_card()
			if selected_card:
				start_drag(selected_card)
		else:
			undrag_card()

func _raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK
	var res = space_state.intersect_point(parameters)
	# get center of the card
	
	if res.size() > 0:
		var card = highest_z_card(res)
		# var card_center = card.collider.get_parent().global_position
		# # get offset between mouse and card center
		# off_set_x = card_center.x - get_global_mouse_position().x
		# off_set_y = card_center.y - get_global_mouse_position().y
		print("Card selected: " + card.collider.get_parent().card_name)
		return card.collider.get_parent()
	return null

func _raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_SLOT
	var res = space_state.intersect_point(parameters)
	
	if res.size() > 0:
		var slot_res = highest_z_card(res)
		var slot_node = slot_res.collider.get_parent()
		# On affiche le nom du Node du slot, pas un 'card_name' inexistant
		print("Slot sélectionné : " + slot_node.name)
		return slot_node
	return null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if selected_card != null:
		var new_position = get_global_mouse_position() + Vector2(off_set_x, off_set_y)
		selected_card.global_position = new_position

	
func connect_card_signals(card):
	print("Connecting signals for card: " + card.card_name)
	card.set_meta("base_scale", card.scale)
	card.connect("hovered", _on_card_hovered)
	card.connect("unhovered", _on_card_unhovered)

func highest_z_card(cards):
	print("Cards under mouse: ", cards)
	var highest_card = null
	var highest_z = -1
	for card in cards:
		var collider = card.collider.get_parent()
		if collider != null and "z_index" in collider:
			if collider.z_index > highest_z:
				highest_z = collider.z_index
				highest_card = card
	return highest_card

# DEPLACEMENT DE CARTES

func start_drag(card):
	selected_card = card
	var card_center = card.global_position
	off_set_x = card_center.x - get_global_mouse_position().x
	off_set_y = card_center.y - get_global_mouse_position().y
	
	# Force maximum z_index while dragging to prevent overlap issues
	card.z_index = 100
	print("Card selected: " + card.card_name)
	highlight_card(card, true, 1.2) # Slightly larger when dragging

func undrag_card():
	if selected_card != null:
		var dropped_card = selected_card 
		
		highlight_card(dropped_card, true, 1.1)
		selected_card = null
		
		var card_under_mouse = _raycast_check_for_card()
		if card_under_mouse != null:
			_on_card_hovered(card_under_mouse)
			
		var card_slot_found = _raycast_check_for_card_slot()
		if card_slot_found and not card_slot_found.card_in_slot:
			dropped_card.global_position = card_slot_found.global_position
			
			card_slot_found.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
			card_slot_found.card_in_slot = true
			dropped_card.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)

func _on_card_hovered(card):
	# Ignore hover logic if a card is currently being dragged
	if selected_card != null and selected_card != card:
		return
		
	if (hovering_card == null):
		hovering_card = card
		print("Card hovered: " + card.card_name)
		highlight_card(card, true)

func _on_card_unhovered(card):
	# Ignore hover logic if a card is currently being dragged
	if selected_card != null:
		return
		
	print("Card unhovered: " + card.card_name)
	highlight_card(card, false)
	var new_hovering_card = _raycast_check_for_card()
	if new_hovering_card != null and new_hovering_card != card:
		hovering_card = new_hovering_card
		print("New card hovered: " + hovering_card.card_name)
		highlight_card(hovering_card, true)
	else:
		hovering_card = null

func highlight_card(card, hovered, scale_factor = 1.1):
	if hovered:
		card.scale = card.get_meta("base_scale", Vector2(1, 1)) * scale_factor
		card.z_index = 10 # High enough to be on top
	else:
		card.scale = card.get_meta("base_scale", Vector2(1, 1))
		card.z_index = 0
