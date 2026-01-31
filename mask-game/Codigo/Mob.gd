extends CharacterBody2D

#class_name enemigoRenacido

# Controla la velocidad base del enemigo
const VELOCIDAD_NORMAL = 30
const VELOCIDAD_PERSECUCION = 80
const DISTANCIA_DETECCION = 200  # Píxeles a los que detecta al jugador

# Variables para controlar el hp del enemigo

var vidaMaxima = 100
var vida = vidaMaxima
var vidaMinima = 0

# Estados del enemigo
enum Estado { DEAMBULANDO, PERSEGUIR, ATACAR, MUERTO }
var estado_actual = Estado.DEAMBULANDO

# Variables de daño y ataque
var muerto: bool = false
var recibeDaño: bool = false
var daño = 10
var realizandoDaño1: bool = false
var puede_atacar: bool = true

# Variables de movimiento
var direccion: Vector2 = Vector2.RIGHT
var fuerzaRetroceso = 200
var jugador_ref = null  # Referencia al jugador

@onready var player_detection_zone = $PlayerDetectionZone  # Necesitarás un Area2D como hijo
@onready var sprite = $Sprite2D  # Asume que tienes un nodo Sprite2D

func _ready():
	# Iniciar el timer para cambiar dirección
	$DirectionTimer.start()
	$DirectionTimer.wait_time = choose_float([0.5, 1.0, 1.5])
	
	# Conectar señales si usas un Area2D para detección
	if player_detection_zone:
		player_detection_zone.body_entered.connect(_on_player_detected)
		player_detection_zone.body_exited.connect(_on_player_lost)

func _physics_process(delta: float) -> void:
	if muerto:
		return
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	
	# Manejar estados
	match estado_actual:
		Estado.DEAMBULANDO:
			movimiento_deambulando()
		Estado.PERSEGUIR:
			perseguir_jugador()
		Estado.ATACAR:

			

			#PONER AQUI LA INICIALIZACION DE LA ANIMACION DE ATAQUE

			realizar_ataque()
	
	# Aplicar movimiento
	move_and_slide()
	
	# Actualizar dirección del sprite
	#actualizar_direccion_sprite()

func movimiento_deambulando():
	# Movimiento aleatorio
	velocity.x = direccion.x * VELOCIDAD_NORMAL
	if velocity.x > 1:
		$AnimatedSprite2D.play("caminata")

func perseguir_jugador():
	if jugador_ref and not muerto:
		# Calcular dirección hacia el jugador
		var direccion_hacia_jugador = (jugador_ref.global_position - global_position).normalized()
		
		# Mover hacia el jugador
		velocity.x = direccion_hacia_jugador.x * VELOCIDAD_PERSECUCION
		
		# Actualizar dirección para el sprite
		direccion.x = sign(direccion_hacia_jugador.x)
		
		# Verificar si está lo suficientemente cerca para atacar
		#Aqui habia if de distancia
		estado_actual = Estado.ATACAR



func realizar_ataque():
	# Detener movimiento para atacar
	velocity.x = 0
	
	# Aquí implementas la lógica de ataque
	if jugador_ref:
		print("Atacando al jugador!")
		# Dañar al jugador si está en rango
		#Aqui habia un if de distancia
		jugador_ref.recibir_daño(daño)
	# Después de atacar, volver a perseguir
	estado_actual = Estado.PERSEGUIR

func _on_player_detected(body):
	

func _on_player_lost(body):
	if body == jugador_ref:
		jugador_ref = null
		estado_actual = Estado.DEAMBULANDO
		print("Jugador perdido")

func _on_direction_timer_timeout():
	if estado_actual == Estado.DEAMBULANDO and not muerto:
		cambio_direccion_aleatoria()
		$DirectionTimer.wait_time = choose_float([0.5, 1.0, 1.5])
		$DirectionTimer.start()

func cambio_direccion_aleatoria():
	# Cambiar dirección aleatoriamente
	direccion.x = choose([-1, 1])
	
	# También puedes agregar pequeñas pausas
	if randf() < 0.3:  # 30% de probabilidad de detenerse brevemente
		velocity.x = 0
	else:
		velocity.x = direccion.x * VELOCIDAD_NORMAL

func actualizar_direccion_sprite():
	# Voltear sprite según dirección
	if direccion.x > 0:
		sprite.flip_h = false
	elif direccion.x < 0:
		sprite.flip_h = true

func recibir_daño(cantidad):
	if muerto:
		return
	
	vida -= cantidad
	print("Enemigo recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	# Efecto visual de daño
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if vida <= 0:
		morir()

func morir():
	muerto = true
	estado_actual = Estado.MUERTO
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)  # Desactivar colisión
	set_collision_mask_value(1, false)
	# Animación de muerte
	print("Enemigo muerto")
	# queue_free() después de animación si es necesario

func choose(array):
	array.shuffle()
	return array.front()

func choose_float(array):
	array.shuffle()
	return array.front()


func _on_attack_hitbox_body_entered(body: Node2D) -> void: #Establecer hitbox en un frame especifico de la animacion
	if body.is_in_group("player"):
		print("TETOQUE")
		body.recibir_daño(daño)


func _on_player_detection_zone_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
