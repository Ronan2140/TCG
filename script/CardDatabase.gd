extends Node

var data = {} # Contiendra toutes tes cartes indexées par leur ID
var path = "res://Cartes/card_list.csv"

func _ready():
	load_data()

func load_data():
	if not FileAccess.file_exists(path):
		print("Erreur : Fichier CSV introuvable à : ", path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	
	# On récupère les entêtes (ex: id, name, atk...)
	var headers = file.get_csv_line()
	
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < headers.size(): continue # Saute les lignes mal formées ou vides
		
		var card_info = {}
		# On boucle sur les colonnes pour remplir le dictionnaire
		for i in range(headers.size()):
			var value = line[i]
			# Convertit en nombre si c'est possible, sinon garde le texte
			if value.is_valid_int():
				card_info[headers[i]] = value.to_int()
			else:
				card_info[headers[i]] = value
		
		var new_card = CardData.new(card_info)
		
		# 3. On stocke l'objet
		data[new_card.id] = new_card
	
	print("Base de données chargée : ", data.size(), " cartes trouvées.")


func get_card_data_by_id(card_id):
	if data.has(card_id):
		return data[card_id]
	else:
		print("Aucune carte trouvée avec l'ID : ", card_id)
		return null