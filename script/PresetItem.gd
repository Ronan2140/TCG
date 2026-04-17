extends VBoxContainer

@onready var button = $PresetButton
@onready var number_label = $PresetButton/NumberLabel
@onready var name_label = $DeckNameLabel

# function to initialize the preset
func setup(index: int, deck_name: String, is_add_button: bool = false):
	if is_add_button:
		name_label.text = "Créer un deck"
		number_label.text = "+"
		#change size of text in button
		name_label.add_theme_font_size_override("font_size", 18)
	else:
		name_label.text = deck_name
		number_label.text = str(index + 1)

	# connect the signal
	button.pressed.connect(_on_button_pressed.bind(index, is_add_button))

func _on_button_pressed(index: int, is_add_button: bool):
	if is_add_button:
		# emit signal to parent to create new deck
		print("Create new deck")
	else:
		# emit signal to load deck index
		print("Load deck: ", index)