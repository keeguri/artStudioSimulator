extends RigidBody3D

@export var labels : Array[Label3D]

func _ready():
	var dimensions :Vector3 = get_meta("statue_dimensions", Vector3.ZERO)
	for label in labels:
		label.text = "{0}x{1}x{2}".format([int(dimensions.x),int(dimensions.y),int(dimensions.z)])