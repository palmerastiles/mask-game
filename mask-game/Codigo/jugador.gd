extends CharacterBody2D

enum Estado { 
	SACRIFICIO,
	IRA,
	BURLA,
	DIOS 
}

signal health_changed
signal mask_changed(mask_name: String)
signal mask_cooldown_updated(mask: Estado, cooldown: float)

const BASE_SPEED := 300.0
const BASE_JUMP_VELOCITY := -600.0
const BASE_DAMAGE := 10

@export var vida_maxima := 100
@export var tiempo_max_uso_mascara := 5.0
@export var cooldown_duracion := 10.0

var actual := Estado.SACRIFICIO
var desbloqueadas := [Estado.SACRIFICIO]
var rotacion := []
var vida_actual: int
var daño_actual = BASE_DAMAGE
var mult_daño_recibido := 1.0
var speed := BASE_SPEED
var jump_velocity := BASE_JUMP_VELOCITY
var ataque := false
var tiempo_uso_restante := 0.0
var esta_usando_mascara := false

var cooldowns := {
	Estado.SACRIFICIO: 0.0,
	Estado.IRA: 0.0,
	Estado.BURLA: 0.0,
	Estado.DIOS: 0.0
}

@onready var area_ataque: Area2D = $AreaAtaqueMelee
@onready var animacion := $AnimatedSprite2D
@onready var menu_muerte := $Camera2D/CanvasLayer/MenuMuerte
@onready var mascaras := {
	Estado.SACRIFICIO: null,
	Estado.IRA: $PjProtaMask1,
	Estado.BURLA: $Mask2,
	Estado.DIOS: $Mask3
}

func _ready() -> void:
	vida_actual = vida_maxima
	$HealthBar2D.initialize("health_changed", vida_actual)
	actualizar_mascaras_desbloqueadas()
	actualizar_rotacion()
	if rotacion.size() > 0:
		actual = rotacion[0]
		equipar_mascara(actual)
		actualizar_visibilidad_mascaras()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Cambio_F"):
		ciclo_mascara(1)
	elif event.is_action_pressed("Cambio_B"): 
		ciclo_mascara(-1)
	elif event.is_action_pressed("Ataque"):
		ataque = true

func ciclo_mascara(direccion: int) -> void:
	if rotacion.size() <= 1:
		return
	
	var indice_actual = rotacion.find(actual)
	if indice_actual == -1:
		indice_actual = 0
	
	var nuevo_indice = (indice_actual + direccion) % rotacion.size()
	if nuevo_indice < 0:
		nuevo_indice = rotacion.size() - 1
	
	var mascara_seleccionada = rotacion[nuevo_indice]
	equipar_mascara(mascara_seleccionada)

func equipar_mascara(mascara: Estado) -> void:
	if cooldowns[mascara] > 0:
		print("¡Mascara ", Estado.keys()[mascara], " en cooldown! Faltan: ", snapped(cooldowns[mascara], 0.1), "s")
		return

	# Quitar mascara anterior (excepto sacrificio)
	if actual != mascara and actual != Estado.SACRIFICIO:
		print("Quitando ", Estado.keys()[actual], ". Cooldown iniciado")
		cooldowns[actual] = cooldown_duracion
		mask_cooldown_updated.emit(actual, cooldown_duracion)
	
	# Resetear estadísticas
	resetear_estadisticas()
	
	# Aplicar efectos de la nueva máscara
	aplicar_efectos_mascara(mascara)
	
	# Actualizar estado
	actual = mascara
	tiempo_uso_restante = tiempo_max_uso_mascara
	esta_usando_mascara = (actual != Estado.SACRIFICIO)
	
	actualizar_visibilidad_mascaras()
	mask_changed.emit(Estado.keys()[actual])

func resetear_estadisticas() -> void:
	speed = BASE_SPEED
	jump_velocity = BASE_JUMP_VELOCITY
	daño_actual = BASE_DAMAGE
	mult_daño_recibido = 1.0
	scale = Vector2.ONE

