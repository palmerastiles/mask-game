extends CharacterBody2D

@export var fire_ring_scene: PackedScene
@export var player_path: NodePath

@export_category("Ataque de Aro de Fuego")
@export var ring_attack_cooldown: float = 5.0
@export var ring_lifetime: float = 8.0
@export var ring_rotation_speed: float = 180.0
@export var ring_orbit_radius: float = 100.0

@onready var player: Node2D
@onready var fire_point: Marker2D = $FirePoint
@onready var attack_timer = $AttackTimer
#@onready var anim_player: AnimationPlayer = $AnimationPlayer

enum AttackType {
	RING_STATIONARY,     # Aro estático en el aire
	RING_AROUND_BOSS,    # Aro que gira alrededor del jefe
	RING_CHASE_PLAYER,   # Aro que persigue al jugador
	RING_EXPANDING       # Aro que se expande
}

var can_attack: bool = true
var current_attack: AttackType = AttackType.RING_AROUND_BOSS

func _ready():
	# Obtener referencia al jugador
	if player_path:
		player = get_node(player_path)
	else:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	attack_timer.wait_time = ring_attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	start_attacks()

func start_attacks():
	attack_timer.start()

func _on_attack_timer_timeout():
	if can_attack and fire_ring_scene:
		perform_fire_ring_attack()

func perform_fire_ring_attack():
	# Animación de preparación
	#anim_player.play("attack_windup")
	#await anim_player.animation_finished
	
	match current_attack:
		AttackType.RING_STATIONARY:
			launch_stationary_ring()
		AttackType.RING_AROUND_BOSS:
			launch_boss_ring()
		AttackType.RING_CHASE_PLAYER:
			launch_chasing_ring()
		AttackType.RING_EXPANDING:
			launch_expanding_ring()
	
	# Animación de recuperación
	#anim_player.play("attack_recovery")

# ===== DIFERENTES TIPOS DE ATAQUE DE ARO =====

# Aro estático en una posición
func launch_stationary_ring():
	var target_pos = player.global_position if player else global_position
	spawn_fire_ring(target_pos, FireRingController.RingMode.STATIONARY)

# Aro que gira alrededor del jefe
func launch_boss_ring():
	spawn_fire_ring(global_position, FireRingController.RingMode.FOLLOW_BOSS, self)

# Aro que persigue al jugador
func launch_chasing_ring():
	if player:
		spawn_fire_ring(player.global_position, FireRingController.RingMode.FOLLOW_PLAYER, player)

# Aro que se expande desde el jefe
func launch_expanding_ring():
	spawn_fire_ring(global_position, FireRingController.RingMode.EXPANDING)

# ===== MÉTODO PRINCIPAL PARA CREAR AROS =====

func spawn_fire_ring(position: Vector2, mode: int, target: Node2D = null):
	if not fire_ring_scene:
		return
	
	var fire_ring = fire_ring_scene.instantiate()
	get_parent().add_child(fire_ring)
	
	# Configurar el aro
	fire_ring.global_position = position
	
	# Pasar parámetros específicos
	if fire_ring.has_method("setup_ring"):
		fire_ring.setup_ring(position, mode, target)
	
	# Ajustar parámetros según el modo
	match mode:
		FireRingController.RingMode.EXPANDING:
			fire_ring.expand_speed = 80.0
			fire_ring.max_radius = 300.0
		FireRingController.RingMode.FOLLOW_PLAYER:
			fire_ring.rotation_speed = 220.0
	
	# Efecto de sonido
	play_fire_ring_sound()

# ===== CONTROL DE ATAQUES =====

func stop_attacks():
	can_attack = false
	attack_timer.stop()

func resume_attacks():
	can_attack = true
	attack_timer.start()

func cycle_attack_pattern():
	# Cambiar entre diferentes tipos de ataque
	current_attack = (current_attack + 1) % AttackType.size()
	print("Cambiando a patrón de ataque: ", current_attack)

# ===== EFECTOS Y SONIDOS =====

func play_fire_ring_sound():
	var sound = $FireRingSound
	if sound:
		sound.pitch_scale = randf_range(0.9, 1.1)
		sound.play()

# ===== INTEGRACIÓN CON PLATAFORMAS 2D =====

func _physics_process(delta):
	# Movimiento básico del jefe (opcional)
	handle_movement(delta)
	
	# Seguimiento del jugador
	if player and is_instance_valid(player):
		look_at_player()

func look_at_player():
	var direction = player.global_position - global_position
	if direction.x > 0:
		$Sprite2D.flip_h = false
	else:
		$Sprite2D.flip_h = true

func handle_movement(delta):
	# Ejemplo: Movimiento entre plataformas
	velocity.y += 980 * delta  # Gravedad
	
	var move_direction = 0
	if player and is_instance_valid(player):
		var distance = player.global_position.x - global_position.x
		if abs(distance) > 100:  # Mantener distancia
			move_direction = sign(distance)
	
	velocity.x = move_direction * 100
	move_and_slide()

# ===== VIDA Y DAÑO =====
@export var health: int = 100

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		defeat()

func defeat():
	stop_attacks()
	#anim_player.play("death")
	#await anim_player.animation_finished
	queue_free()
