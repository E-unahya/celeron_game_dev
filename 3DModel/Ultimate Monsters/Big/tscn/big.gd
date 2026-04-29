extends "res://3DModel/Ultimate Platformer Pack - Dec 2021/Enemies/glTF/enemy.gd"

class_name Big
@onready var ball: MeshInstance3D = $ball
@onready var ball_collision: CollisionShape3D = $ball/Area3D/BallCollision

## 投げるボールがTOUTATU SURU JIKAN
@export var ball_arrival : float = 3.0

## 敵とプレイヤーの距離がここまで来たら動き出す。
@export var distance: float = 100.0

@export var target: Player
@export var speed : float = 5.0

enum State {
	CHASE,
	ATTACK
}

var state : State

var ball_initial : Vector3
var weapon_request_id : int = 0


func _ready() -> void:
	ball.hide()
	ball_collision.disabled = true
	ball_initial = Vector3(0.7, 1.6, 1.0)
	super._ready()
	if enemy_type == EnemyType.FOLLOWING or target == null:
		set_process(true)
		set_physics_process(true)
		state = State.CHASE
	else:
		set_process(false)
		set_physics_process(false)

func _process(delta: float) -> void:
	if enemy_type == EnemyType.FOLLOWING or target != null:
		var dist_sq = (global_position.distance_squared_to(target.global_position))
		if distance > dist_sq:
			if state == State.CHASE:
				animation_player.play("Walk")
			elif state == State.ATTACK:
				animation_player.play("Weapon")

			var direction = (target.global_position - global_position).normalized()
			# 方向が上下に荒ぶらないため
			direction.y = 0
			if global_position.distance_squared_to(target.global_position) > 1.1:
				global_translate(direction * speed * delta)
				var look_pos = target.global_position
				look_pos.y = global_position.y
				$CharacterArmature.look_at(look_pos, Vector3.UP)
				$CharacterArmature.rotate_y(PI)
			else:
				state = State.ATTACK
		else:
			animation_player.play("Idle")
			$CharacterArmature.rotation = Vector3.ZERO


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
	if enemy_type == EnemyType.FOLLOWING:
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
