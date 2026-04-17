extends Control

# On définit le chemin vers la scène du Deck Builder
# Vérifie bien que le chemin correspond à ton dossier
var deck_builder_path = "res://scenes/DeckBuilder.tscn"

func _ready():
	# On connecte le signal du bouton. 
	# Assure-toi que le nom du nœud est exact (ex: $DeckButton)
	$MarginContainer/VBoxContainer/DeckBuilder.pressed.connect(_on_deck_builder_pressed)

func _on_deck_builder_pressed():
	# Cette ligne décharge le menu et charge le Deck Builder
	var error = get_tree().change_scene_to_file(deck_builder_path)
	
	if error != OK:
		print("Erreur : Impossible de charger la scène du Deck Builder. Vérifie le chemin !")
