extends Particles2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var created_on = Time.get_ticks_msec()

func _process(delta):
	if Time.get_ticks_msec()-created_on > 3000:
		queue_free()
