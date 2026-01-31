# UI_MaskHUD.gd
extends Control

@onready var player = get_node("../Player")
@onready var mask_icons = [
	$Mask1Icon,
	$Mask2Icon,
	$Mask3Icon
]
@onready var mask_labels = [
	$Mask1Label,
	$Mask2Label,
	$Mask3Label
]

func _process(delta):
	update_mask_display()

func update_mask_display():
	var masks = player.mask_rotation_order
	var current_mask = player.current_mask
	
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
