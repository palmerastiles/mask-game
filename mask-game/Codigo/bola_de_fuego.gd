extends Area2D

class_name FireballAnillo

@export var rotation_speed: float = 180.0
@export var orbit_radius: float = 100.0
@export var damage: int = 30
@export var lifetime: float = 10.0

var center: Vector2
var current_angle: float = 0.0
var is_rotating: bool = true
var follow_target: Node2D = null

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(center_position: Vector2, start_angle: float, target: Node2D = null):
	center = center_position
	current_angle = start_angle
	follow_target = target
	update_position()

func _physics_process(delta):
	if not is_rotating:
		return
	
	current_angle += deg_to_rad(rotation_speed) * delta
	
	if follow_target and is_instance_valid(follow_target):
		center = follow_target.global_position
	
	update_position()

func update_position():
	var offset = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	global_position = center + offset
	rotation = current_angle

func update_center(new_center: Vector2):
	center = new_center

func set_orbit_radius(new_radius: float):
	orbit_radius = new_radius

func set_rotation_speed(new_speed: float):
	rotation_speed = new_speed

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("recibir_daño"):
			body.recibir_daño(damage)
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		# No destruir inmediatamente

func set_fire_effect(scale_mod: float = 1.0):
	var sprite = $Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE * scale_mod
