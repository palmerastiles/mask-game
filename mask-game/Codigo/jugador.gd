extends CharacterBody2D

enum Estado { 
	Sacrificio,
	Ira,
	Burla,
	Dios 
}

var Actual = Estado.Sacrificio
var Desbloqueada = [Estado.Sacrificio]
var Rotacion = []
@onready var Animacion = $AnimatedSprite2D
@export var Ira_Desbloqueada = false
@export var Burla_Desbloqueada = false
@export var Dios_Desbloqueada = false

var SPEED = 300.0
var JUMP_VELOCITY = -600.0

#Tiempo de uso y cooldowns para las mascaras
@export var TIEMPO_MAX_USO = 5.0  # Tiempo de uso de mascara (igual pa toos)
@export var COOLDOWN_DURACION = 10.0

var tiempo_uso_restante = 0.0
var esta_usando_mascara = false #??

# Cooldowns independientes de mascaras
var cooldowns = {
	Estado.Sacrificio: 0.0,
	Estado.Ira: 0.0,
	Estado.Burla: 0.0,
	Estado.Dios: 0.0
}


func _ready() -> void:
	Update_Mascara_Desbloqueada()
	Update_Rotacion()
	if Rotacion.size() > 0:
		Actual = Rotacion[0]
		Equipar_Mascara(Actual)  # Corregido: llamar a la función

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Cambio_F"):
		ciclo_mascara(1)
	elif event.is_action_pressed("Cambio_B"): 
		ciclo_mascara(-1)

func ciclo_mascara(direccion: int):  # Corregido: agregar dos puntos y tipo
	if Rotacion.size() <= 1:
		return  # na
	
	var valor_actual = Rotacion.find(Actual)  # Corregido: usar guión bajo, no espacio
	
	if valor_actual == -1: #Si no encuentra na
		valor_actual = 0
	
	var nuevo_valor = (valor_actual + direccion) % Rotacion.size()  # Anillo
	if nuevo_valor < 0:
		nuevo_valor = Rotacion.size() - 1
	
	var Mascara_seleccionada = Rotacion[nuevo_valor]
	Equipar_Mascara(Mascara_seleccionada)  # Corregido: punto y coma separado

func Equipar_Mascara(Mascara: Estado):  # Corregido: tipo Estado
	"""
	Actual = Mascara
	print("Máscara equipada: ", Estado.keys()[Mascara])  # Corregido: sintaxis
	#Toca cambiarlo
	
	#Dado que rotacion se actualiza de desbloqueadas, nunca habra una mascara 
	sin desbloquear en el mismo
	
	# 1. Si la máscara está bloqueada, no hacer nada 
	if Mascara not in Desbloqueada:
		print("Acceso denegado: Máscara bloqueada.")
		return
	"""

	# Si la máscara tiene cooldown activo, no permitir cambio
	if cooldowns[Mascara] > 0:
		print("¡Mascara ", Estado.keys()[Mascara], " en cooldown! Faltan: ", snapped(cooldowns[Mascara], 0.1), "s")
		return

	# QUITAR mascara antes de terminar (entra en cooldown)
	# (Excepto la de Sacrificio)
	if Actual != Mascara and Actual != Estado.Sacrificio:
		print("Quitando ", Estado.keys()[Actual], ". Cooldown iniciado")
		cooldowns[Actual] = COOLDOWN_DURACION
	
	# 4. LÓGICA DE ENTRADA: Equipar la nueva
	if Mascara == Estado.Sacrificio: # Para que no le aparezca cooldown a sacrificio 
		print("Equipada: ", Estado.keys()[Mascara])
	else:
		print("Equipada: ", Estado.keys()[Mascara], " | Tiempo de uso: ", TIEMPO_MAX_USO, "s")
	Actual = Mascara
	tiempo_uso_restante = TIEMPO_MAX_USO # Reiniciamos el tiempo de uso global
	esta_usando_mascara = (Actual != Estado.Sacrificio) # Sacrificio no gasta tiempo
	


	# Aquí puedes añadir efectos específicos para cada máscara
	match Mascara:
		Estado.Sacrificio:
			Animacion.modulate = Color(1, 1, 1)  # Color normal
		
		Estado.Ira:
			Animacion.modulate = Color(1, 0.2, 0.2)  # Rojo
		Estado.Burla:
			Animacion.modulate = Color(0.2, 1, 0.2)  # Verde
			SPEED + 400
			
		Estado.Dios:
			Animacion.modulate = Color(1, 1, 0.2)  # Amarillo

