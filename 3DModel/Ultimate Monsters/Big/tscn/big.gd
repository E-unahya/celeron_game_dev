extends "res://3DModel/Ultimate Platformer Pack - Dec 2021/Enemies/glTF/enemy.gd"

@onready var ball: MeshInstance3D = $ball
@onready var ball_collision: CollisionShape3D = $ball/Area3D/BallCollision

## 投げるボールがTOUTATU SURU JIKAN
@export var ball_arrival : float = 3.0

var ball_initial : Vector3
var weapon_request_id : int = 0

func _ready() -> void:
	ball.hide()
	ball_collision.disabled = true
	ball_initial = ball.position
	super._ready()


func throw_ballet() -> void:
	ball.show()
	ball_collision.disabled = false
	var tween = get_tree().create_tween()
	tween.tween_property(ball, "position", Vector3(0.0, 1.4, 12.0), ball_arrival).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_ball_throw_finished)


func _ball_throw_finished() -> void:
	ball.position = ball_initial
	ball.hide()
	ball_collision.disabled = true
	if collision_shape_3d.disabled:
		return
	animation_player.play("Weapon")


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	super._on_animation_player_animation_started(anim_name)
	if anim_name != "Weapon":
		return

	weapon_request_id += 1
	var current_request_id := weapon_request_id
	await get_tree().create_timer(animation_player.current_animation_length * 0.5).timeout
	if current_request_id != weapon_request_id:
		return
	if collision_shape_3d.disabled:
		return
	if animation_player.current_animation != "Weapon":
		return
	throw_ballet()


func _on_area_3d_buttobasare_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(6) or area.get_collision_layer_value(2):
		be_blown_away(area, ball)
