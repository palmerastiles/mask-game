extends CharacterBody2D

class_name EnemigoRenacido

# Constantes
const VELOCIDAD_NORMAL := 30.0
const VELOCIDAD_PERSECUCION := 80.0
const DISTANCIA_DETECCION := 200.0
const FRAME_IMPACTO_ATAQUE := 4
const DISTANCIA_ATAQUE := 150.0  # Distancia mínima para atacar
const DISTANCIA_PERSECUCION := 300.0  # Distancia máxima para perseguir

# Arrays
var direcciones_deambulacion = [Vector2.RIGHT, Vector2.LEFT]

# Estados
enum Estado { DEAMBULANDO, PERSEGUIR, ATACAR, MUERTO, PREPARAR_ATAQUE }

# Variables exportadas
@export var vida_maxima := 100
@export var daño_ataque := 10
@export var fuerza_retroceso := 200.0
@export var proyectil_scene: PackedScene  # Escena del proyectil
@export var cadencia_ataque := 2.0  # Segundos entre ataques
@export var velocidad_proyectil := 300.0

# Variables de estado
var estado_actual := Estado.DEAMBULANDO
var vida: int
var muerto := false
var atacando := false
var daño_aplicado_en_este_ataque := false
var puede_atacar := true
var tiempo_desde_ultimo_ataque := 0.0

# Referencias
var jugador_ref: Node2D = null
var direccion := Vector2.RIGHT

# Timer interno
var tiempo_restante_deambulacion: float = 0.0
var tiempo_maximo_deambulacion: float = 2.0

# Nodos
@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var player_detection_zone := $PlayerDetectionZone
@onready var attack_hitbox := $AttackHitbox
@onready var fire_point := $Marker2D # Punto de lanzamiento de proyectiles

func _ready() -> void:
	vida = vida_maxima
	inicializar_conexiones()
	reiniciar_timer_deambulacion()
	
	# Verificar que existe el punto de disparo
	if not fire_point:
		fire_point = Node2D.new()
		fire_point.name = "FirePoint"
		add_child(fire_point)
		fire_point.position = Vector2(50, 0)  # Posición por defecto

func inicializar_conexiones() -> void:
	if player_detection_zone:
		player_detection_zone.body_entered.connect(_on_player_detected)
		player_detection_zone.body_exited.connect(_on_player_lost)
	
	if sprite:
		sprite.animation_finished.connect(_on_animacion_finalizada)
		sprite.frame_changed.connect(_on_frame_cambiado)

func reiniciar_timer_deambulacion() -> void:
	# Elegir nueva dirección
	direccion = elegir_direccion_aleatoria()
	
	# Elegir tiempo aleatorio entre 0.5 y 2.0 segundos
	tiempo_maximo_deambulacion = randf_range(0.5, 2.0)
	tiempo_restante_deambulacion = tiempo_maximo_deambulacion

func elegir_direccion_aleatoria() -> Vector2:
	var direcciones = direcciones_deambulacion.duplicate()
	direcciones.shuffle()
	return direcciones[0]

func _physics_process(delta: float) -> void:
	if muerto:
		return
	
	# Actualizar temporizador de ataque
	if not puede_atacar:
		tiempo_desde_ultimo_ataque += delta
		if tiempo_desde_ultimo_ataque >= cadencia_ataque:
			puede_atacar = true
	
	aplicar_gravedad(delta)
	manejar_estado(delta)
	move_and_slide()
	actualizar_direccion_sprite()

func aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

func manejar_estado(delta: float) -> void:
	match estado_actual:
		Estado.DEAMBULANDO:
			movimiento_deambulando(delta)
		Estado.PERSEGUIR:
			perseguir_jugador(delta)
		Estado.PREPARAR_ATAQUE:
			preparar_ataque(delta)
		Estado.ATACAR:
			realizar_ataque_distancia()
		Estado.MUERTO:
			# Comportamiento de muerte
			pass

