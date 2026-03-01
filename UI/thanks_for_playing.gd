extends Node3D


func _ready() -> void:
    $Character/AnimationPlayer.play("Wave")


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        get_tree().change_scene_to_file("uid://d2ldvpmxfxrty")
