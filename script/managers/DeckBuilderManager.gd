extends Control

@onready var library = %CollectionGrid
@onready var current_deck = %DeckGrid
@onready var deck_presets = %DeckPresets
@onready var search = %SearchBar
@onready var error_dialog = %ErrorDialog
@onready var delete_dialog = %DeleteDialog
var new_deck: DeckData


func _ready():
	print("Deck Builder Manager ready. Setting up UI...")
	library.card_added_to_deck.connect(add_card_to_deck)
	deck_presets.preset_selected.connect(_on_preset_selected)
	deck_presets.preset_saved.connect(_on_deck_save_pressed)
	deck_presets.preset_deleted.connect(_on_delete_button_pressed)
	current_deck.card_removed_from_deck.connect(_on_delete_card_from_deck)
	library.populate_library(CardDatabase.data)

	#  get the first preset existing
	var decks = PlayerData.decks
	deck_presets.populate_presets(decks)


func add_card_to_deck(card_id):
	print("is new deck selected ? ", deck_presets.is_new_deck_selected(), " and selected index : ", PlayerData.selected_deck_index)
	if (deck_presets.is_new_deck_selected() and PlayerData.selected_deck_index == -2):
		# ajouter la carte a new deck mais pas au player data
		if new_deck == null:
			new_deck = DeckData._init_empty(-2, "Nouveau Deck")
		new_deck.add_card(card_id)
		current_deck.refresh_list(new_deck)
		return
	if PlayerData.add_card_to_selected_deck(card_id):
		current_deck.refresh_list()

func _on_preset_selected(index, new):
	new_deck = null
	if (new):
		new_deck = DeckData._init_empty(-2, "Nouveau Deck")
	print("Deck sélectionné : ", index, " (Nouveau : ", new, ")")
	PlayerData.selected_deck_index = index
	current_deck.refresh_list(new_deck)

func _on_deck_save_pressed(index, name):
	print("Saving deck with index: ", index, " and name: ", name)
	if index != -2 and index < PlayerData.decks.size():
		if (!PlayerData.name_available(name) and name != PlayerData.decks[index].name):
			# pop up d'erreur
			show_error("Un deck avec ce nom existe déjà ! Veuillez en choisir un autre.")
			return
		PlayerData.decks[index].name = name
		PlayerData.save_all_decks()
		deck_presets.populate_presets(PlayerData.decks, name)

	else:
		#  cas nouveau deck 
		if (!PlayerData.name_available(name) or name == "Nouveau Deck"):
			# pop up d'erreur
			show_error("Vous ne pouvez pas utiliser ce nom pour un nouveau deck." if name == "Nouveau Deck" else "Un deck avec ce nom existe déjà ! Veuillez en choisir un autre.")
			return
		new_deck.name = name
		new_deck.id = PlayerData.decks.size()
		PlayerData.decks.append(new_deck)
		PlayerData.save_all_decks()
		deck_presets.populate_presets(PlayerData.decks, name)


func _on_delete_button_pressed(index):
	print("Deleting deck with index: ", index)
	# ask for confirmation before deleting
	delete_dialog.confirmed.connect(func(): _delete_deck(index))
	delete_dialog.popup_centered()

func show_error(message: String):
	error_dialog.dialog_text = message
	error_dialog.popup_centered() # Affiche le pop-up au milieu de l'écran

func _delete_deck(index):
	if index != -2 and index < PlayerData.decks.size():
		PlayerData.decks.remove_at(index)
		PlayerData.save_all_decks()
		deck_presets.populate_presets(PlayerData.decks)
		# select nouveau deck (index = size)
		deck_presets.select(0)
		new_deck = DeckData._init_empty(-2, "Nouveau Deck")
		current_deck.refresh_list(new_deck)
	else:
		deck_presets.select(0)
		new_deck = DeckData._init_empty(-2, "Nouveau Deck")
		current_deck.refresh_list(new_deck)

func _on_delete_card_from_deck(card_instance, card_id):
	print("Removing card with 	ID ", card_id, " from selected deck with index ", PlayerData.selected_deck_index)
	if PlayerData.selected_deck_index == -2:
		if new_deck != null:
			new_deck.card_ids.erase(card_id)
			current_deck.refresh_list(new_deck)
	else:
		var current_selected_deck = PlayerData.decks[PlayerData.selected_deck_index]
		current_selected_deck.card_ids.erase(card_id)
		PlayerData.save_all_decks()
		current_deck.refresh_list()
