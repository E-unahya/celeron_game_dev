extends Area3D

class_name Enemy

@onready var animation_player = $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var weak_area : Area3D = $WeakArea
@onready var static_body_3d: StaticBody3D = $StaticBody3D

var home_pos : Vector3

## 派生として前に進む
enum EnemyType {
	WAIT,
	WALKING,
	FLYING,
	THROWING
}

## 敵キャラによって動きを分ける
@export var enemy_type : EnemyType = 0

## 敵によってジャンプの大きさをChange OK.
@export var bounce_power : float = 1.2

func _ready() -> void:
	home_pos = self.global_position
	match enemy_type:
		EnemyType.WAIT:
			animation_player.play("Dance")
		EnemyType.FLYING:
			animation_player.play("Flying")
		EnemyType.WALKING:
			animation_player.play("Walk")
		EnemyType.THROWING:
			animation_player.play("Weapon")


func _on_body_entered(body: Node3D) -> void:
	# プレイヤーは4ぬ
	if body is not Player:
		return
	if body.attack_now == false:
		animation_player.play("Bite_Front")
		body.die()


func _on_weak_area_body_entered(body: Node3D) -> void:
	# 前提としてプレイヤーしか侵入不可
	if not body.is_on_floor() :
		if Input.is_action_pressed("ui_accept"):
			body.bounce(bounce_power)
		else:
			body.bounce()
		animation_player.play("Death")

func _on_area_entered(area: Area3D) -> void:
	# もしスピンアタックまたはよその敵に当たったら
	if area.get_collision_layer_value(6) or area.get_collision_layer_value(2):
		be_blown_away(area)

func be_blown_away(attack_area : Area3D, object : Node3D = self):
	# 引数が多いし、このやり方だと重くなるような気がする。
	if object == self:
		object.collision_shape_3d.scale *= 3.0
	var tondeku = Vector3(global_position - attack_area.global_position).normalized() * 30.0
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(object, "global_position", tondeku + Vector3.UP * 5.0, 0.5)
	tween.tween_property(object, "rotation", Vector3.UP * 3000, 1.0)
	if object != self:
		return
	tween.tween_callback(animation_player.play.bind("Death"))

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	match anim_name:
		"Death":
			$CollisionShape3D.disabled = true
			$WeakArea/CollisionShape3D.disabled = true
			$StaticBody3D/CollisionShape3D.disabled = true


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Death":
			await get_tree().create_timer(0.5).timeout
			hide()


func all_free() -> void:
	set_process(false)
	set_physics_process(false)
	set_script(null)
