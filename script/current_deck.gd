extends GridContainer


signal card_removed_from_deck(card_instance, card_id)

@onready var library = %CollectionGrid
var card_item_scene = preload("res://prefab/Card.tscn")

@export var columns_count: int = 4


func _ready():
	print("Deck Builder ready. Connecting signals...", library)


func get_sorted_card_ids(ids_to_sort: Array) -> Array:
	var temp_list = []
	for id in ids_to_sort:
		var data = CardDatabase.get_card_data_by_id(int(id))
		if data:
			temp_list.append({"id": int(id), "name": data.name})
	
	temp_list.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	
	return temp_list.map(func(item): return item.id)

	
func refresh_list(deckData: DeckData = null):
	var spacing = get_theme_constant("h_separation")
	var total_spacing = spacing * (columns_count - 1)
	var grid_width = max(get_rect().size.x, 100.0)
	var responsive_width = (grid_width - total_spacing) / columns_count
	var responsive_height = responsive_width * 1.4
	
	for child in get_children():
		child.queue_free()
	
	var ids_to_show = []
	
	if PlayerData.selected_deck_index == -2 and deckData:
		ids_to_show = deckData.card_ids
	elif PlayerData.selected_deck_index != -2:
		ids_to_show = PlayerData.decks[PlayerData.selected_deck_index].card_ids
		
	var sorted_ids = get_sorted_card_ids(ids_to_show)
	
	for id in sorted_ids:
		_create_card_slot(id, responsive_width, responsive_height)

func _create_card_slot(id, w, h):
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(w, h)
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(slot)
	
	var card_node = card_item_scene.instantiate()
	slot.add_child(card_node)
	
	var native_size = GameConfig.CARD_SIZE
	card_node.scale = Vector2(w / native_size.x, h / native_size.y)
	
	var card_data = CardDatabase.get_card_data_by_id(id)
	if card_data and card_node.has_method("setup_with_data"):
		card_node.setup_with_data(card_data)
		card_node.left_clicked.connect(_on_card_left_clicked.bind(id))
		card_node.right_clicked.connect(_on_card_right_clicked.bind(id))

func _on_card_left_clicked(card_instance, card_id):
	print("Carte ajoutée au deck : ", card_id)

func _on_card_right_clicked(card_instance, card_id):
	card_removed_from_deck.emit(card_instance, card_id)
