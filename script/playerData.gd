extends Node

var decks = []
var selected_deck_index = 0

const SAVE_PATH = "user://player_decks.json"

func _ready():
	load_all_decks()


func save_multiple_items(items_list: Array):
	var data_to_serialize = []
	
	for item in items_list:
		print("Serializing item using _to_dict: ", item)
		if item.has_method("_to_dict"):
			data_to_serialize.append(item._to_dict())
		else:
			data_to_serialize.append(item)
			
	var json_string = JSON.stringify(data_to_serialize, "\t")
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(json_string)

	
func save_all_decks():
	save_multiple_items(decks)

func load_all_decks():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		# if file empty or not valid json, no deck
		if file.get_as_text() == "":
			decks = []
			return
		var json = JSON.parse_string(file.get_as_text())
		if json:
			for deck in json:
				decks.append(DeckData.new(deck["id"], deck))

func add_card_to_selected_deck(card_id):
	var current_deck = decks[selected_deck_index]
	if current_deck.card_ids.size() < 40:
		current_deck.card_ids.append(card_id)
		if (selected_deck_index != -2):
			save_all_decks()
		return true
	else:
		print("Deck complet ! Impossible d'ajouter la carte ", card_id)
		return false

func name_available(deck_name):
	for deck in decks:
		if deck.name == deck_name:
			return false
	return true
