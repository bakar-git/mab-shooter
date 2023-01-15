extends KinematicBody2D

onready var char_revolver = $gunPosition.get_children()[0]
onready var char_smg = $gunPosition.get_children()[1]
onready var char_sniper = $gunPosition.get_children()[2]

export var char_name = "character"
export var eye_Max_distance = 10
export var gravity = 600
export var air_friction = 5
export var floor_friction = 10
var flor = Vector2.UP
var velocity = Vector2.ZERO

puppet func eye_postions(l_eye, r_eye):
	$texture/left/Sprite.position = lerp($texture/left/Sprite.position, l_eye, 1)
	$texture/right/Sprite.position = lerp($texture/right/Sprite.position, r_eye, 1)
	
func _on_Network_tick_timeout():
	if is_network_master():
		rpc_unreliable("eye_postions", $texture/right/Sprite.position, $texture/right/Sprite.position)
		
puppet func self_position(s_pos):
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", s_pos, 0.01)

var health = Network.character_helath

remotesync var master_health = Network.character_helath setget set_health
func set_health(val):
	master_health = val
	health = master_health
	get_parent().get_node("MENU/HBoxContainer/HBoxContainer2/Health").text = str(health)
	hit_reaction()
		
func hit_reaction():
	if health <= 0:
		animate_death()
	else:
		animate_hurt()
		
func animate_hurt():
	$Tween.interpolate_property($texture, "modulate", modulate, Color(1,1,1,0), 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	$Tween.interpolate_property($texture, "rotation_degrees", $texture.rotation_degrees, 10, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Tween.interpolate_property($texture, "rotation_degrees", $texture.rotation_degrees, -10, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.interpolate_property($texture, "modulate", modulate, Color(1,1,1,1), 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	$Tween.interpolate_property($texture, "rotation_degrees", $texture.rotation_degrees, 0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
func animate_death():
	$Tween.interpolate_property(self, "modulate", modulate, Color(1,1,1,0), 1.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	$Tween.interpolate_property(self, "scale", scale, Vector2.ZERO, 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	queue_free()
	
puppetsync func configure_character(plyr_name, plyr_type):
	var id = get_tree().get_rpc_sender_id()
	var _char = null
	if plyr_type == "groot":
		_char = Network.groot.instance()
	elif plyr_type == "panda":
		_char = Network.panda.instance()
	name = "em"
	_char.name = str(id)
	_char.set_network_master(id)
	get_parent().add_child(_char)
	_char.global_position = global_position
	_char.get_node("name").visible = true
	_char.get_node("name").text = plyr_name
	_char.set_process(true)
	queue_free()

var thrust_rate = 0.9
var thrust_power = 800
var can_thrust = true
var thrust_timer = Timer.new()
func enable_thrust():
	can_thrust = true


func _ready():
	if char_name == "egg":
		$texture/left.visible = false
		$texture/right.visible = false
		$gunPosition.visible = false
	char_revolver.visible = true
	char_revolver.num_bullets = Network.revolver_bult
	char_smg.visible = false
	char_sniper.visible = false
	set_process(false)
	thrust_timer.wait_time = thrust_rate
	thrust_timer.one_shot = true
	thrust_timer.connect("timeout", self, "enable_thrust")
	add_child(thrust_timer)
	
func _process(delta):
	if is_network_master() and Network.match_start:
		var mouse_position = $texture.get_local_mouse_position()
		$texture/left/Sprite.position = Vector2.ZERO.direction_to(mouse_position) * min(mouse_position.length(), eye_Max_distance)
		$texture/right/Sprite.position = Vector2.ZERO.direction_to(mouse_position) * min(mouse_position.length(), eye_Max_distance)
		handle_friction()
		velocity.y += gravity*delta
		velocity = move_and_slide(velocity, flor)
		rpc("self_position", position)
		if Input.is_action_pressed("mouse_right") and can_thrust and !char_revolver.visible and !char_smg.visible and !char_sniper.visible:
			var frc = get_local_mouse_position().normalized()
			rpc("free_thrust", frc)
		
			

puppetsync func free_thrust(frc):
	velocity = frc*thrust_power
	get_node("ThrustAudio").play()
	can_thrust = false
	thrust_timer.start()


		
func handle_friction():
	# floor friction
	if velocity.x > 0 and is_on_floor():
		velocity.x -= floor_friction
		if(velocity.x < 0):
			velocity.x = 0
	elif velocity.x < 0 and is_on_floor():
		velocity.x += floor_friction
		if(velocity.x > 0):
			velocity.x = 0
	# air friction
	if velocity.x > 0 and !is_on_floor():
		velocity.x -= air_friction
		if(velocity.x < 0):
			velocity.x = 0
	elif velocity.x < 0 and !is_on_floor():
		velocity.x += air_friction
		if(velocity.x > 0):
			velocity.x = 0

func _on_Area2D_area_entered(area):
	if area.is_in_group("pickups"):
		if "revolver" in area.pickup_name:
			rpc("change_gun", 0, int(name))
		elif "smg" in area.pickup_name:
			rpc("change_gun", 1, int(name))
		elif "sniper" in area.pickup_name:
			rpc("change_gun", 2, int(name))
		area.queue_free()
		
remotesync func change_gun(choice, sent_by):
	if int(name) == sent_by:
		char_revolver.visible = false
		char_revolver.num_bullets = 0
		char_smg.visible = false
		char_smg.num_bullets = 0
		char_sniper.visible = false
		char_sniper.num_bullets = 0
		if choice == 0:
			char_revolver.visible = true
			char_revolver.num_bullets = Network.revolver_bult
			if is_network_master():
				get_tree().current_scene.get_node("MENU/HBoxContainer/HBoxContainer3/Bullet").text = str(Network.revolver_bult)
		elif choice == 1:
			char_smg.visible = true
			char_smg.num_bullets = Network.smg_bult
			if is_network_master():
				get_tree().current_scene.get_node("MENU/HBoxContainer/HBoxContainer3/Bullet").text = str(Network.smg_bult)
		elif choice == 2:
			char_sniper.visible = true
			char_sniper.num_bullets = Network.sniper_bult
			if is_network_master():
				get_tree().current_scene.get_node("MENU/HBoxContainer/HBoxContainer3/Bullet").text = str(Network.sniper_bult)
