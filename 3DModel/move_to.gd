extends AnimatableBody3D

class_name MoveTo

@onready var move_floor_animation: AnimationPlayer = get_node_or_null("MoveFloorAnimation")

var current_player: Player
var current_player_parent: Node

func _on_area_3d_body_entered(body: Node3D) -> void:
	if current_player != null:
		return
	if body is not Player:
		return
	if move_floor_animation == null:
		push_warning("MoveFloorAnimation not found.")
		return

	current_player = body
	current_player_parent = current_player.get_parent()
	current_player.velocity = Vector3.ZERO
	current_player.set_process(false)
	current_player.set_physics_process(false)
	current_player.reparent(self, true)
	move_floor_animation.play("MoveTo")


func _ready() -> void:
	if move_floor_animation:
		move_floor_animation.animation_finished.connect(_on_move_floor_animation_finished)


func _on_move_floor_animation_finished(anim_name: StringName) -> void:
	if anim_name != "MoveTo":
		return
	if current_player == null:
		return

	current_player.reparent(current_player_parent, true)
	current_player.velocity = Vector3.ZERO
	current_player.set_process(true)
	current_player.set_physics_process(true)
	current_player = null
	current_player_parent = null
