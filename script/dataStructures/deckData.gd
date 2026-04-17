class_name DeckData
extends RefCounted

var id: int
var name: String
var card_ids: Array[int]


func _init(deck_id: int, dict: Dictionary):
	self.id = deck_id
	self.name = dict.get("name", "")
	var raw_ids = dict.get("card_ids", [])
	self.card_ids = [] as Array[int]
	for cid in raw_ids:
		self.card_ids.append(int(cid))

static func _init_empty(deck_id: int, deck_name: String):
	var deck = DeckData.new(deck_id, {})
	deck.name = deck_name
	deck.card_ids = [] as Array[int]
	return deck

func add_card(card_id: int):
	card_ids.append(card_id)


func _to_dict():
	var dict = {}
	dict["id"] = id
	dict["name"] = name
	dict["card_ids"] = card_ids
	return dict
