extends Node2D

const card_scene = preload("res://prefab/Card.tscn")
var MAX_HAND_WIDTH = 0
var HAND_CENTER_X = 0
var HAND_Y_hidden = 0
var HAND_Y_shown = 0
@export var deck_zone: Control
@export var discard_zone: Control

var selected_card = null
var off_set_x = 0.0
var off_set_y = 0.0
var screen_size = Vector2.ZERO
var hovering_card = null
var current_hovered_slot = null
var deck_pos = Vector2(100, 100)
var hide_hand_delay_sec := 1
var hand_hide_timer: Timer = null
var is_hand_shown := false
var is_hovering_deck := false
var is_hovering_discard := false
var base_deck_y := 0.0
var base_discard_y := 0.0
var zone_hide_offset := 84
var base_deck_scale := Vector2.ONE
var base_discard_scale := Vector2.ONE
var deck_tween: Tween = null
var discard_tween: Tween = null
var zone_hover_scale := 1.08


# region _ready and _process
func _ready() -> void:
	screen_size = get_viewport_rect().size
	MAX_HAND_WIDTH = screen_size.x - 2 * GameConfig.CARD_SIZE.x - 40
	HAND_CENTER_X = screen_size.x / 2
	# Hidden and shown positions
	HAND_Y_hidden = screen_size.y
	HAND_Y_shown = screen_size.y - GameConfig.CARD_SIZE.y / 2 - 20

	hand_hide_timer = Timer.new()
	hand_hide_timer.one_shot = true
	hand_hide_timer.wait_time = hide_hand_delay_sec
	hand_hide_timer.timeout.connect(_on_hand_hide_timeout)
	add_child(hand_hide_timer)

	update_card_connections()
	
	if deck_zone != null:
		# Save default Y position and connect hover signals
		base_deck_y = deck_zone.position.y
		base_deck_scale = deck_zone.scale
		deck_zone.mouse_entered.connect(_on_deck_hovered)
		deck_zone.mouse_exited.connect(_on_deck_unhovered)
	else:
		push_warning("DeckZone introuvable, utilisation de la position par defaut pour le draw.")

	if discard_zone != null:
		print("DiscardZone trouvé, position: ", discard_zone.position, '\n')
		# Save default Y position and connect hover signals
		base_discard_y = discard_zone.position.y
		base_discard_scale = discard_zone.scale
		discard_zone.mouse_entered.connect(_on_discard_hovered)
		discard_zone.mouse_exited.connect(_on_discard_unhovered)
	else:
		push_warning("DiscardZone introuvable, utilisation de la position par defaut pour le draw.")
	
	# Load deck in PlayerData
	load_deck(PlayerData.decks[PlayerData.selected_deck_index])

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
	
	var prev_slot = card.get_meta("assigned_slot", null)
	card.set_meta("previous_slot", prev_slot)
	
	release_card_slot(card)
	
	set_card_mouse_filter_recursive(card, Control.MOUSE_FILTER_IGNORE, Control.MOUSE_FILTER_IGNORE)
	print("Mouse filter set to IGNORE for card: ", card.name)
	card.z_index = 100
	print("Card selected: ", card.name)
	highlight_card(card, true, 1.2)
	_update_hand_hide_state()


func undrag_card():
	var dropped_card = selected_card
	selected_card = null
	off_set_x = 0
	off_set_y = 0
	
	set_card_mouse_filter_recursive(dropped_card, Control.MOUSE_FILTER_STOP, Control.MOUSE_FILTER_PASS)
	highlight_card(dropped_card, false)
	
	if current_hovered_slot != null:
		snap_card_to_slot(dropped_card, current_hovered_slot)
		assign_card_to_slot(dropped_card, current_hovered_slot)
		
		dropped_card.set_meta("previous_slot", null)
		
		print("Carte déposée dans : ", current_hovered_slot.name)
		current_hovered_slot = null
		_update_hand_hide_state()
		return

	print("Carte relâchée hors d'un slot disponible.")
	
	# Check if the card was previously in a slot
	var prev_slot = dropped_card.get_meta("previous_slot", null)
	if prev_slot != null and is_instance_valid(prev_slot):
		print("Retour au slot precedent : ", prev_slot.name)
		snap_card_to_slot(dropped_card, prev_slot)
		assign_card_to_slot(dropped_card, prev_slot)
		dropped_card.set_meta("previous_slot", null)
	else:
		# If no previous slot was found it means the card came from the hand
		if not dropped_card in player_hand:
			player_hand.append(dropped_card)
		_organize_hand(HAND_Y_shown if is_hand_shown else HAND_Y_hidden)
		
	_update_hand_hide_state()
