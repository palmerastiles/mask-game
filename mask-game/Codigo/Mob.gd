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
var daño = 10
var Atacando: bool = false
var daño_aplicado_en_este_ataque = false

# Variables de movimiento
var direccion: Vector2 = Vector2.RIGHT
var fuerzaRetroceso = 200
var jugador_ref = null  # Referencia al jugador (cercania)
var jugador_ref_atack_hit = null #Referencia al jugador (AttackHitbox)

@onready var player_detection_zone = $PlayerDetectionZone  # Necesitarás un Area2D como hijo
@onready var sprite = $AnimatedSprite2D # Asume que tienes un nodo Sprite2D

func _ready():
	# Iniciar el timer para cambiar dirección
	$DirectionTimer.start()
	$DirectionTimer.wait_time = choose_float([0.5, 1.0, 1.5])
	
	# Conectar señales si usas un Area2D para detección
	if player_detection_zone:
		player_detection_zone.body_entered.connect(_on_player_detection_zone_body_entered)
		player_detection_zone.body_exited.connect(_on_player_detection_zone_body_exited)

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
		sprite.play("correr")
		if direccion.x > 0:
			sprite.flip_h = false
			$AttackHitbox.scale.x = 1
		else:
			sprite.flip_h = true
			$AttackHitbox.scale.x = -1
		# Verificar si está lo suficientemente cerca para atacar


func realizar_ataque():
	velocity.x = 0
	print("Atacando?", Atacando)
	print("Daño",daño_aplicado_en_este_ataque)
	if not Atacando: # Usamos tu variable para saber si ya empezó la animación
		daño_aplicado_en_este_ataque = false
		sprite.play("ataque")
		Atacando = true
		# Esperamos a que la animación termine para volver a perseguir
		await sprite.animation_finished
		
		Atacando = false
		estado_actual = Estado.PERSEGUIR #probar bien

# SECUENCIA DE ATAQUE
# Señal que se activa cuando la animacion de ataque este completa.
func _on_animated_sprite_2d_frame_changed() -> void:
	if estado_actual == Estado.ATACAR and sprite.animation == "ataque": # tmb debe estar atacando
		
		var frame_de_impacto = 4 #Lanza completamente estirada
		
		#If para evitar que se efectue daño continuamente
		if sprite.frame == frame_de_impacto and not daño_aplicado_en_este_ataque: 
			print("ENTRO")
			verificar_impacto_actual()

func verificar_impacto_actual():
	# Comprobamos si el jugador sigue dentro de la hitbox de ataque
	var cuerpos_en_rango = $AttackHitbox.get_overlapping_bodies() 
	
	for cuerpo in cuerpos_en_rango:
		if cuerpo.is_in_group("player"):
			cuerpo.recibir_daño(daño)
			daño_aplicado_en_este_ataque = true # Evita doble daño en el mismo golpe
			print("¡El enemigo te ha golpeado en el frame ", sprite.frame, "!")

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
		jugador_ref_atack_hit = body
		estado_actual = Estado.ATACAR


func _on_player_detection_zone_body_exited(body: Node2D) -> void:
	if body == jugador_ref:
		jugador_ref = null
		estado_actual = Estado.DEAMBULANDO
		print("Jugador perdido")


func _on_player_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not muerto:
		jugador_ref = body
		estado_actual = Estado.PERSEGUIR
		print("¡Jugador detectado!")
