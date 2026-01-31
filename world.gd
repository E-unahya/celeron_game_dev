extends Node3D

@onready var enemies : Node = get_node("Enemies")
@onready var attack_se : AudioStreamPlayer = get_node("AttackSE")

func _ready():
    # 敵がArea3Dになってること前提
    for e : Enemy in enemies.get_children():
        e.area_entered.connect(_on_enemy_area_entered)

func _on_enemy_area_entered(area: Area3D) -> void:
    if area.get_collision_layer_value(6):
        attack_se.play()
    elif area.get_collision_layer_value(2):
        pass