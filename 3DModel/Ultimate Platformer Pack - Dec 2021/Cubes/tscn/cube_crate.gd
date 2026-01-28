extends Node3D

## ノードの名前違う可能性があるため、get_childで取得
@onready var static_body : StaticBody3D = get_child(0).get_child(0)

## 破壊された時のエフェクトを再生するためどうするか？