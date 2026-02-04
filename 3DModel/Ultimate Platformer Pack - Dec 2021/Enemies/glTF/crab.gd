extends "res://3DModel/Ultimate Platformer Pack - Dec 2021/Enemies/glTF/enemy.gd"

var tween : Tween
var home_pos : Vector3

## 下に落ちるように
@onready var ray_cast_3d: RayCast3D = $RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	home_pos = global_position
	super._ready()

"""
func _process(delta: float) -> void:
	if ray_cast_3d.is_colliding():
		pass
"""

func start_patrol():
	if tween:
		return
	# ループ
	var target_pos : Vector3 = home_pos + home_pos.direction_to(global_position + transform.basis.z) * 10.0
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(self, "position", target_pos, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", home_pos, 5).set_trans(Tween.TRANS_SINE)

func stop():
	tween.stop()
