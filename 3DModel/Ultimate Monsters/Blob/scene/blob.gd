extends Enemy

@onready var ray_cast_3d: RayCast3D = $RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	if ray_cast_3d.is_colliding():
		self.y -= 0.5
	else:
		self.y += 30.0 * delta
