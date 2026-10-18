extends Control

########### Script del Menu Principal ##############
@onready var menu: Control = $Menu
@onready var partida_ofline: Control = $partidaOfline
@onready var p_1: LineEdit = $partidaOfline/VBoxContainer/P1
@onready var p_2: LineEdit = $partidaOfline/VBoxContainer/P2

func _ready() -> void:
	menu.visible = true
	partida_ofline.visible = false
func _on_play_ofline_pressed() -> void:
	menu.visible = false
	partida_ofline.visible = true
	pass


func _on_play_pressed() -> void:
	
	get_tree().change_scene_to_file("res://MesaJuego.tscn") #instaciona la esena de juegoo
	pass # Replace with function body.


func _on_p_1_text_changed(new_text: String) -> void:
	Global.NameP1 = new_text
	print(Global.NameP1)
	pass # Replace with function body.


func _on_p_2_text_changed(new_text: String) -> void:
	Global.NameP2 = new_text
	print(Global.NameP2)
	pass # Replace with function body.
