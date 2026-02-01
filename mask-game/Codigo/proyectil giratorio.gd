extends Node2D

class_name FireRingController

@export var fireball_scene: PackedScene
@export var number_of_fireballs: int = 4
@export var rotation_speed: float = 180.0  # Grados por segundo
@export var orbit_radius: float = 100.0
@export var expand_speed: float = 50.0
@export var max_radius: float = 200.0
@export var lifetime: float = 10.0

var fireballs: Array = []
var is_active: bool = true
var current_radius: float

# Definir el enum dentro de la clase
enum RingMode {
	STATIONARY = 0,      # Gira en su lugar
	FOLLOW_BOSS = 1,     # Sigue al jefe
	FOLLOW_PLAYER = 2,   # Sigue al jugador
	EXPANDING = 3        # Se expande
}

@export var mode: RingMode = RingMode.STATIONARY
var target: Node2D = null

func _ready():
	current_radius = orbit_radius
	spawn_fireball_ring()
	
	# Auto-destrucción después del tiempo de vida
	await get_tree().create_timer(lifetime).timeout
	destroy_ring()

func setup_ring(center_pos: Vector2, ring_mode: RingMode, ring_target: Node2D = null):
	global_position = center_pos
	mode = ring_mode
	target = ring_target

func spawn_fireball_ring():
	if not fireball_scene:
		push_error("No hay escena de fireball asignada!")
		return
	
	var angle_step = TAU / number_of_fireballs
	
	for i in range(number_of_fireballs):
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		
		# Configurar ángulo inicial
		var start_angle = angle_step * i
		
		# Configurar la bola de fuego
		if fireball.has_method("setup"):
			fireball.setup(global_position, start_angle, 
						  target if mode == RingMode.FOLLOW_PLAYER else null)
		
		if fireball.has_method("set_orbit_radius"):
			fireball.set_orbit_radius(current_radius)
		
		if fireball.has_method("set_rotation_speed"):
			fireball.set_rotation_speed(rotation_speed)
		
		if fireball.has_method("set_fire_effect"):
			fireball.set_fire_effect(1.0 + i * 0.1)  # Variación visual
		
		fireballs.append(fireball)

func _physics_process(delta):
	if not is_active:
		return
	
	# Seguir objetivo si es necesario
	if mode == RingMode.FOLLOW_PLAYER or mode == RingMode.FOLLOW_BOSS:
		if target and is_instance_valid(target):
			global_position = target.global_position
	
	# Expansión del aro
	if mode == RingMode.EXPANDING:
		current_radius += expand_speed * delta
		if current_radius > max_radius:
			current_radius = max_radius
		
		# Actualizar radio de todas las bolas
		for fireball in fireballs:
			if is_instance_valid(fireball) and fireball.has_method("set_orbit_radius"):
				fireball.set_orbit_radius(current_radius)
	
	# Actualizar posición de todas las bolas
	update_fireballs_position()

func update_fireballs_position():
	for fireball in fireballs:
		if is_instance_valid(fireball):
			if fireball.has_method("update_center"):
				fireball.update_center(global_position)

func destroy_ring():
	is_active = false
	for fireball in fireballs:
		if is_instance_valid(fireball):
			fireball.queue_free()
	fireballs.clear()
	queue_free()

# Métodos para modificar el aro en tiempo real
func change_target(new_target: Node2D):
	target = new_target
	if mode == RingMode.FOLLOW_PLAYER:
		mode = RingMode.FOLLOW_BOSS

func set_rotation_speed(new_speed: float):
	rotation_speed = new_speed
	for fireball in fireballs:
		if is_instance_valid(fireball) and fireball.has_method("set_rotation_speed"):
			fireball.set_rotation_speed(new_speed)

func set_orbit_radius(new_radius: float):
	orbit_radius = new_radius
	current_radius = new_radius
	for fireball in fireballs:
		if is_instance_valid(fireball) and fireball.has_method("set_orbit_radius"):
			fireball.set_orbit_radius(new_radius)

# Señal para notificar cuando el aro se destruye
signal ring_destroyed

func _exit_tree():
	ring_destroyed.emit()
