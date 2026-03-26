extends Area3D

class_name Bouncer

func _ready() -> void:
	$AnimationPlayer.play("Bouncer_Idle")

func _on_body_entered(body: Node3D) -> void:
	$AnimationPlayer.play("Bouncer_Bounce")
	var bounce = 1.7
	if Input.is_action_pressed("ui_accept"):
		bounce = 2.0
	body.bounce(bounce)
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Bouncer_Idle")
