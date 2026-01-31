extends RigidBody2D

@export var speed := 120
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if player == null:
		return

	var direction = (player.global_position - global_position).normalized()
	linear_velocity = direction * speed
