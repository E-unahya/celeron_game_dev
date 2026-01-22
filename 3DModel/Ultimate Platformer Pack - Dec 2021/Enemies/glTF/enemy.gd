extends Area3D
@onready var animation_player = $AnimationPlayer
## 派生として前に進む
enum EnemyType {
	WAIT,
	WALKING,
	FLYING
}

@export var enemy_type : EnemyType = 0

func _ready() -> void:
	match enemy_type:
		EnemyType.WAIT:
			animation_player.play("Dance")
		EnemyType.FLYING:
			animation_player.play("Flying")


func _on_body_entered(body: Node3D) -> void:
	# プレイヤーは4ぬ
	animation_player.play("Bite_Front")
	body.die()


func _on_weak_area_body_entered(body: Node3D) -> void:
	# 前提としてプレイヤーしか侵入不可
	if not body.is_on_floor():
		body.bounce()
		animation_player.play("Death")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Death":
			await get_tree().create_timer(0.5).timeout
			hide()
			$CollisionShape3D.disabled = true
			$WeakArea/CollisionShape3D.disabled = true
