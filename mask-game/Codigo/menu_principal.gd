extends Control




func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/suelo.tscn")

func _on_opciones_pressed() -> void:
	pass # Replace with function body.

func _on_créditos_pressed() -> void:
	pass # Replace with function body.

func _on_salir_del_juego_pressed() -> void:
	get_tree().quit()
