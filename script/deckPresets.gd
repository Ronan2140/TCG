extends OptionButton

signal preset_selected(index, new)
signal preset_saved(index)
signal preset_deleted(index)

@onready var saveButton = %SaveButton
@onready var deck_name_input = %DeckNameInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_selected.connect(_on_preset_selected)


func populate_presets(decks, name_to_select = null):
	clear()
	add_item("Nouveau Deck", -2)
	for i in range(decks.size()):
		if decks[i].name != "":
			add_item(decks[i].name, i)
		else:
			add_item("Deck " + str(i), i)
	# list les items
	for i in range(get_item_count()):
		print("Preset item ", i, ": ", get_item_text(i), " with ID: ", get_item_id(i))
	# call the selection changed to update the input field with the name of the first deck
	if not name_to_select and get_item_count() > 0:
		select(0)
		_on_preset_selected(0)
	elif name_to_select:
		for i in range(get_item_count()):
			if get_item_text(i) == name_to_select:
				select(i)
				_on_preset_selected(i)
				break

func _on_preset_selected(index):
	print("Preset sélectionné : ", get_item_id(index))
	emit_signal("preset_selected", get_item_id(index), get_item_id(index) == -2)
	# si item "Nouveau Deck" sélectionné, clear le champ de nom, sinon le remplir avec le nom du deck
	if get_item_id(index) == -2:
		deck_name_input.text = "Nouveau Deck"
	else:
		deck_name_input.text = PlayerData.decks[get_item_id(index)].name


func _on_save_button_pressed() -> void:
	var current_id = get_item_id(selected)
	var deck_name = deck_name_input.text
	
	preset_saved.emit(current_id, deck_name)


func _on_delete_button_pressed() -> void:
	var current_id = get_item_id(selected)
	preset_deleted.emit(current_id)

func is_new_deck_selected():
	return get_item_id(selected) == -2
