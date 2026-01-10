extends Camera3D

@export var follow_target : CharacterBody3D
@export var offset: Vector3 = Vector3(0, 3, 8) # プレイヤーとの距離
@export var smooth_speed: float = 5.0 # 追従の滑らかさ

func _ready() -> void:
	if follow_target:
		global_position = follow_target.global_position + offset
		# rotation = Vector3(-15, 0, 0) # 少し上から見る角度に調整

func _process(delta: float) -> void:
	if follow_target:
		var target_position : Vector3 = follow_target.global_position + offset
		global_position = global_position.lerp(target_position, smooth_speed * delta)
