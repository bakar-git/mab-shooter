extends Node2D

var choice = 0

func _ready():
	$MENU/MarginContainer/VBoxContainer/Section_main_menu/VBoxContainer/MarginContainer/Btn_create_server.grab_focus()
	Network.spawn_positions = [
		Vector2(176, 100), Vector2(540, 100), Vector2(884, 100),
	#	Vector2(176, 300), Vector2(540, 300), Vector2(884, 300),
		Vector2(176, 300), Vector2(884, 300),
		Vector2(176, 500), Vector2(540, 500), Vector2(884, 500)
	]
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	$ParallaxBackground.scroll_offset += Vector2(-1, 0) * 800 * delta
	$Cursor.position = get_global_mouse_position()
	$Cursor.rotation += PI*0.8*delta
	if Input.is_action_just_pressed("ui_cancel"):
		reset_menus()

func reset_menus():
	$SecondMenu.visible = false
	$SecondMenu/MarginContainer/Section_create_server.visible = false
	$SecondMenu/MarginContainer/Section_join_server.visible = false
	$CustomizationMENU.visible = false
	$CustomizationMENU/MarginContainer/Section_name_customization.visible = false
	$CustomizationMENU/MarginContainer/Section_character_customization.visible = false

func random_name():
	var random_string = ""
	for i in range(5):
		randomize()
		random_string += char(int(rand_range(65, 91)))
	return random_string

func _on_Btn_create_server_pressed():
	# choice 1 indicates, create server button is pressed
	choice = 1
	_show_customization_section()
	
	
func _on_Btn_join_server_pressed():
	# choice 2 indicates, join server button is pressed
	choice = 2
	_show_customization_section()
	
func _show_customization_section():
	# show name section 
	$CustomizationMENU.visible = true
	$CustomizationMENU/MarginContainer/Section_name_customization.visible = true
	# set random name
	var name = random_name()
	DataStore.player_name = name
	$CustomizationMENU/MarginContainer/Section_name_customization/VBoxContainer/HBoxContainer/Fld_name.text = name
	# set focus
	$CustomizationMENU/MarginContainer/Section_name_customization/VBoxContainer/Btn_submit_name.grab_focus()


func _on_Btn_exit_pressed():
	get_tree().quit()

func _on_Btn_submit_serverIP_pressed():
	var ip = $SecondMenu/MarginContainer/Section_join_server/VBoxContainer/HBoxContainer/Fld_serverIP
	var error = $SecondMenu/MarginContainer/Section_join_server/VBoxContainer/Txt_error_connect
	if ip.text.empty():
		error.text = "Error : Empty IP field"
	else:
		Network.ip_address = ip.text
		Network.join_server()
		DataStore.bg_music_posistion = $BackgroundMusic.get_playback_position()
		get_tree().change_scene("res://scenes/Match.tscn")

func _on_Btn_submit_create_server_pressed():
	Network.create_server()
	DataStore.bg_music_posistion = $BackgroundMusic.get_playback_position()
	get_tree().change_scene("res://scenes/Match.tscn")

func _on_Btn_submit_name_pressed():
	var name = $CustomizationMENU/MarginContainer/Section_name_customization/VBoxContainer/HBoxContainer/Fld_name.text
	if name.length() <= 5:
		DataStore.player_name = name
	# hide name section 
	$CustomizationMENU/MarginContainer/Section_name_customization.visible = false
	# show character selection section
	$CustomizationMENU/MarginContainer/Section_character_customization.visible = true
	# set focus
	$CustomizationMENU/MarginContainer/Section_character_customization/HBoxContainer/btn_panda_select.grab_focus()

func _on_btn_panda_select_pressed():
	DataStore.player_type = "panda"
	_show_second_menu()

func _on_btn_groot_selet_pressed():
	DataStore.player_type = "groot"
	_show_second_menu()

func _show_second_menu():
	$CustomizationMENU/MarginContainer/Section_character_customization.visible = false
	$CustomizationMENU.visible = false
	# show second menu
	$SecondMenu.visible = true
	if choice == 1:
		Network.ip_address = Network.get_IP_addr()
		$SecondMenu/MarginContainer/Section_create_server.visible = true
		$SecondMenu/MarginContainer/Section_create_server/VBoxContainer/Txt_server_ip.text = "Priavte IP : " + Network.ip_address
		$SecondMenu/MarginContainer/Section_create_server/VBoxContainer/Btn_submit_create_server.grab_focus()
	elif choice == 2:
		$SecondMenu/MarginContainer/Section_join_server.visible = true
		$SecondMenu/MarginContainer/Section_join_server/VBoxContainer/HBoxContainer/Fld_serverIP.grab_focus()
