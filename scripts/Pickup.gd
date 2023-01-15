extends Area2D


export var pickup_name = "pickup"

func _ready():
	animate()
	
func animate():
	$Tween.interpolate_property(self, "scale", scale, Vector2(scale.x-0.1, scale.y-0.1), 1)
	$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, -3, 1)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.interpolate_property(self, "scale", scale, Vector2(scale.x+0.1, scale.y+0.1), 1)
	$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, 5, 1)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	animate()
