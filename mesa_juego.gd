extends Node2D

@onready var fichas = [
	##fichas azules
	{"ficha":$EquipoAzul/fichaAzulArea}, #0
	{"ficha":$EquipoAzul/fichaAzulArea2}, #1
	{"ficha":$EquipoAzul/fichaAzulArea3},#2
	{"ficha":$EquipoAzul/fichaAzulArea4},#3
	{"ficha":$EquipoAzul/fichaAzulArea5},#4
	##fichas rojas
	{"ficha":$EquipoRojo/fichaRojaArea},#5
	{"ficha":$EquipoRojo/fichaRojaArea2},#6
	{"ficha":$EquipoRojo/fichaRojaArea3},#7
	{"ficha":$EquipoRojo/fichaRojaArea4},#8
	{"ficha":$EquipoRojo/fichaRojaArea5}]#9
@onready var text_turno: Label = $textTurno



################# AREAS DE LOS PUNTOS ##########################
@onready var punto: Area2D = $Puntos/punto
@onready var punto_2: Area2D = $Puntos/punto2
@onready var punto_3: Area2D = $Puntos/punto3
@onready var punto_4: Area2D = $Puntos/punto4
@onready var punto_5: Area2D = $Puntos/punto5
@onready var punto_6: Area2D = $Puntos/punto6
@onready var punto_7: Area2D = $Puntos/punto7
@onready var punto_8: Area2D = $Puntos/punto8
@onready var punto_9: Area2D = $Puntos/punto9
@onready var punto_10: Area2D = $Puntos/punto10
@onready var punto_11: Area2D = $Puntos/punto11
@onready var punto_12: Area2D = $Puntos/punto12
@onready var punto_13: Area2D = $Puntos/punto13
@onready var punto_14: Area2D = $Puntos/punto14
@onready var punto_15: Area2D = $Puntos/punto15
@onready var punto_16: Area2D = $Puntos/punto16
@onready var punto_17: Area2D = $Puntos/punto17
@onready var punto_18: Area2D = $Puntos/punto18
@onready var punto_19: Area2D = $Puntos/punto19
@onready var punto_20: Area2D = $Puntos/punto20
@onready var punto_21: Area2D = $Puntos/punto21
@onready var punto_22: Area2D = $Puntos/punto22
@onready var punto_23: Area2D = $Puntos/punto23
@onready var punto_24: Area2D = $Puntos/punto24
#################################################################

@onready var Puntos = [{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}]

enum Estados {
	INICIO,
	JUGANDO,
	TERNINADO
}
var estadoActual = Estados.INICIO
var Turno: bool = false #tru para azul #false rojo

var ArrayQua = [{"a": 0, "b": 1, "c": 2}, {"a": 3, "b": 4, "c": 5},{"a": 6, "b": 7, "c": 8},
{"a": 9, "b": 10, "c": 11},{"a": 12, "b": 13, "c": 14},{"a": 15, "b": 16, "c": 17},{"a": 18, "b": 19, "c": 20},{"a": 21, "b": 22, "c": 23},
{"a": 0, "b": 18, "c": 15},{"a": 3, "b": 19, "c": 12},{"a": 6, "b": 20, "c": 9},{"a": 1, "b": 4, "c": 7},
{"a": 10, "b": 13, "c": 16},{"a": 8, "b": 21, "c": 11},{"a": 5, "b": 22, "c": 14},{"a": 2, "b": 23, "c": 17},
{"a": 0, "b": 3, "c": 6},{"a": 15, "b": 12, "c": 9},{"a": 8, "b": 5, "c": 2},{"a": 11, "b": 14, "c": 17}]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(Puntos.size())
	turnosCambio(Turno)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.

	
	

func turnosCambio(boleano):
	if boleano == false:
		text_turno.add_theme_color_override("font_color",Color.BLUE)
		text_turno.text = "AZUL: " + str(Turno)
		Turno = true
	else:
		text_turno.add_theme_color_override("font_color",Color.RED)
		text_turno.text = "ROJO: "+str(Turno)
		Turno = false
		
	
func GestorUbicacioFicha(num,boleno): #funcion para las fichas 
	if Global.UbiPunto == null:
		return
	fichas[num]["ficha"].global_position = Global.UbiPunto
	turnosCambio(boleno)