func movimiento_deambulando(delta: float) -> void:
	# Reducir el timer
	tiempo_restante_deambulacion -= delta
	
	# Si se acabó el tiempo, cambiar dirección
	if tiempo_restante_deambulacion <= 0:
		reiniciar_timer_deambulacion()
	
	# Mover en la dirección actual
	velocity.x = direccion.x * VELOCIDAD_NORMAL
	
	# Verificar si hay jugador cerca para perseguir
	if jugador_ref and puede_perseguir():
		estado_actual = Estado.PERSEGUIR
		return
	
	# Animación
	if abs(velocity.x) > 1.0:
		sprite.play("Idleboss")
	else:
		sprite.play("Idleboss")

func puede_perseguir() -> bool:
	if not jugador_ref:
		return false
	
	var distancia = global_position.distance_to(jugador_ref.global_position)
	return distancia <= DISTANCIA_PERSECUCION

func perseguir_jugador(delta: float) -> void:
	if not jugador_ref:
		estado_actual = Estado.DEAMBULANDO
		reiniciar_timer_deambulacion()
		return
	
	var distancia_al_jugador = global_position.distance_to(jugador_ref.global_position)
	
	# Si el jugador está muy lejos, dejar de perseguir
	if distancia_al_jugador > DISTANCIA_PERSECUCION:
		jugador_ref = null
		estado_actual = Estado.DEAMBULANDO
		reiniciar_timer_deambulacion()
		return
	
	# Si está en rango de ataque, preparar ataque
	if distancia_al_jugador <= DISTANCIA_ATAQUE and puede_atacar:
		estado_actual = Estado.PREPARAR_ATAQUE
		velocity.x = 0
		return
	
	# Seguir al jugador
	var direccion_hacia_jugador = (jugador_ref.global_position - global_position).normalized()
	velocity.x = direccion_hacia_jugador.x * VELOCIDAD_PERSECUCION
	
	# Actualizar orientación
	actualizar_orientacion(direccion_hacia_jugador.x)
	
	# Animación de persecución
	sprite.play("correr")

func preparar_ataque(delta: float) -> void:
	# Detenerse y preparar ataque
	velocity.x = 0
	
	# Mirar al jugador
	if jugador_ref:
		var direccion_hacia_jugador = (jugador_ref.global_position - global_position).normalized()
		actualizar_orientacion(direccion_hacia_jugador.x)
	
	# Animación de preparación
	sprite.play("preparar_ataque")
	
	# Después de un breve tiempo, atacar
	await get_tree().create_timer(0.5).timeout
	
	if estado_actual == Estado.PREPARAR_ATAQUE and jugador_ref:
		lanzar_proyectil()
		estado_actual = Estado.ATACAR

func lanzar_proyectil() -> void:
	if not proyectil_scene or not jugador_ref:
		print("ERROR: No hay proyectil o jugador")
		return
	
	# Crear el proyectil
	var proyectil = proyectil_scene.instantiate()
	get_parent().add_child(proyectil)
	
	# Posicionar en el punto de disparo
	proyectil.global_position = fire_point.global_position
	
	# DEBUG: Mostrar posiciones
	print("FirePoint position: ", fire_point.global_position)
	print("Jugador position: ", jugador_ref.global_position)
	
	# Calcular dirección NORMALIZADA hacia el jugador
	var direccion_ataque = (jugador_ref.global_position - fire_point.global_position).normalized()
	print("Dirección calculada: ", direccion_ataque)
	
	# Configurar el proyectil
	if proyectil.has_method("apuntar_al_jugador"):
		proyectil.apuntar_al_jugador(fire_point.global_position, jugador_ref)
		print("Usando apuntar_al_jugador()")
	
	elif proyectil.has_method("setup"):
		# Asegúrate de pasar la dirección, no el ángulo
		proyectil.setup(fire_point.global_position, direccion_ataque, jugador_ref)
		print("Usando setup() con dirección")
	
	elif proyectil.has_method("set_direccion"):
		proyectil.set_direccion(direccion_ataque)
		print("Usando set_direccion()")
	
	# Configurar velocidad y daño
	if proyectil.has_method("set_velocidad"):
		proyectil.set_velocidad(velocidad_proyectil)
	
	if proyectil.has_method("set_daño"):
		proyectil.set_daño(daño_ataque)
	
	# Animación
	sprite.play("ataque")
