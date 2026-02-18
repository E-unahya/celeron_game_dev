extends Node3D

class_name Box
## ノードの名前違う可能性があるため、get_childで取得
@onready var static_body : StaticBody3D = get_child(0).get_child(0)
@onready var area_3d: Area3D = $Area3D

signal breaked(_my_position:Vector3)

## 破壊された時のエフェクトを再生するためどうするか？
## 答えは簡単、親から取るのでシグナルを使う。

func _on_area_3d_body_entered(body: Node3D) -> void:
	if Input.is_action_pressed("ui_accept"):
		body.bounce(1.2)
	else:
		body.bounce()
	i_was_break()


func _on_area_3d_area_entered(area: Area3D) -> void:
	print(area.name)
	i_was_break()

func i_was_break() -> void:
	static_body.get_child(0).disabled = true
	area_3d.get_node("CollisionShape3D").disabled = true
	breaked.emit(global_position)
	hide()
