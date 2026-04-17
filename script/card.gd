@tool
extends Control

signal left_clicked(card_node)
signal right_clicked(card_node)

@export_group("Card Identity")
@export var card_name: String = "Nom de la carte":
	set(value):
		card_name = value
		if is_node_ready():
			update_card_visuals()

@export var description: String = "Description des effets...":
	set(value):
		description = value
		if is_node_ready():
			update_card_visuals()

@export var spec: String = "Spécifité...":
	set(value):
		spec = value
		if is_node_ready():
			update_card_visuals()

@export_group("Visuals")
@export var artwork: Texture2D:
	set(value):
		artwork = value
		if is_node_ready():
			update_card_visuals()

@export_group("Stats")
@export var atk_value: int = 0:
	set(value):
		atk_value = value
		if is_node_ready():
			update_card_visuals()

@export var atk_icon: Texture2D:
	set(value):
		atk_icon = value
		if is_node_ready():
			update_card_visuals()

@export var hp_value: int = 0:
	set(value):
		hp_value = value
		if is_node_ready():
			update_card_visuals()

@export var pm_value: int = 0:
	set(value):
		pm_value = value
		if is_node_ready():
			update_card_visuals()

@export var slots_value: int = 0:
	set(value):
		slots_value = value
		if is_node_ready():
			update_card_visuals()


@onready var name_label = $UI/Titre
@onready var desc_label = $UI/Description
@onready var specifity_label = $UI/Spec
@onready var art_sprite = $Illustration_rounded/Illustration
@onready var atk_label = $UI/ATK
@onready var atk_icon_sprite = $UI/ATTACK_ICON
@onready var pm_label = $UI/PM
@onready var slots_label = $UI/SLOTS
@onready var hp_label = $UI/PV

signal hovered
signal unhovered


func _ready():
	update_card_visuals()
	# Execute the manager logic only if the game is actually running, not in the editor
	if not Engine.is_editor_hint():
		var manager = get_tree().get_root().find_child("CardManager", true, false)
		if manager:
			manager.connect_card_signals(self )


func update_card_visuals():
	if name_label: name_label.text = card_name
	if desc_label: desc_label.text = description
	if art_sprite: art_sprite.texture = artwork
	if atk_label: atk_label.text = str(atk_value)
	if atk_icon_sprite: atk_icon_sprite.texture = atk_icon
	if pm_label: pm_label.text = str(pm_value)
	if slots_label: slots_label.text = str(slots_value)
	if specifity_label: specifity_label.text = spec
	if hp_label:
		if hp_value > 0:
			hp_label.text = str(hp_value)
		else:
			hp_label.text = ""


func setup_with_data(data: CardData):
	# On met à jour les variables exportées du script
	card_name = data.name
	description = data.description
	atk_value = data.atk
	hp_value = data.hp
	pm_value = data.pm
	slots_value = data.slots
	spec = data.spec
	# Pour l'image, on la charge dynamiquement si le chemin existe
	# (data.artwork contient le chemin res:// défini dans ton CSV)
	if data.artwork != "":
		artwork = load(data.artwork)
	
	# On force la mise à jour visuelle (Labels, Sprites)
	update_card_visuals()

	
func _on_area_2d_mouse_exited() -> void:
	emit_signal("unhovered", self )

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self )


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				accept_event()
				left_clicked.emit(self )
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				accept_event()
				right_clicked.emit(self )