func realizar_ataque_distancia() -> void:
	# Esperar a que termine la animación de ataque
	if sprite.animation == "ataque" and sprite.is_playing():
		return
	
	# Después de atacar, verificar qué hacer
	if jugador_ref and puede_perseguir():
		estado_actual = Estado.PERSEGUIR
	else:
		estado_actual = Estado.DEAMBULANDO
		reiniciar_timer_deambulacion()

func _on_animacion_finalizada() -> void:
	match sprite.animation:
		"ataque":
			# Después del ataque, continuar
			if estado_actual == Estado.ATACAR:
				realizar_ataque_distancia()
		"preparar_ataque":
			# La preparación ya maneja el ataque, no hacer nada aquí
			pass

func _on_frame_cambiado() -> void:
	# Mantener para ataques cuerpo a cuerpo si los mantienes
	if estado_actual == Estado.ATACAR and sprite.animation == "ataque_cuerpo":
		if sprite.frame == FRAME_IMPACTO_ATAQUE and not daño_aplicado_en_este_ataque:
			procesar_impacto_cuerpo()

func procesar_impacto_cuerpo() -> void:
	for cuerpo in attack_hitbox.get_overlapping_bodies():
		if cuerpo.is_in_group("player") and cuerpo.has_method("recibir_daño"):
			cuerpo.recibir_daño(daño_ataque)
			daño_aplicado_en_este_ataque = true

func actualizar_orientacion(direccion_x: float) -> void:
	if direccion_x == 0:
		return
	
	sprite.flip_h = direccion_x > 0
	
	# Ajustar posición del fire_point según dirección
	if fire_point:
		fire_point.position.x = abs(fire_point.position.x) * (1 if direccion_x > 0 else -1)
	
	# Ajustar hitbox de ataque cuerpo a cuerpo
	if attack_hitbox:
		attack_hitbox.scale.x = -1 if direccion_x < 0 else 1

func actualizar_direccion_sprite() -> void:
	if estado_actual != Estado.DEAMBULANDO or velocity.x == 0:
		return
	
	sprite.flip_h = velocity.x > 0
	
	# Ajustar fire_point durante deambulación
	if fire_point:
		fire_point.position.x = abs(fire_point.position.x) * (1 if velocity.x > 0 else -1)

func recibir_daño(cantidad: int) -> void:
	if muerto:
		return
	
	vida -= cantidad
	print("Enemigo recibió ", cantidad, " de daño. Vida: ", vida)
	
	# Efecto visual de daño
	efecto_daño()
	
	# Interrumpir ataque si está atacando
	if estado_actual == Estado.PREPARAR_ATAQUE or estado_actual == Estado.ATACAR:
		estado_actual = Estado.PERSEGUIR
	
	if vida <= 0:
		morir()

func efecto_daño() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func morir() -> void:
	muerto = true
	estado_actual = Estado.MUERTO
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	sprite.play("muerte")
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	# Esto es para ataques cuerpo a cuerpo
	if body.is_in_group("player") and estado_actual == Estado.PERSEGUIR:
		# Cambiar a ataque cuerpo a cuerpo si está muy cerca
		estado_actual = Estado.ATACAR
		sprite.play("ataque_cuerpo")
		daño_aplicado_en_este_ataque = false

func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player") and not muerto:
		jugador_ref = body
		if puede_perseguir():
			estado_actual = Estado.PERSEGUIR
		print("¡Jugador detectado!")

func _on_player_lost(body: Node2D) -> void:
	if body == jugador_ref:
		jugador_ref = null
		estado_actual = Estado.DEAMBULANDO
		reiniciar_timer_deambulacion()
		print("Jugador perdido")
