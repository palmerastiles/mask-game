extends Area2D

@export var daño := 20
@export var duracion := 0.5

func _ready() -> void:
	$AnimationPlayer.play("Rayo")
	$Timer.start(duracion)
	
	# Conectar señal de cuerpo entrado
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemigo") and body.has_method("recibir_daño"):
		body.recibir_daño(daño)
		print("¡Enemigo alcanzado por rayo!")

func _on_timer_timeout() -> void:
	queue_free()