func aplicar_efectos_mascara(mascara: Estado) -> void:
	match mascara:
		Estado.SACRIFICIO:
			mult_daño_recibido = 1.5
			print("MODO SACRIFICIO: Daño recibido x1.5")
		
		Estado.IRA:
			daño_actual = BASE_DAMAGE * 2.0
			print("MODO IRA: Daño de ataque x2")
		
		Estado.BURLA:
			speed = 600.0
			daño_actual = BASE_DAMAGE * 0.5
			print("MODO BURLA: Veloz pero débil")
		
		Estado.DIOS:
			mult_daño_recibido = 0.5
			speed = 150.0
			scale = Vector2(1.3, 1.3)
			print("MODO DIOS: Tanque lento")

func actualizar_visibilidad_mascaras() -> void:
	for estado in mascaras:
		var nodo = mascaras[estado]
		if nodo:
			nodo.visible = (estado == actual)

func rayo() -> void:
	if ataque and actual == Estado.BURLA:
		animacion.play("AtaqueBurla")
		print("Ataque de burla")

func recibir_daño(cantidad: int) -> void:
	var daño_final = int(cantidad * mult_daño_recibido)
	vida_actual -= daño_final
	health_changed.emit(vida_actual)
	print("Recibiste ", daño_final, " de daño. Vida restante: ", vida_actual)
	
	if actual == Estado.SACRIFICIO:
		reducir_cooldowns_por_sacrificio()
	
	if vida_actual <= 0:
		morir()

func reducir_cooldowns_por_sacrificio() -> void:
	for estado in cooldowns:
		if cooldowns[estado] > 0:
			cooldowns[estado] = max(0, cooldowns[estado] - 2.0)
	print("¡Sacrificio aceptado! Cooldowns reducidos.")

func morir() -> void:
	print("El jugador ha muerto.")
	menu_muerte.visible = true
	get_tree().paused = true

func actualizar_mascaras_desbloqueadas() -> void:
	desbloqueadas = [Estado.SACRIFICIO]
	# Estas variables deberían ser reemplazadas por un sistema de progreso
	if true:  # Ejemplo: condición para Ira
		desbloqueadas.append(Estado.IRA)
	if true:  # Ejemplo: condición para Burla
		desbloqueadas.append(Estado.BURLA)
	if true:  # Ejemplo: condición para Dios
		desbloqueadas.append(Estado.DIOS)

func actualizar_rotacion() -> void:
	rotacion = desbloqueadas.duplicate()

func _physics_process(delta: float) -> void:
	procesar_tiempos(delta)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("Salto") and is_on_floor():
		velocity.y = jump_velocity
	
	var direction := Input.get_axis("Izquierda", "Derecha")
	if direction:
		velocity.x = direction * speed
		animacion.flip_h = direction < 0
		actualizar_orientacion_hitbox(direction) #Actualizar
		for nodo in mascaras.values():
			if nodo:
				nodo.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	manejar_animaciones()
	move_and_slide()

func manejar_animaciones() -> void:
	var en_suelo = is_on_floor()
	var velocidad_y = velocity.y
	#print(ataque, actual)
	if ataque and actual == Estado.BURLA:
		if animacion.animation != "AtaqueBurla":
			animacion.play("AtaqueBurla")
			await animacion.animation_finished
			ataque = false
		return
	if ataque and actual == Estado.IRA:
		if animacion.animation != "AtaqueIra":
			animacion.play("AtaqueIra")
			await animacion.animation_finished
			ataque = false
		return
	
	if not en_suelo:
		if velocidad_y < -50:
			if animacion.animation != "Salto":
				animacion.play("Salto")
		elif velocidad_y > 50:
			if animacion.animation != "Caida":
				animacion.play("Caida")
	else:
		if abs(velocity.x) > 0:
			if animacion.animation != "Caminata":
				animacion.play("Caminata")
			animacion.speed_scale = 3.0 if (actual == Estado.BURLA and speed == 600) else 1.0
		else:
			if animacion.animation != "Idle":
				animacion.play("Idle")
			animacion.speed_scale = 1.0


