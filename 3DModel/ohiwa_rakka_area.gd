extends Area3D

@onready var ohiwa : MeshInstance3D = $Ohiwa
@onready var animation_player :AnimationPlayer= $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var shadow_mesh : MeshInstance3D = $ShadowMesh

var ohiwa_start : bool = false
var target : Player

func _ready() -> void:
	animation_player.play("RESET")

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		animation_player.play("Ohiwa Go")	
		target = body


func _physics_process(delta: float) -> void:
	if ohiwa_start and target:
		var goto_position = Vector3(global_position.x, target.global_position.y * 5, target.global_position.z)
		ohiwa.global_position = ohiwa.global_position.lerp(goto_position, 0.003)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Ohiwa Go":
			ohiwa_start = true


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		target = null
		ohiwa.position = Vector3.ZERO
