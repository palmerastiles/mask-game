extends CharacterBody2D

class_name enemigoRenacido

#Controla la velocidad base del enemigo y la modifica si está el jugador cerca
const VELOCIDAD = 10
var velocidadPersiguiendo: bool

#Las variables para controlar el hp del enemigo
var vida = 10
var vidaMaxima = 10
var vidaMinima = 0


#Mecanicas cuando el enemigo está muerto,  
#sprite cuando recibe daño del jugador, el daño que realiza al jugador,
#sprite cuando realiza un ataque al jugador (varían según el ataque que haga el enemigo)
var muerto: bool = false
var recibeDaño: bool = false
var daño = 3
var realizandoDaño1: bool = false
#var realizandoDaño2: bool = false
#var realizandoDaño3: bool = false

# Configuracion para la dinamica de movimiento del enemigo direccion a la que se mueve
# La gravedad que tiene el enemigo
# Y la cantidad de movimiento que tendrá en caso de ser golpeado por un enemigo.
var direccion: Vector2
const gravity = 900
var fuerzaRetroceso = 200
var deambulando: bool = true #Controla si el enemigo sigue vivo y moviendose

func _process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
	movimiento(delta)
	
func movimiento(delta):
	if !muerto and !velocidadPersiguiendo:
		velocity += direccion * VELOCIDAD * delta
		deambulando = true
	else:
		velocity.x = 0

func cambio_direccion_por_tiempo():
	$DirectionTimer.wait_time = choose([0.5, 1.0, 1.5])
	if !velocidadPersiguiendo:
		direccion = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0
	
func choose(array):
	array.shuffle()
	return array.front()
