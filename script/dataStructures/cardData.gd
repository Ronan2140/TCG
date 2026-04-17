class_name CardData
extends RefCounted

var id: int
var name: String
var category: String
var description: String
var type: String
var atk: int
var hp: int
var pm: int
var slots: int
var spec: String
var artwork: String

# Le constructeur : il prend le dictionnaire du CSV et remplit l'objet
func _init(dict: Dictionary):
	id = dict.get("ID", 0)
	name = dict.get("Nom carte", "Inconnu")
	category = dict.get("Categorie", "")
	description = dict.get("Effet/description", "")
	type = dict.get("Type", "")
	
	# Conversion sécurisée en entier (si la cellule est vide, on met 0)
	atk = int(dict.get("ATK", 0))
	hp = int(dict.get("PV", 0))
	pm = int(dict.get("PM", 0))
	slots = int(dict.get("Slots", 0))
	spec = dict.get("Spécifité", "")
	if spec != "":
		spec = "[" + spec.replace(", ", "][") + "]"
	else:
		spec = "[Normal]"
	var artwork_path = "res://Cartes/Cartes/" + dict.get("Nom carte", "placeholder") + ".png"
	# try loading

	if not FileAccess.file_exists(artwork_path):
		artwork_path = "res://Cartes/Cartes/placeholder.png"

	artwork = artwork_path
	
#  override de to_string pour un affichage facile
func _to_string() -> String:
	return "CardData(ID: %d, Name: %s, Categorie: %s, description: %s, Type: %s, ATK: %d, HP: %d, PM: %d, Slots: %d, Spécifité: %s)" % [id, name, category, description, type, atk, hp, pm, slots, spec]