extends Control

########### Script del Menu Principal ##############
@onready var language: Label = $InfQua/OptionButton/language
@onready var contenido: Label = $InfQua/ScrollContainer/VBoxContainer/Contenido
@onready var cont_esp: Label = $InfQua/ScrollContainer/VBoxContainer/ContEsp
@onready var menu: Control = $Menu
@onready var partida_ofline: Control = $partidaOfline
@onready var p_1: LineEdit = $partidaOfline/VBoxContainer/P1
@onready var p_2: LineEdit = $partidaOfline/VBoxContainer/P2
@onready var inf_qua: Control = $InfQua
@onready var contra_maquina: CheckButton = $partidaOfline/VBoxContainer/ContraMaquina
@onready var bando: OptionButton = $partidaOfline/VBoxContainer/Bando
@onready var aviso: Label = $partidaOfline/VBoxContainer/Aviso
@onready var save_a: AudioStreamPlayer2D = $save_A
@onready var pointer: AudioStreamPlayer2D = $Pointer
@onready var save_b: AudioStreamPlayer2D = $save_B
@onready var sountrack: AudioStreamPlayer2D = $sountrack


func _ready() -> void:
	sountrack.play()
	menu.visible = true
	partida_ofline.visible = false
	inf_qua.visible = false

	# Estado limpio en cada vuelta al menú.
	Global.modo = Global.Modo.DOS_JUGADORES
	Global.bando_humano = 0
	Global.dificultad = 1
	Global.NameP1 = "player 1"
	Global.NameP2 = "player 2"

	bando.clear()
	bando.add_item("You play as blue.")
	bando.add_item("You play as red.")
	bando.selected = 0

	_aplicar_modo()


func _aplicar_modo() -> void:
	var vs_maquina := contra_maquina.button_pressed
	bando.visible = vs_maquina
	aviso.visible = vs_maquina
	p_2.visible = not vs_maquina
	p_1.placeholder_text = "Your name" if vs_maquina else "P1 Enter your name"


func _on_contra_maquina_toggled(_activado: bool) -> void:
	_aplicar_modo()


func _on_bando_item_selected(index: int) -> void:
	Global.bando_humano = index


func _on_play_ofline_pressed() -> void:
	save_a.play()
	menu.visible = false
	partida_ofline.visible = true
	inf_qua.visible = false


func _on_jugar_online_pressed() -> void:
	
	Red.salir()
	get_tree().change_scene_to_file("res://Scenes/lobby_online.tscn")


func _on_play_pressed() -> void:
	
	var nombre := p_1.text.strip_edges()
	if nombre == "":
		nombre = "Player"

	if contra_maquina.button_pressed:
		Global.modo = Global.Modo.CONTRA_MAQUINA
		Global.bando_humano = bando.selected
		Global.dificultad = 1
		if Global.bando_humano == 0:
			Global.NameP1 = nombre
			Global.NameP2 = Global.NOMBRE_MAQUINA
		else:
			Global.NameP1 = Global.NOMBRE_MAQUINA
			Global.NameP2 = nombre
	else:
		Global.modo = Global.Modo.DOS_JUGADORES
		var nombre2 := p_2.text.strip_edges()
		Global.NameP1 = nombre
		Global.NameP2 = nombre2 if nombre2 != "" else "Player 2"

	get_tree().change_scene_to_file("res://MesaJuego.tscn")


func _on_demo_pressed() -> void:
	save_a.play()
	Global.modo = Global.Modo.DEMO
	Global.dificultad = 1
	Global.NameP1 = "Machine blue"
	Global.NameP2 = "Machine red"
	get_tree().change_scene_to_file("res://MesaJuego.tscn")


func _on_p_1_text_changed(new_text: String) -> void:
	Global.NameP1 = new_text


func _on_p_2_text_changed(new_text: String) -> void:
	Global.NameP2 = new_text


func _on_informacion_pressed() -> void:
	save_a.play()
	menu.visible = false
	partida_ofline.visible = false
	inf_qua.visible = true


func _on_volver_pressed() -> void:
	pointer.play()
	menu.visible = true
	inf_qua.visible = false
	partida_ofline.visible = false


func _on_quit_pressed() -> void: 
	get_tree().quit()


func _on_link_button_pressed() -> void:
	OS.shell_open("https://github.com/haidercapera440")
	pass # Replace with function body.


func _on_font_pressed() -> void:
	OS.shell_open("https://yukipixels.itch.io/boldpixels")
	pass # Replace with function body.


func _on_sound_pressed() -> void:
	OS.shell_open("https://emoviolencestudios.itch.io/")
	pass # Replace with function body.


func _on_option_button_item_selected(index: int) -> void:
	language.visible = false
	if index == 0:
		
		contenido.visible = true
		cont_esp.visible  = false
	elif index == 1:
		contenido.visible = false
		cont_esp.visible = true
		
	pass # Replace with function body.


func _on_sound_track_pressed() -> void:
	OS.shell_open("https://davidkbd.itch.io/purgatory-vol-3-extreme-metal-music-pack")
	pass # Replace with function body.
	
	#videojuego creado por Haidercapera440 
	# Juego Terminado el 31/10/2026
