extends Node2D

export var bullet_speed = 1000
export var gun_name = "gun"
export var num_bullets = 0
export var bullet_damage = 10
export (PackedScene) var bullet = null
export var bullet_position = Vector2(410, -45)
export var bullet_position_fliped = Vector2(410, 45)
export var recoil = 400
export var fire_rate = 0.5
export var thrust_power = 400
export var thrust_rate = 0.8
export var gun_shrink = Vector2(0.9, 1)
export (Color) var bf_bullet = Color(2,2,2,1) # before fire
export (Color) var af_bullet = Color(1.4,1.4,1.4,1) # after fire
var can_thrust = true
var thrust_timer = Timer.new()
func enable_thrust():
	can_thrust = true
var can_fire = true
var fire_timer = Timer.new()
func enable_fire():
	can_fire = true

onready var texture = $texture
onready var postion2d = $Position2D
onready var audio = $audio
onready var audioHit = $audioHit
 

func _ready():
	if is_network_master():
		get_tree().current_scene.get_node("MENU/HBoxContainer/HBoxContainer3/Bullet").text = str(Network.revolver_bult)
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	fire_timer.connect("timeout", self, "enable_fire")
	add_child(fire_timer)
	thrust_timer.wait_time = thrust_rate
	thrust_timer.one_shot = true
	thrust_timer.connect("timeout", self, "enable_thrust")
	add_child(thrust_timer)



puppet var puppet_rotation = 0 setget set_puppet_rotation
func set_puppet_rotation(val):
	puppet_rotation = val
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", puppet_rotation, 0.1)
	handle_rotation()
	
func _process(delta):
	if is_network_master():
		handle_rotation()
		look_at(get_global_mouse_position())
		if Input.is_action_pressed("mouse_right") and can_thrust and Network.match_start and visible:
			var frc = get_parent().get_parent().get_local_mouse_position().normalized()
			rpc("thrust", frc)
		if Input.is_action_pressed("mouse_left") and can_fire and Network.match_start and visible:
			var frc = get_parent().get_parent().get_local_mouse_position().normalized()
			rpc("fire", frc, $Position2D.global_position, rotation_degrees, rotation)

func handle_rotation():
	if wrapf(rotation, 0, 2*PI) > PI/2 and wrapf(rotation, 0, 2*PI) < (3*PI)/2:
		texture.set_flip_v(true)
		postion2d.position = bullet_position_fliped
	else:
		texture.set_flip_v(false)
		postion2d.position = bullet_position

puppetsync func fire(recoil_force, bullet_pos, bullet_rot, bullet_fire_angle):
	num_bullets-=1
	if is_network_master():
		get_tree().current_scene.get_node("MENU/HBoxContainer/HBoxContainer3/Bullet").text = str(num_bullets)
	var bullet_instance = bullet.instance()
	bullet_instance.position = bullet_pos
	bullet_instance.rotation_degrees = bullet_rot
	bullet_instance.modulate = bf_bullet
	bullet_instance.velocity = Vector2(bullet_speed, 0).rotated(bullet_fire_angle)
	audio.play()
	if num_bullets <= 0:
		visible = false
	get_tree().get_root().add_child(bullet_instance)
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", self, "anim_complete")
	tween.tween_property(texture, "scale", gun_shrink, 0.05)
	tween.tween_property(bullet_instance, "modulate", af_bullet, 0.1)
	var parent = get_parent().get_parent()
	parent.velocity = -1*recoil_force*recoil
	bullet_instance.get_node("VisibilityNotifier2D").connect("screen_exited", self, "on_bullet_screen_exit", [bullet_instance])
	bullet_instance.get_node("Area2D").connect("body_entered", self, "_on_Area2D_body_entered", [get_network_master(), bullet_instance])
	can_fire = false
	fire_timer.start()
	
		
		
func _on_Area2D_body_entered(body, fired_by_id, self_instance):
	if audioHit == null:
		audioHit = get_tree().current_scene.get_node("UniversalPlayer")
	if body.is_in_group("players") and int(body.name) != int(get_tree().get_network_unique_id()) and int(body.name) != int(fired_by_id):
		if "sniper_gun" == gun_name:
			audioHit.stream = Network.lgBultHit
		elif "smg_gun" == gun_name:
			audioHit.stream = Network.mdBultHit
		elif "revolver_gun" == gun_name:
			audioHit.stream = Network.smBultHit
		body.health -= bullet_damage
		if body.health <= 0:
			body.health = 0
		body.hit_reaction()
		if int(body.name) != get_tree().get_network_unique_id():
			body.rset_id(int(body.name), "master_health", body.health)
#		body.rset("master_health", body.health)
		if is_network_master():
			if "smg_gun" == gun_name:
				get_tree().current_scene.get_node("Camera2D").shake(2, 0.1)
			else:
				get_tree().current_scene.get_node("Camera2D").shake(5, 0.2)
	else:
		audioHit.stream = Network.floorHit
	bullet_collide_visuals(body, self_instance)
	audioHit.play()
	self_instance.queue_free()
	 
	
func bullet_collide_visuals(body : Node2D, bult_inst : Node2D):
	var x = Network.particles_effect.instance()
	x.emitting = true
	x.rotation_degrees = bult_inst.rotation_degrees+180 % 360
	x.global_position = bult_inst.global_position
	if body.is_in_group("players") and body.health <= 0:
		x.process_material.set("initial_velocity", 500)
		x.process_material.set("spread", 180)
		x.process_material.set("scale", 15)
		x.amount = 50
		x.modulate = Color(0,1,1.7,1)
	elif body.is_in_group("players") and body.health > 0:
		x.process_material.set("initial_velocity", 200)
		x.process_material.set("spread", 90)
		x.process_material.set("scale", 7)
		x.amount = 20
		randomize()
		x.modulate = Color(rand_range(1.5, 1.7),rand_range(0,1),rand_range(0,1.5),1)
	else:
		x.process_material.set("initial_velocity", 200)
		x.process_material.set("spread", 90)
		x.process_material.set("scale", 5)
		x.amount = 10
		x.modulate = Color(1,1,1,0.7)
	body.get_parent().add_child(x)
	
	
	
func anim_complete():
		texture.scale = Vector2(1,1);

puppetsync func thrust(frc):
	var parent = get_parent().get_parent()
	parent.velocity = frc*thrust_power
	parent.get_node("ThrustAudio").play()
	can_thrust = false
	thrust_timer.start()
		
func on_bullet_screen_exit(bult):
	bult.queue_free()

func _on_Network_timer_timeout():
	if is_network_master():
		rset_unreliable("puppet_rotation", rotation)
		
