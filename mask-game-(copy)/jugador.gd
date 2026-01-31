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

@export var Ira_Desbloqueada = false
@export var Burla_Desbloqueada = false
@export var Dios_Desbloqueada = false

var SPEED = 300.0
var JUMP_VELOCITY = -400.0
@onready var hurtbox = $Area2D

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
		return  # Corregido: indentación
	
	var valor_actual = Rotacion.find(Actual)  # Corregido: usar guión bajo, no espacio
	
	if valor_actual == -1:
		valor_actual = 0
	
	var nuevo_valor = (valor_actual + direccion) % Rotacion.size()  # Corregido: variable correcta
	if nuevo_valor < 0:
		nuevo_valor = Rotacion.size() - 1
	
	var Mascara_seleccionada = Rotacion[nuevo_valor]
	Equipar_Mascara(Mascara_seleccionada)  # Corregido: punto y coma separado

func Equipar_Mascara(Mascara: Estado):  # Corregido: tipo Estado
	if Mascara not in Desbloqueada:
		print("Máscara Bloqueada: ", Mascara)
		return
	
	Actual = Mascara
	print("Máscara equipada: ", Estado.keys()[Mascara])  # Corregido: sintaxis
	
	# Aquí puedes añadir efectos específicos para cada máscara
	match Mascara:
		Estado.Sacrificio:
			$Sprite2D.modulate = Color(1, 1, 1)  # Color normal
		Estado.Ira:
			$Sprite2D.modulate = Color(1, 0.2, 0.2)  # Rojo
		Estado.Burla:
			$Sprite2D.modulate = Color(0.2, 1, 0.2)  # Verde
		Estado.Dios:
			$Sprite2D.modulate = Color(1, 1, 0.2)  # Amarillo

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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

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