func Update_Mascara_Desbloqueada():
	Desbloqueada = [Estado.Sacrificio]  # Siempre empieza con Sacrificio
	
	if Ira_Desbloqueada:
		Desbloqueada.append(Estado.Ira)
	if Burla_Desbloqueada:
		Desbloqueada.append(Estado.Burla)
	if Dios_Desbloqueada:
		Desbloqueada.append(Estado.Dios)

func Update_Rotacion():
	Rotacion = Desbloqueada.duplicate()
	# Opcional: si quieres que siempre empiece con Sacrificio, déjalo así
	# Si prefieres que el ciclo no incluya Sacrificio cuando hay otras:
	# if Rotacion.size() > 1:
	#     Rotacion.erase(Estado.Sacrificio)

func _physics_process(delta: float) -> void:
	# Tiempos para mascaras
	procesar_tiempos(delta)
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Salto
	if Input.is_action_just_pressed("Salto") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	

	# Movimiento horizontal
	var direction := Input.get_axis("Izquierda", "Derecha")
	if direction:
		velocity.x = direction * SPEED
		
		Animacion.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
	
	
		
	manejar_animaciones_suavizado()
		
	move_and_slide()

func manejar_animaciones_suavizado():
	var en_suelo = is_on_floor()
	var velocidad_y = velocity.y
	
	# Transición suave entre animaciones
	if not en_suelo:
		if velocidad_y < -50:  # Subiendo rápidamente
			if Animacion.animation != "Salto":
				Animacion.play("Salto")
		elif velocidad_y > 50:  # Cayendo rápidamente
			if Animacion.animation != "Caida":
				Animacion.play("Caida")
		else:  # En el aire pero con poca velocidad vertical
			if Animacion.animation != "Caida":
				Animacion.play("Caida")
	else:
		if abs(velocity.x) > 300:
			if Animacion.animation != "Correr":
				Animacion.play("Correr")
		else:
			if Animacion.animation != "Idle":
				Animacion.play("Idle")


#Funcion para tiempos de mascaras
func procesar_tiempos(delta: float):
	# Reducir todos los cooldowns
	for m in cooldowns:
		if cooldowns[m] > 0:
			cooldowns[m] -= delta
			if cooldowns[m] <= 0: #Cooldown acabado
				cooldowns[m] = 0
				print("Mascara ", Estado.keys()[m], " lista para usar de nuevo.")

	# Reducir tiempo actual
	if esta_usando_mascara:
		tiempo_uso_restante -= delta
		if tiempo_uso_restante <= 0:
			print("¡Tiempo agotado! Volviendo a Sacrificio.")
			Equipar_Mascara(Estado.Sacrificio) #Forzar sacrificio


# Función para desbloquear máscaras desde otros lugares del juego
func Desbloquear_Ira():
	Ira_Desbloqueada = true
	Update_Mascara_Desbloqueada()
	Update_Rotacion()
	print("Máscara Ira desbloqueada!")

func Desbloquear_Burla():
	Burla_Desbloqueada = true
	Update_Mascara_Desbloqueada()
	Update_Rotacion()
	print("Máscara Burla desbloqueada!")

func Desbloquear_Dios():
	Dios_Desbloqueada = true
	Update_Mascara_Desbloqueada()
	Update_Rotacion()
	print("Máscara Dios desbloqueada!")

# Método helper para obtener nombre actual
func Obtener_Mascara_Actual() -> String:
	return Estado.keys()[Actual]