func procesar_tiempos(delta: float) -> void:
	# Reducir cooldowns
	for estado in cooldowns:
		if cooldowns[estado] > 0:
			cooldowns[estado] -= delta
			if cooldowns[estado] <= 0:
				cooldowns[estado] = 0
				print("Máscara ", Estado.keys()[estado], " lista para usar de nuevo.")
	
	# Reducir tiempo de uso
	if esta_usando_mascara:
		tiempo_uso_restante -= delta
		if tiempo_uso_restante <= 0:
			print("¡Tiempo agotado! Volviendo a Sacrificio.")
			equipar_mascara(Estado.SACRIFICIO)

func obtener_mascara_actual() -> String:
	return Estado.keys()[actual]

func _on_retry_bttn_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_bttn_pressed() -> void:
	get_tree().paused = false
	print("Cambiando a Menú Principal")
	# get_tree().change_scene_to_file("res://escenas/menu.tscn")
# AL FINAL DEL SCRIPT DEL JUGADOR, después de _on_menu_bttn_pressed()

# --- Sistema de desbloqueo mejorado ---
func desbloquear_mascara(mascara: Estado) -> void:
	if mascara not in desbloqueadas:
		desbloqueadas.append(mascara)
		actualizar_rotacion()
		print("¡Máscara ", Estado.keys()[mascara], " desbloqueada!")

# Funciones específicas (snake_case - convención GDScript)
func desbloquear_ira() -> void:
	desbloquear_mascara(Estado.IRA)

func desbloquear_burla() -> void:
	desbloquear_mascara(Estado.BURLA)

func desbloquear_dios() -> void:
	desbloquear_mascara(Estado.DIOS)

# Funciones legacy (PascalCase - compatibilidad con código existente)
func Desbloquear_Ira() -> void:
	desbloquear_ira()

func Desbloquear_Burla() -> void:
	desbloquear_burla()

func Desbloquear_Dios() -> void:
	desbloquear_dios()



# --- LÓGICA DE COMBATE Y DAÑO ---

# Esta función se debe conectar a la señal "frame_changed" del AnimatedSprite2D


func _on_animated_sprite_2d_frame_changed() -> void:
	# Si no estamos atacando, no gastamos recursos calculando
	if not ataque and not animacion.animation.begins_with("Ataque"):
		return
	
	var frame_actual = animacion.frame
	var anim_nombre = animacion.animation
	
	# Definimos en qué frame golpea cada máscara
	# (Ajusta los números según tus sprites: el primer frame es 0)
	var frame_de_impacto = -1
	
	match anim_nombre:
		"AtaqueIra":
			frame_de_impacto = 3
		"AtaqueBurla":
			frame_de_impacto = 2  # Ejemplo: golpea rápido
		"AtaqueDios":
			frame_de_impacto = 3  # Ejemplo: golpea lento
	
	# Si estamos JUSTO en el frame del golpe, aplicamos el daño
	if frame_actual == frame_de_impacto:
		
		aplicar_daño_en_area()
		

func aplicar_daño_en_area() -> void:
	# Obtenemos todo lo que esté tocando el AreaAtaqueMelee en este momento
	var cuerpos = area_ataque.get_overlapping_bodies()
	
	for cuerpo in cuerpos:
		
		# 1. Ignoramos al propio jugador
		if cuerpo == self:
			continue
			
		# 2. Verificamos que sea un enemigo (debe tener el método recibir_daño)
		if cuerpo.has_method("recibir_dano"):
			print("Daño enviado")
			# Calculamos daño final (ya calculado en equipar_mascara)
			var daño_final = int(daño_actual)
			
			# Enviamos la "señal" llamando a la función del enemigo
			cuerpo.recibir_dano(daño_final)
			
			
			print("¡GOLPE! ", Estado.keys()[actual], " causó ", daño_final, " de daño a ", cuerpo.name)



func actualizar_orientacion_hitbox(direccion: float) -> void:
	# Si no existe la referencia, salimos para evitar errores
	if not area_ataque:
		return

	# Si la dirección es negativa (Izquierda), invertimos la escala
	if direccion < 0:
		area_ataque.scale.x = -0.165
	# Si la dirección es positiva (Derecha), la ponemos normal
	elif direccion > 0:
		area_ataque.scale.x = 0.165
