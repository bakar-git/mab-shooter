extends Node2D
var timeout = Timer.new()
func _ready():
	count_down_timer.wait_time = 1
	count_down_timer.connect("timeout", self, "on_cd_time_out")
	add_child(count_down_timer)
	timeout.wait_time = 5
	timeout.one_shot = true
	timeout.connect("timeout", self, "on_time_out")
	add_child(timeout)
	timeout.start()
	$MENU/HBoxContainer/HBoxContainer/Name.text = DataStore.player_name
	$BackgroundStuff/BackgroundMusic.play(DataStore.bg_music_posistion)
#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")
	if Network.server != null:
		var position_index = randi()%Network.spawn_positions.size()
		var pos = Network.spawn_positions[position_index]
		Network.spawn_positions.remove(position_index)
		DataStore.player_position = pos
		register_player(get_tree().get_network_unique_id())
		$StartMatch/MarginContainer/btn_start_match.visible = true
		$StartMatch/MarginContainer/btn_start_match.grab_focus()
	if Network.client != null:
		$StartMatch/MarginContainer/count_down.visible = true
		
var count_down_timer = Timer.new()
var count_down = 5
func on_cd_time_out():
	count_down -= 1
	$StartMatch/MarginContainer/count_down.text = str(count_down)
	if count_down <= 0 :
		count_down_timer.stop()
		if get_tree().get_network_unique_id() == 1:
			rpc("start_match")

func on_time_out():
	if !Network.server_found and Network.server == null:
		_on_btn_end_match_pressed()

func _process(delta):
	if $BackgroundStuff/BackgroundMusic.playing == false :
		$BackgroundStuff/BackgroundMusic.playing = true
	if Input.is_action_just_pressed("ui_cancel"):
		$EndMatch.visible = !$EndMatch.visible
		if $EndMatch.visible:
			$EndMatch/MarginContainer/btn_end_match.grab_focus()

func _connected_to_server():
	register_player(get_tree().get_network_unique_id())	

func _player_connected(id):
	if get_tree().get_network_unique_id() == 1:
		var position_index = randi()%Network.spawn_positions.size()
		var pos = Network.spawn_positions[position_index]
		Network.spawn_positions.remove(position_index)
		Network.send_data(pos, id)
		if !Network.match_start:
			rpc_id(id, "server_found")
		else:
			return
	register_player(id)

func _player_disconnected(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free()

func _server_disconnected():
	_on_btn_end_match_pressed()

func _connection_failed():
	_on_btn_end_match_pressed()

func register_player(id):
	var player_instance =  Network.egg.instance()
	add_child(player_instance)
	player_instance.name = str(id)
	player_instance.set_network_master(id)
	if get_tree().get_network_unique_id() == id:
		yield(get_tree().create_timer(1), "timeout")
		player_instance.position = DataStore.player_position
	else:
		player_instance.position = Vector2(rand_range(100, 900), rand_range(100, 500))

remotesync func start_match():
	get_node(str(get_tree().get_network_unique_id())).rpc("configure_character", DataStore.player_name, DataStore.player_type)
	$GunSpawnTimer.start()
	Network.match_start = true
	$StartMatch.visible = false
	$MENU/HBoxContainer/HBoxContainer2/Health.text = str(Network.character_helath)
	
remotesync func start_count_down():
	$StartMatch/MarginContainer/count_down.visible = true
	$StartMatch/MarginContainer/btn_start_match.visible = false
	$StartMatch/MarginContainer/count_down.text = str(count_down)
	count_down_timer.start()

remote func server_found():
	Network.server_found=true

func _on_btn_start_match_pressed():
	if(get_tree().get_network_unique_id() == 1):
		rpc("start_count_down")

func _on_btn_end_match_pressed():
	get_tree().network_peer = null
	Network.client = null
	Network.server = null
	Network.server_found = false
	Network.match_start = false
	queue_free()
	get_tree().change_scene("res://scenes/TitleScreen.tscn")

remotesync func spawn_a_gun(pos_ind, gun_ind):
	var gun = Network.gun_list[gun_ind].instance()
	gun.position = Network.gun_positions[pos_ind]
	add_child(gun)


func _on_GunSpawnTimer_timeout():
	if get_tree().get_network_unique_id() == 1:
		randomize()
		var gun_pos_ind = randi()%Network.gun_positions.size()
		var gun_ind = randi()%Network.gun_list.size()
		rpc("spawn_a_gun", gun_pos_ind, gun_ind)
