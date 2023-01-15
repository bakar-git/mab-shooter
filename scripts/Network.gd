extends Node

const Port = 9080
const character_helath = 100

var sniper_bult = 3
var smg_bult = 20
var revolver_bult = 10

var spawn_positions = null

var gun_positions = [
		Vector2(176, 100), Vector2(540, 100), Vector2(884, 100),
		Vector2(176, 300), Vector2(540, 300), Vector2(884, 300)
	]

var server = null
var client = null
var server_found = false
remotesync var match_start = false

var particles_effect = preload("res://scenes/ParticleEffect.tscn")
var floorHit = preload("res://assets/sounds/floorHit.mp3")
var lgBultHit = preload("res://assets/sounds/lg bult hit flesh.mp3")
var mdBultHit = preload("res://assets/sounds/md bult hit flesh.mp3")
var smBultHit = preload("res://assets/sounds/sm bult hit flesh.mp3")
var sniper = preload("res://scenes/Guns/SniperGun.tscn")
var revolver = preload("res://scenes/Guns/RevolverGun.tscn")
var smg = preload("res://scenes/Guns/SMGGun.tscn")
var panda = preload("res://scenes/Characters/Panda.tscn")
var groot = preload("res://scenes/Characters/Groot.tscn")
var egg = preload("res://scenes/Characters/Egg.tscn")

var gun_list = [preload("res://scenes/Pickup/Revolver.tscn"), preload("res://scenes/Pickup/SMG.tscn"), preload("res://scenes/Pickup/Sniper.tscn")]


var ip_address = ""
func _ready():
	ip_address = get_IP_addr()

func get_IP_addr():
	var res = ""
	if OS.get_name() == "Windows":
		res = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		res = IP.get_local_addresses()[0]
	else:
		res = IP.get_local_addresses()[3]
		
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			res = ip
			break
	return res
	
func create_server():
	server = NetworkedMultiplayerENet.new()
	server.create_server(Port)
	get_tree().network_peer = server
	
func join_server():
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address, Port)
	get_tree().network_peer = client
	

	
func send_data(data, id):
	rpc_id(id, "receieved_data", data)
	
remote func receieved_data(data):
	DataStore.player_position = data
	
