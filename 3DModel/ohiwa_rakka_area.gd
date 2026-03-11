extends Area3D

@onready var ohiwa: Ohiwa = $Ohiwa

@export var forward : Vector3 = Vector3.MODEL_FRONT
@onready var shadow_mesh: MeshInstance3D = $ShadowMesh

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		ohiwa.freeze = false
		ohiwa.forward = forward

func _physics_process(delta: float) -> void:
	if !ohiwa.freeze:
		shadow_mesh.position = ohiwa.position - Vector3.UP * 10
