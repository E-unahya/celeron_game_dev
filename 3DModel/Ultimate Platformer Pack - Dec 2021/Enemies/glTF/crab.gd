extends "res://3DModel/Ultimate Platformer Pack - Dec 2021/Enemies/glTF/enemy.gd"

var tween : Tween

# もし動くタイプの敵だった場合、Raycast3Dを使って床についてるかどうか判定したいのでRaycast3Dを何かしらのタイミングで取得したい。
## 下に落ちるように

@onready var ray_cast_3d: RayCast3D = $RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

"""
func _process(delta: float) -> void:
	if ray_cast_3d.is_colliding():
		self.position = ray_cast_3d.get_collision_point()
		print(ray_cast_3d.get_collision_point())
	else:
		self.position.y -= 0.98 * delta
"""

func start_patrol():
	if tween:
		return
	# ループ
	var target_pos : Vector3 = home_pos + home_pos.direction_to(global_position + transform.basis.z) * 10.0
	var armature : Node3D = self.get_child(0)
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(self, "position", target_pos, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(armature, "rotation_degrees", Vector3(0, -180, 0), 1.0)
	tween.tween_property(self, "position", home_pos, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(armature, "rotation_degrees", Vector3.ZERO, 1.0)

func stop():
	tween.stop()