func cambiarEstoPunto(num, boleano, area): ##funcion que cambia el estado de los puntos 
		Global.UbiPunto = null
		Puntos[num]["Punto"] = area
		print(Puntos[num]["Punto"])
		Puntos[num]["ocupado"] = boleano
		print(Puntos[num]["ocupado"])
		dectetarTriqui()
	
		

func dectetarTriqui():
	
	for i in range(0,20,1):
		print(i, "A: ", Puntos[ArrayQua[i]["a"]]["ocupado"], " B: ",Puntos[ArrayQua[i]["b"]]["ocupado"]," C: ", Puntos[ArrayQua[i]["c"]]["ocupado"])
		if Puntos[ArrayQua[i]["a"]]["ocupado"] == true and Puntos[ArrayQua[i]["b"]]["ocupado"] == true and  Puntos[ArrayQua[i]["c"]]["ocupado"] == true:
			if Puntos[ArrayQua[i]["a"]]["Punto"].is_in_group("Rojo") and Puntos[ArrayQua[i]["b"]]["Punto"].is_in_group("Rojo") and Puntos[ArrayQua[i]["c"]]["Punto"].is_in_group("Rojo"):
				print("gano rojo")
				continue
				
			else:
				if Puntos[ArrayQua[i]["a"]]["Punto"].is_in_group("Azul") and Puntos[ArrayQua[i]["b"]]["Punto"].is_in_group("Azul") and Puntos[ArrayQua[i]["c"]]["Punto"].is_in_group("Azul"):
					print("gano azul")
					



######## BOTONES DE LOS PUNTOS #######


func _on_punto_3_pressed() -> void:
	Global.UbiPunto = punto_3.global_position
	pass # Replace with function body.


func _on_punto_4_pressed() -> void:
	Global.UbiPunto = punto_4.global_position
	pass # Replace with function body.


func _on_punto_5_pressed() -> void:
	Global.UbiPunto = punto_5.global_position
	pass # Replace with function body.


func _on_punto_7_pressed() -> void:
	Global.UbiPunto = punto_7.global_position
	pass # Replace with function body.


func _on_punto_8_pressed() -> void:
	Global.UbiPunto = punto_8.global_position
	pass # Replace with function body.


func _on_punto_10_pressed() -> void:
	Global.UbiPunto = punto_10.global_position
	pass # Replace with function body.


func _on_punto_11_pressed() -> void:
	Global.UbiPunto = punto_11.global_position
	pass # Replace with function body.


func _on_punto_12_pressed() -> void:
	Global.UbiPunto = punto_12.global_position
	pass # Replace with function body.


func _on_punto_13_pressed() -> void:
	Global.UbiPunto = punto_13.global_position
	pass # Replace with function body.


func _on_punto_15_pressed() -> void:
	Global.UbiPunto = punto_15.global_position
	pass # Replace with function body.


func _on_punto_16_pressed() -> void:
	Global.UbiPunto = punto_16.global_position
	pass # Replace with function body.


func _on_punto_17_pressed() -> void:
	Global.UbiPunto = punto_17.global_position
	pass # Replace with function body.


func _on_punto_19_pressed() -> void:
	Global.UbiPunto = punto_19.global_position
	pass # Replace with function body.


func _on_punto_22_pressed() -> void:
	Global.UbiPunto = punto_22.global_position
	pass # Replace with function body.


func _on_punto_23_pressed() -> void:
	Global.UbiPunto = punto_23.global_position
	pass # Replace with function body.


func _on_punto_24_pressed() -> void:
	Global.UbiPunto = punto_24.global_position
	pass # Replace with function body.

######## Botones ###########

func _on_punto_1_pressed() -> void:
	Global.UbiPunto = punto.global_position



func _on_punto_2_pressed() -> void:
	Global.UbiPunto = punto_2.global_position
	pass # Replace with function body.


func _on_punto_6_pressed() -> void:
	Global.UbiPunto = punto_6.global_position
	pass # Replace with function body.


func _on_punto_9_pressed() -> void:
	Global.UbiPunto = punto_9.global_position
	pass # Replace with function body.


func _on_punto_14_pressed() -> void:
	Global.UbiPunto = punto_14.global_position
	pass # Replace with function body.


func _on_punto_18_pressed() -> void:
	Global.UbiPunto = punto_18.global_position
	pass # Replace with function body.


func _on_punto_20_pressed() -> void:
	Global.UbiPunto = punto_20.global_position
	pass # Replace with function body.


