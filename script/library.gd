extends GridContainer
signal card_added_to_deck(card_id)


var card_item_scene = preload("res://scenes/Card.tscn")
@export var columns_count: int = 4

func populate_library(cards_to_show: Dictionary):
	for child in get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var spacing = get_theme_constant("h_separation")
	var total_spacing = spacing * (columns_count - 1)
	var grid_width = max(get_rect().size.x, 100.0)
	var responsive_width = (grid_width - total_spacing) / columns_count
	var responsive_height = responsive_width * 1.4 # Ratio 1.4
	
	for card_data in cards_to_show.values():
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(responsive_width, responsive_height)
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(slot)
		
		var card_node = card_item_scene.instantiate()
		slot.add_child(card_node)
		var native_size = Vector2(250, 350)
		card_node.scale = Vector2(responsive_width / native_size.x, responsive_height / native_size.y)
		
		if card_node.has_method("setup_with_data"):
			card_node.setup_with_data(card_data)
			card_node.left_clicked.connect(_on_card_left_clicked.bind(card_data.id))
			card_node.right_clicked.connect(_on_card_right_clicked.bind(card_data.id))
		else:
			print("Erreur : setup_with_data introuvable sur ", card_node.name)
			

func _ready():
	print("Library UI ready. Waiting for data to populate...")


func _on_card_left_clicked(_card_instance, card_id):
		card_added_to_deck.emit(card_id)

func _on_card_right_clicked(_card_instance, card_id):
	print("Right-clicked on card ID: ", card_id)
