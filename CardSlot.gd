extends Control

signal slot_hovered(slot_node)
signal slot_unhovered(slot_node)
var card_in_slot = false


func _on_mouse_entered() -> void:
	if not card_in_slot:
		print("Slot hovered")
		slot_hovered.emit(self )


func _on_mouse_exited() -> void:
	if not card_in_slot:
		print("Slot unhovered")
		slot_unhovered.emit(self )