func _on_punto_21_pressed() -> void:
	Global.UbiPunto = punto_21.global_position
	pass # Replace with function body.
	


	
##### Botones Azules #######

func _on_azul_button_1_pressed() -> void:
	if Turno == true:
		GestorUbicacioFicha(0,true)


func _on_azul_button_2_pressed() -> void:
	if Turno == true:
		GestorUbicacioFicha(1,true)
	pass # Replace with function body.


func _on_azul_button_3_pressed() -> void:
	if Turno == true:
		GestorUbicacioFicha(2,true)
	pass # Replace with function body.


func _on_azul_button_4_pressed() -> void:
	if Turno == true:
		GestorUbicacioFicha(3,true)
	pass # Replace with function body.


func _on_azul_button_5_pressed() -> void:
	if Turno == true:
		GestorUbicacioFicha(4,true)
	pass # Replace with function body.


##### Botones Rjos #####	

func _on_rojo_button_1_pressed() -> void:
	if Turno == false:
		GestorUbicacioFicha(5,false)
	pass # Replace with function body.


func _on_rojo_button_2_pressed() -> void:
	if Turno == false:
		GestorUbicacioFicha(6,false)
	pass # Replace with function body.


func _on_rojo_button_3_pressed() -> void:
	if Turno == false:
		GestorUbicacioFicha(7,false)
	pass # Replace with function body.


func _on_rojo_button_4_pressed() -> void:
	if Turno == false:
		GestorUbicacioFicha(8,false)
	pass # Replace with function body.


func _on_rojo_button_5_pressed() -> void:
	if Turno == false:
		GestorUbicacioFicha(9,false)
	pass # Replace with function body.
	
	
######## AREAS DE LOS PUNTOS ##############

func _on_punto_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(0,true,area)

func _on_punto_area_exited(area: Area2D) -> void:
	area = null
	cambiarEstoPunto(0,false,area)

	

func _on_punto_2_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(1,true,area)
	pass # Replace with function body.


func _on_punto_2_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(1,false,area)



func _on_punto_3_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(2,true,area)
	pass # Replace with function body.


func _on_punto_3_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(2,false,area)
	pass # Replace with function body.


func _on_punto_4_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(3,true,area)
	pass # Replace with function body.


func _on_punto_4_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(3,false,area)
	pass # Replace with function body.


func _on_punto_5_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(4,true,area)
	pass # Replace with function body.


func _on_punto_5_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(4,false,area)
	pass # Replace with function body.


func _on_punto_6_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(5,true,area)
	pass # Replace with function body.


func _on_punto_6_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(5,false,area)
	pass # Replace with function body.


func _on_punto_7_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(6,true,area)
	pass # Replace with function body.


func _on_punto_7_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(6,false,area)


func _on_punto_8_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(7,true,area)


func _on_punto_8_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(7,false,area)


func _on_punto_9_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(8,true,area)


func _on_punto_9_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(8,false,area)


func _on_punto_10_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(9,true,area)


func _on_punto_10_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(9,false,area)


func _on_punto_11_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(10,true,area)


func _on_punto_11_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(10,false,area)


func _on_punto_12_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(11,true,area)


func _on_punto_12_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(11,false,area)


func _on_punto_13_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(12,true,area)


func _on_punto_13_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(12,false,area)


func _on_punto_14_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(13,true,area)


func _on_punto_14_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(13,false,area)


func _on_punto_15_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(14,true,area)


func _on_punto_15_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(14,false,area)


func _on_punto_16_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(15,true,area)


func _on_punto_16_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(15,false,area)


func _on_punto_17_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(16,true,area)


func _on_punto_17_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(16,false,area)


func _on_punto_18_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(17,true,area)

func _on_punto_18_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(17,false,area)


func _on_punto_19_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(18,true,area)


func _on_punto_19_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(18,false,area)


func _on_punto_20_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(19,true,area)


func _on_punto_20_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(19,false,area)


func _on_punto_21_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(20,true,area)


func _on_punto_21_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(20,false,area)


func _on_punto_22_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(21,false,area)


func _on_punto_22_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(21,false,area)


func _on_punto_23_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(22,true,area)


func _on_punto_23_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(22,false,area)


func _on_punto_24_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(23,true,area)


func _on_punto_24_area_exited(area: Area2D) -> void:
	cambiarEstoPunto(23,false,area)
