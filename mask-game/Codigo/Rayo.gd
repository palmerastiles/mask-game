# proyectil_burla.gd
extends Area2D

@export var velocidad = 500.0
@export var daño = 5
var direccion = Vector2.RIGHT

func _ready():
	# Autodestruirse después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	position += direccion * velocidad * delta

func lanzar(dir: Vector2, dmg: int):
	direccion = dir.normalized()
	daño = dmg
	# Girar sprite según dirección
	if dir.x < 0:
		$Area2D2/AnimatedSprite2D.flip_h = true


		queue_free()
