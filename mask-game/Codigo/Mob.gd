extends CharacterBody2D



# Constantes
const VELOCIDAD_NORMAL := 30.0
const VELOCIDAD_PERSECUCION := 80.0
const DISTANCIA_DETECCION := 200.0
const FRAME_IMPACTO_ATAQUE := 4

# Arrays separados para direcciones y tiempos
var direcciones_deambulacion = [Vector2.RIGHT, Vector2.LEFT]
var tiempos_deambulacion = [0.5, 1.0, 1.5]  # Cambiado a variable, no constante

# Estados
enum Estado { DEAMBULANDO, PERSEGUIR, ATACAR, MUERTO }

# Variables exportadas para fácil ajuste
@export var vida_maxima := 100
@export var dano_ataque := 10
@export var fuerza_retroceso := 200.0

# Variables de estado
var estado_actual := Estado.DEAMBULANDO
var vida: int
var muerto := false
var atacando := false
var dano_aplicado_en_este_ataque := false


# Referencias
var jugador_ref: Node2D = null
var direccion := Vector2.RIGHT
var jugador_ref_atack_hit = null 

# Nodos
@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var player_detection_zone := $PlayerDetectionZone
@onready var attack_hitbox := $AttackHitbox
@onready var direction_timer := $DirectionTimer

func _ready() -> void:
	vida = vida_maxima
	inicializar_conexiones()
	iniciar_timer_deambulacion()

func inicializar_conexiones() -> void:
	if player_detection_zone:
		player_detection_zone.body_entered.connect(_on_player_detected)
		player_detection_zone.body_exited.connect(_on_player_lost)
	
	if sprite:
		sprite.animation_finished.connect(_on_animacion_finalizada)
		sprite.frame_changed.connect(_on_frame_cambiado)

func iniciar_timer_deambulacion() -> void:
	# 1. Elegir dirección inicial
	direccion = elegir_direccion_aleatoria()
	
	# 2. Elegir tiempo aleatorio (IMPORTANTE: usar el array de tiempos)
	var tiempo_aleatorio = elegir_tiempo_aleatorio()
	
	if direction_timer:
		# Verificar que el tiempo sea válido
		if tiempo_aleatorio <= 0:
			print("ADVERTENCIA: Tiempo inválido (<= 0). Usando valor por defecto.")
			tiempo_aleatorio = 1.0
		
		direction_timer.wait_time = tiempo_aleatorio
		direction_timer.start()

func elegir_direccion_aleatoria() -> Vector2:
	# Método con shuffle para direcciones
	var direcciones = direcciones_deambulacion.duplicate()
	direcciones.shuffle()
	return direcciones[0]

func elegir_tiempo_aleatorio() -> float:
	# Método con shuffle para tiempos
	var tiempos = tiempos_deambulacion.duplicate()
	tiempos.shuffle()
	return tiempos[0]
	
	# Alternativa más simple (sin shuffle):
	# return tiempos_deambulacion[randi() % tiempos_deambulacion.size()]

func _physics_process(delta: float) -> void:
	if muerto:
		return
	
	aplicar_gravedad(delta)
	manejar_estado()
	move_and_slide()
	actualizar_direccion_sprite()

func aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

func manejar_estado() -> void:
	match estado_actual:
		Estado.DEAMBULANDO:
			movimiento_deambulando()
		Estado.PERSEGUIR:
			perseguir_jugador()
		Estado.ATACAR:
			realizar_ataque()
		Estado.MUERTO:
			# Comportamiento de muerte
			pass

func movimiento_deambulando() -> void:
	velocity.x = direccion.x * VELOCIDAD_NORMAL
	if abs(velocity.x) > 1.0:
		sprite.play("caminata")

func perseguir_jugador() -> void:
	if not jugador_ref:
		estado_actual = Estado.DEAMBULANDO
		return
	
	var direccion_hacia_jugador = (jugador_ref.global_position - global_position).normalized()
	velocity.x = direccion_hacia_jugador.x * VELOCIDAD_PERSECUCION
	
	sprite.play("correr")
	actualizar_orientacion(direccion_hacia_jugador.x)

func realizar_ataque() -> void:
	velocity.x = 0
	
	if not atacando:
		iniciar_ataque()

func iniciar_ataque() -> void:
	dano_aplicado_en_este_ataque = false
	sprite.play("ataque")
	atacando = true
	# Esperamos a que la animación termine para volver a perseguir
	await sprite.animation_finished
		
	atacando = false
	if jugador_ref_atack_hit != null:
		estado_actual = Estado.ATACAR
	elif jugador_ref != null:
		estado_actual = Estado.PERSEGUIR
	else:
		estado_actual = Estado.DEAMBULANDO
	
func finalizar_ataque() -> void:
	atacando = false
	
	if jugador_ref:
		estado_actual = Estado.PERSEGUIR
	else:
		estado_actual = Estado.DEAMBULANDO

func _on_animacion_finalizada() -> void:
	if sprite.animation == "ataque":
		finalizar_ataque()

func _on_frame_cambiado() -> void:
	if estado_actual != Estado.ATACAR or sprite.animation != "ataque":
		return
	
	if sprite.frame == FRAME_IMPACTO_ATAQUE and not dano_aplicado_en_este_ataque:
		procesar_impacto()

func procesar_impacto() -> void:
	for cuerpo in attack_hitbox.get_overlapping_bodies():
		if cuerpo.is_in_group("player"):
			cuerpo.recibir_daño(dano_ataque)
			dano_aplicado_en_este_ataque = true
			print("¡Golpe conectado en frame ", sprite.frame, "!")

func actualizar_orientacion(direccion_x: float) -> void:
	if direccion_x == 0:
		return
	
	sprite.flip_h = direccion_x < 0
	attack_hitbox.scale.x = -1 if direccion_x < 0 else 1

func actualizar_direccion_sprite() -> void:
	if estado_actual != Estado.DEAMBULANDO or velocity.x == 0:
		return
	
	sprite.flip_h = velocity.x < 0

func _on_direction_timer_timeout() -> void:
	if estado_actual != Estado.DEAMBULANDO or muerto:
		return
	
	cambiar_direccion_aleatoria()
	
	# Elegir nuevo tiempo (usar elegir_tiempo_aleatorio, no elegir_direccion_aleatoria)
	var nuevo_tiempo = elegir_tiempo_aleatorio()
	if nuevo_tiempo <= 0:
		nuevo_tiempo = 1.0
	
	direction_timer.wait_time = nuevo_tiempo
	direction_timer.start()

func cambiar_direccion_aleatoria() -> void:
	direccion.x = elegir_direccion_aleatoria().x
	
	if randf() < 0.3:  # 30% de probabilidad de detenerse
		velocity.x = 0
	else:
		velocity.x = direccion.x * VELOCIDAD_NORMAL

func recibir_dano(cantidad: int) -> void:
	if muerto:
		return
	
	vida -= cantidad
	print("Enemigo recibió ", cantidad, " de daño. Vida: ", vida)
	
	# Efecto visual de daño
	efecto_dano()
	
	if vida <= 0:
		morir()

func efecto_dano() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func morir() -> void:
	muerto = true
	estado_actual = Estado.MUERTO
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	print("Enemigo eliminado")
	queue_free()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_ref_atack_hit = body
		estado_actual = Estado.ATACAR

func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player") and not muerto:
		jugador_ref = body
		estado_actual = Estado.PERSEGUIR
		print("¡Jugador detectado!")

func _on_player_lost(body: Node2D) -> void:
	if body == jugador_ref:
		jugador_ref = null
		estado_actual = Estado.DEAMBULANDO
		print("Jugador perdido")
