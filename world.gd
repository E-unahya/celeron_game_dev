extends Node3D

@onready var enemies : Node = get_node("Enemies")
@onready var attack_se : AudioStreamPlayer = get_node("AttackSE")
@onready var jump_bounce_se : AudioStreamPlayer = get_node("JumpBounceSE")
@onready var player : Player = get_node("Player")

var se_pitch_limit : int = 0

func _ready():
	# 敵がArea3Dになってること前提
	for e : Enemy in enemies.get_children():
		e.area_entered.connect(_on_enemy_area_entered)
		e.weak_area.body_entered.connect(_on_enemy_weak_area_entered)

func _physics_process(delta: float) -> void:
	if player.is_on_floor(): 
		jump_bounce_se.pitch_scale = 1.0

func _on_enemy_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(6) or area.get_collision_layer_value(2):
		attack_se.play()

func _on_enemy_weak_area_entered(body : CharacterBody3D) -> void:
	if body is Player:
		jump_bounce_se.play()
		if !body.is_on_floor() and se_pitch_limit < 18:
			jump_bounce_se.pitch_scale += 0.1
			se_pitch_limit += 1


func _on_rakka_area_area_entered(area: Area3D) -> void:
	if area is Enemy:
		area.position = area.home_pos