func _on_card_hovered(card):
	if selected_card != null and selected_card != card:
		return
		
	if hovering_card == null:
		hovering_card = card
		print("Card hovered: ", card.name)
		highlight_card(card, true)
	_update_hand_hide_state()


func _on_card_unhovered(card):
	if selected_card != null:
		return
		
	print("Card unhovered: ", card.name)
	if hovering_card == card:
		hovering_card = null
		
		var current_hover = get_viewport().gui_get_hovered_control()
		if current_hover != null and current_hover.has_signal("hovered") and current_hover != card:
			hovering_card = current_hover
			print("New card hovered: ", hovering_card.name)

			
			highlight_card(hovering_card, true)

	highlight_card(card, false)
	_update_hand_hide_state()

func highlight_card(card, hovered, scale_factor = 1.1):
	# Lock pivot offset exactly to the center to prevent visual shifting on scale
	card.pivot_offset = Vector2(60, 84)

	if card.has_meta("hover_tween"):
		var existing_tween = card.get_meta("hover_tween")
		if existing_tween and existing_tween.is_valid():
			existing_tween.kill()

	var target_scale = card.get_meta("base_scale", Vector2(1, 1))
	var target_modulate = Color(1, 1, 1, 1)

	if hovered:
		card.z_index = 10
		target_scale = card.get_meta("base_scale", Vector2(1, 1)) * scale_factor
		target_modulate = Color(1.12, 1.12, 1.12, 1)
	else:
		card.z_index = 0

	var hover_tween = card.create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(card, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(card, "modulate", target_modulate, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	card.set_meta("hover_tween", hover_tween)


func _update_hand_hide_state() -> void:
	if selected_card != null or hovering_card != null or is_hovering_deck or is_hovering_discard:
		_cancel_hand_hide_timer()
		if not is_hand_shown:
			show_hand()
		return

	_restart_hand_hide_timer()


func _restart_hand_hide_timer() -> void:
	if hand_hide_timer == null:
		return
	hand_hide_timer.stop()
	hand_hide_timer.start()


func _cancel_hand_hide_timer() -> void:
	if hand_hide_timer == null:
		return
	hand_hide_timer.stop()


func _on_hand_hide_timeout() -> void:
	if selected_card == null and hovering_card == null:
		hide_hand()


func assign_card_to_slot(card: Control, slot: Control) -> void:
	release_card_slot(card)
	slot.card_in_slot = true
	slot.modulate = Color(1, 1, 1)
	card.set_meta("assigned_slot", slot)
	if card in player_hand:
		player_hand.erase(card)
		_organize_hand(HAND_Y_shown if is_hand_shown else HAND_Y_hidden)


func snap_card_to_slot(card: Control, slot: Control) -> void:
	if card == null or slot == null:
		return

	card.pivot_offset = card.size / 2.0
	
	var target_pos = slot.global_position + (slot.size - card.size) / 2.0
	
	if card.has_meta("move_tween"):
		var old_tween = card.get_meta("move_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
			
	var tween = card.create_tween()
	card.set_meta("move_tween", tween)
	
	tween.tween_property(card, "position", target_pos, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	card.z_index = slot.z_index + 1


func release_card_slot(card: Control) -> void:
	var assigned_slot = null
	if card.has_meta("assigned_slot"):
		assigned_slot = card.get_meta("assigned_slot", null)
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
		return null

	var new_card = card_scene.instantiate()
	new_card.setup_with_data(data)
	new_card.global_position = pos
	add_child(new_card)
	
	connect_card_signals(new_card)
	return new_card


# region Drawing and Hand

var player_hand = []
var player_deck = []

func load_deck(deck_data: DeckData):
	print("Loading deck: ", deck_data)
	if deck_data == null or deck_data.card_ids.size() == 0:
		print("Erreur : Aucun deck sélectionné ou le deck est invalide.")
		player_deck = [16, 20, 16, 16, 17, 18, 18, 19, 20]
		return
	player_deck = deck_data.card_ids.duplicate()

func draw_card():
	var current_deck_pos = Vector2(100, 100)
	if deck_zone != null:
		current_deck_pos = deck_zone.global_position
	print("Position du deck pour le draw: ", current_deck_pos)

	if player_deck.is_empty():
		print("Plus de cartes !")
		return
		
	var card_id = player_deck.pop_front()
	var card_instance = spawn_card(card_id, current_deck_pos)
	
	if card_instance != null:
		player_hand.append(card_instance)
		_organize_hand(HAND_Y_shown if is_hand_shown else HAND_Y_hidden)
		# set metadata slot to null for the new card
		

func _organize_hand(card_y = HAND_Y_hidden):
	var count = player_hand.size()
	if count == 0: return

	var spacing = min(140, MAX_HAND_WIDTH / count)
	
	for i in range(count):
		var card = player_hand[i]
		
		# Skip tweening for the dragged card
		if card == selected_card:
			continue
		
		var target_x = HAND_CENTER_X + (i - (count - 1) / 2.0) * spacing
		var target_pos = Vector2(target_x, card_y)
		var final_dest = target_pos - Vector2(60, 84)
		
		# Kill the existing tween to prevent conflicts and floating point drift
		if card.has_meta("move_tween"):
			var old_tween = card.get_meta("move_tween")
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		
		# Create a new tween strictly bound to this card
		var tween = card.create_tween()
		card.set_meta("move_tween", tween)
		
		tween.tween_property(card, "position", final_dest, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

		card.z_index = i

		
func _on_deck_zone_gui_input(event: InputEvent) -> void:
	#  if left click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("Deck clicked, drawing a card.", player_deck)
		draw_card()

func _on_deck_hovered() -> void:
	is_hovering_deck = true
	_apply_zone_hover(deck_zone, true, base_deck_scale, deck_tween)
	_update_hand_hide_state()

func _on_deck_unhovered() -> void:
	is_hovering_deck = false
	_apply_zone_hover(deck_zone, false, base_deck_scale, deck_tween)
	_update_hand_hide_state()

func _on_discard_hovered() -> void:
	is_hovering_discard = true
	_apply_zone_hover(discard_zone, true, base_discard_scale, discard_tween)
	_update_hand_hide_state()

func _on_discard_unhovered() -> void:
	is_hovering_discard = false
	_apply_zone_hover(discard_zone, false, base_discard_scale, discard_tween)
	_update_hand_hide_state()

func _on_discard_zone_mouse_entered() -> void:
	_on_discard_hovered()

func _on_discard_zone_mouse_exited() -> void:
	_on_discard_unhovered()

func _apply_zone_hover(zone: Control, hovered: bool, base_scale: Vector2, tween: Tween) -> void:
	if zone == null:
		return

	if tween != null and tween.is_valid():
		tween.kill()

	zone.pivot_offset = zone.size / 2.0
	var target_scale = base_scale * zone_hover_scale if hovered else base_scale
	var target_modulate = Color(1.18, 1.18, 1.18, 1.0) if hovered else Color(1, 1, 1, 1)
	var zone_tween = zone.create_tween()
	zone_tween.set_parallel(true)
	zone_tween.tween_property(zone, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	zone_tween.tween_property(zone, "modulate", target_modulate, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	if zone == deck_zone:
		deck_tween = zone_tween
	elif zone == discard_zone:
		discard_tween = zone_tween
	_update_hand_hide_state()

func animate_zones(hide: bool) -> void:
	var tween = create_tween().set_parallel(true)
	
	if deck_zone != null:
		var target_y = base_deck_y + (zone_hide_offset if hide else 0.0)
		tween.tween_property(deck_zone, "position:y", target_y, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		
	if discard_zone != null:
		var target_y = base_discard_y + (zone_hide_offset if hide else 0.0)
		tween.tween_property(discard_zone, "position:y", target_y, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func hide_hand() -> void:
	is_hand_shown = false
	_organize_hand(HAND_Y_hidden)
	animate_zones(true)

func show_hand() -> void:
	is_hand_shown = true
	_organize_hand(HAND_Y_shown)
	animate_zones(false)


func _on_discard_zone_gui_input(event: InputEvent) -> void:
	#  if left click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("Discard zone clicked.")
