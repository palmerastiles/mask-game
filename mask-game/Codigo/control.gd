# UI_MaskHUD.gd
extends CanvasLayer  # Cambia de Control a CanvasLayer

@onready var player = get_node("../Player")  # Ajusta la ruta según tu escena
@onready var mask_icons = [
	$PjProtaMask1,
	$Mask2,
	$Mask3
]
@onready var mask_labels = [
	$Mask1Label,
	$Mask2Label,
	$Mask3Label
]

func _ready():
	# Si el CanvasLayer está en la misma escena que el jugador
	player = get_parent().get_node("Player")  # Ajusta según tu estructura

func _process(_delta):
	update_mask_display()

func update_mask_display():
	if not player:
		return
	
	var masks = player.Rotacion  # Usar Rotacion en lugar de mask_rotation_order
	var current_mask = player.Actual  # Usar Actual en lugar de current_mask
	
	# Actualizar iconos
	for i in range(3):
		if i < masks.size():
			mask_icons[i].visible = true
			mask_labels[i].text = str(i + 1)
			
			# Resaltar máscara actual
			if masks[i] == current_mask:
				mask_icons[i].modulate = Color(1, 1, 1)
				mask_labels[i].modulate = Color(1, 1, 0)
			else:
				mask_icons[i].modulate = Color(0.5, 0.5, 0.5)
				mask_labels[i].modulate = Color(0.7, 0.7, 0.7)
		else:
			mask_icons[i].visible = false
			mask_labels[i].text = ""
