extends Camera2D

# Declare a Timer node to control the shake effect
onready var frequency_timer = $Frequency
onready var duration_timer = $Duration
var shake_intensity = 0
func _ready():
	frequency_timer.connect("timeout", self, "_start_shake")
	duration_timer.connect("timeout", self, "_stop_shake")

# Define a function to start the screen shake
func shake(intensity, duration, frequency = 0.01):
	frequency_timer.wait_time = frequency
	shake_intensity = intensity
	frequency_timer.start()
	duration_timer.wait_time = duration
	duration_timer.start()
# Define a function to update the screen shake effect
func _start_shake():
	offset = Vector2(rand_range(-shake_intensity, shake_intensity), rand_range(-shake_intensity, shake_intensity))
func _stop_shake():
	frequency_timer.stop()
	offset = Vector2.ZERO
