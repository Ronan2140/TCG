extends Node

enum Phase {START_GAME, DRAW, PLAY, ENEMY_TURN, END_GAME}


var current_phase = Phase.START_GAME
var active_player = 1 # 1 pour le joueur, 2 pour l'adversaire (IA ou Multi)

# Stats de combat
var player_mana = 0
var opponent_mana = 0

func change_phase(new_phase: Phase):
	current_phase = new_phase
	print("Phase actuelle : ", Phase.keys()[new_phase])
	
	match current_phase:
		Phase.DRAW:
			_handle_draw_phase()
		Phase.PLAY:
			_handle_play_phase()

func setup_battlefield():
	# On récupère les 4 terrains du deck du joueur
	# Pour l'instant on peut juste dire qu'ils sont aux IDs 0, 1, 2, 3
	for i in range(4):
		# On demande au CardManager de spawner un terrain dans les slots prévus
		CardManager.spawn_terrain(i, slot_nodes[i])