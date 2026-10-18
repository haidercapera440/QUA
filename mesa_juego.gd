extends Node2D

########## SCRIPT DEL JUEGO ################
##################################### Variables y Arrays ############################################
#Array de diccionaros para guardar la ubicacion de la ficha y estoy "en este punto" ---> al numero del punto donde se encuentra
@onready var fichas = [
	##fichas azules
	{"ficha":$EquipoAzul/fichaAzulArea, "estoy": null}, #0
	{"ficha":$EquipoAzul/fichaAzulArea2, "estoy": null},#1
	{"ficha":$EquipoAzul/fichaAzulArea3, "estoy": null},#2
	{"ficha":$EquipoAzul/fichaAzulArea4, "estoy": null},#3
	{"ficha":$EquipoAzul/fichaAzulArea5, "estoy": null},#4
	##fichas rojas
	{"ficha":$EquipoRojo/fichaRojaArea, "estoy": null},#5
	{"ficha":$EquipoRojo/fichaRojaArea2, "estoy": null},#6
	{"ficha":$EquipoRojo/fichaRojaArea3, "estoy": null},#7
	{"ficha":$EquipoRojo/fichaRojaArea4, "estoy": null},#8
	{"ficha":$EquipoRojo/fichaRojaArea5, "estoy": null}]#9

@onready var text_turno: Label = $textTurno #variable del nodo texto para mostrar los trunos

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

##### Array de diccionario que guarada el area 2d de cada punto y siete se encuetra desocupado "false" y ocupado "true"
@onready var Puntos = [{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}
,{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false},{"Punto": Area2D, "ocupado": false}]

#estados del juedo que indica el estado del juego
enum Estados {
	INICIO,
	JUGANDO,
	TERNINADO,
	ELIMINAR
}

var estadoActual = Estados.INICIO #variable que guarda el estado del juego
var Turno: bool = false #false para azul #true rojo
var contador = 0
var fichaAeliminar: Area2D
var fichasAzules: int = 5
var fichasRojas: int = 5
const VELOCIDAD_FICHA = 200.0
#Array de diccionaros de los triquis que puede hacer las fichas en los diferente puntos 
#Los triqui totales son 20 de cuentan desde 0 has 19 
var ArrayQua = [{"a": 0, "b": 1, "c": 2, "hizo": false}, 
{"a": 3, "b": 4, "c": 5, "hizo": false},
{"a": 6, "b": 7, "c": 8, "hizo": false},
{"a": 9, "b": 10, "c": 11, "hizo": false},
{"a": 12, "b": 13, "c": 14, "hizo": false},
{"a": 15, "b": 16, "c": 17, "hizo": false},
{"a": 18, "b": 19, "c": 20, "hizo": false},
{"a": 21, "b": 22, "c": 23, "hizo": false},
{"a": 0, "b": 18, "c": 15, "hizo": false},
{"a": 3, "b": 19, "c": 12, "hizo": false},
{"a": 6, "b": 20, "c": 9, "hizo": false},
{"a": 1, "b": 4, "c": 7, "hizo": false},
{"a": 10, "b": 13, "c": 16, "hizo": false},
{"a": 8, "b": 21, "c": 11, "hizo": false},
{"a": 5, "b": 22, "c": 14, "hizo": false},
{"a": 2, "b": 23, "c": 17, "hizo": false},
{"a": 0, "b": 3, "c": 6, "hizo": false},
{"a": 15, "b": 12, "c": 9, "hizo": false},
{"a": 8, "b": 5, "c": 2, "hizo": false},
{"a": 11, "b": 14, "c": 17, "hizo": false}]

#Array de diccionaros que guarda los movimientos que puede hacer ficha segun el punto don de se encuentre
#los punto van de 0 a 23
var Movimientos = [{"a": 1, "b": 3, "c": 18, "d":null},{"a": 0, "b": 4, "c": 2, "d":null},{"a": 1, "b": 5, "c": 23, "d":null},{"a": 0, "b": 19, "c": 6, "d": 4},{"a": 3, "b": 7, "c": 5, "d": 1},{"a": 4, "b": 8, "c": 2, "d": 22},{"a": 3, "b": 20, "c": 7, "d":null}
,{"a": 6, "b": 8, "c": 4,"d":null},{"a": 7, "b": 5, "c": 21,"d":null},{"a": 12, "b": 10, "c": 20,"d":null},{"a": 9, "b": 13, "c": 11,"d":null},{"a": 10, "b": 14, "c": 21,"d":null}
,{"a": 15, "b": 19, "c": 9,"d":13},{"a": 12, "b": 10, "c": 16,"d": 14},{"a": 13, "b": 11, "c": 17,"d":22},{"a": 18, "b": 12, "c": 16,"d":null},{"a": 15, "b": 13, "c": 17,"d":null},{"a": 16, "b": 14, "c": 23,"d":null}
,{"a": 0, "b": 15, "c": 19,"d":null},{"a": 18, "b": 3, "c": 12,"d":20},{"a": 19, "b": 6, "c": 9,"d":null},{"a": 22, "b": 8, "c": 11,"d":null},{"a": 21, "b": 14, "c": 5,"d":23},{"a": 2, "b": 22, "c": 17,"d":null}]

@onready var eliminar_ficha: Control = $EliminarFicha
var QuaEliminar
###################################################### FUNCIONES ################################################
func _ready() -> void:
	eliminar_ficha.visible = false
	turnosCambio(Turno)

#funcion que cambia el turno 
func turnosCambio(boleano):
	
	if boleano == false:
		text_turno.add_theme_color_override("font_color",Color.BLUE)
		text_turno.text = Global.NameP1
		Turno = true
	else:
		text_turno.add_theme_color_override("font_color",Color.RED)
		text_turno.text = Global.NameP2
		Turno = false
		
	if estadoActual == Estados.JUGANDO:
			dectetarTriqui()
			
			
#funcion para guardasr la ubicacion de las fichas en las ficha
func GestorUbicacioFicha(num,boleno):
	MostrarMenuEliminacion()
	fichaAeliminar = fichas[num]["ficha"]
	if Global.UbiPunto == null:
		return
	if estadoActual == Estados.INICIO:
		fichas[num]["ficha"].global_position = Global.UbiPunto
		fichas[num]["estoy"] = Global.numpunto
		print("Ficha: "+ str(fichas[num]["ficha"])+"punto: " + str(fichas[num]["estoy"]))
		contador += 1  #contador de ficha cuando las esta colocando en el tablero
		turnosCambio(boleno) #funcion para cambiar los turnos
		if contador == 10:
			estadoActual = Estados.JUGANDO
			Global.numpunto = null
	elif estadoActual == Estados.JUGANDO:
		PermitirMovimiento(num,boleno,fichas[num]["estoy"])
	
	
#funcion que permite el movimiento de las fichas cuando esta en el estado JUGANDO
func moverFicha(num, destino):
	var ficha = fichas[num]["ficha"]
	while ficha.global_position.distance_to(destino) > 1.0:
		ficha.global_position = ficha.global_position.move_toward(
			destino,
			VELOCIDAD_FICHA * get_process_delta_time()
		)
		await get_tree().process_frame

func PermitirMovimiento(num, boleno, puntoG):
	if estadoActual == Estados.JUGANDO:
		if Global.numpunto == Movimientos[puntoG]["a"] \
		or Global.numpunto == Movimientos[puntoG]["b"] \
		or Global.numpunto == Movimientos[puntoG]["c"] \
		or Global.numpunto == Movimientos[puntoG]["d"]:

			await moverFicha(num, Global.UbiPunto)

			fichas[num]["estoy"] = Global.numpunto
			turnosCambio(boleno)

		else: 
			print("NO PUEDES MOVER A ESE PUNTO")
			return
	else:
		return

################## Funcion que cambia los estados de los puntos ####################
func cambiarEstoPunto(num, boleano, area):
		Global.UbiPunto = null
		Puntos[num]["Punto"] = area
		print(Puntos[num]["Punto"])
		Puntos[num]["ocupado"] = boleano
		print(Puntos[num]["ocupado"])

			
func cambiarEstadoPunto(num):
	Puntos[num]["Punto"] = null
	Puntos[num]["ocupado"] = false
	pass
	
#funcion que detecta el triqui 
func dectetarTriqui():
	for i in range(0,20,1): #en un rango desde 0 hasta 19 con paso uno
		print(i, "A: ", Puntos[ArrayQua[i]["a"]]["ocupado"], " B: ",Puntos[ArrayQua[i]["b"]]["ocupado"]," C: ", Puntos[ArrayQua[i]["c"]]["ocupado"])
		if Puntos[ArrayQua[i]["a"]]["ocupado"] == true and Puntos[ArrayQua[i]["b"]]["ocupado"] == true and  Puntos[ArrayQua[i]["c"]]["ocupado"] == true and ArrayQua[i]["hizo"] == false:
			if Puntos[ArrayQua[i]["a"]]["Punto"].is_in_group("Rojo") and Puntos[ArrayQua[i]["b"]]["Punto"].is_in_group("Rojo") and Puntos[ArrayQua[i]["c"]]["Punto"].is_in_group("Rojo"): 
				print("gano rojo", ArrayQua[i], Puntos[i]["Punto"])
				QuaEliminar = true
				estadoActual = Estados.ELIMINAR
				Global.Ganador = Global.NameP2
				ArrayQua[i]["hizo"] = true
				
			else:
				if Puntos[ArrayQua[i]["a"]]["Punto"].is_in_group("Azul") and Puntos[ArrayQua[i]["b"]]["Punto"].is_in_group("Azul") and Puntos[ArrayQua[i]["c"]]["Punto"].is_in_group("Azul"):
					
					print("gano azul",  ArrayQua[i], Puntos[i]["Punto"])
					estadoActual = Estados.ELIMINAR
					QuaEliminar = false
					Global.Ganador = Global.NameP1
					ArrayQua[i]["hizo"] = true
		

############################### Botone de cancelar y eliminar ######################
func _on_cancelar_pressed() -> void:
	eliminar_ficha.visible = false
	pass # Replace with function body.

func _on_eliminar_pressed() -> void:
	EliminarFicha()
	
func  MostrarMenuEliminacion():
	if estadoActual == Estados.ELIMINAR and QuaEliminar != null:
		eliminar_ficha.visible = true
	else:
		return
	pass

func  EliminarFicha():
	if estadoActual == Estados.ELIMINAR:
		if fichaAeliminar.is_in_group("Rojo") and QuaEliminar == false:
			fichaAeliminar.queue_free()
			fichasRojas -= 1
		else:
			if fichaAeliminar.is_in_group("Azul") and  QuaEliminar == true:
				fichaAeliminar.queue_free()
				fichasAzules -= 1
				
		fichaAeliminar = null
		QuaEliminar = null
		eliminar_ficha.visible = false
		estadoActual = Estados.JUGANDO
		
		#codicion anuncia el fin del juego cuando halla dos fichas sean rojas o azules 
		if fichasAzules < 3  or fichasRojas < 3 : 
			get_tree().change_scene_to_file("res://Scenes/juego_terminado.tscn")
			#Escena de Juego terminado y anuncia el ganador
	else: 
		return

######################################################## BOTONES DE LOS PUNTOS ####################################################

func _on_punto_3_pressed() -> void:
	Global.numpunto = 2
	Global.UbiPunto = punto_3.global_position
	pass # Replace with function body.


func _on_punto_4_pressed() -> void:
	Global.numpunto = 3
	Global.UbiPunto = punto_4.global_position
	pass # Replace with function body.


func _on_punto_5_pressed() -> void:
	Global.numpunto = 4
	Global.UbiPunto = punto_5.global_position
	pass # Replace with function body.


func _on_punto_7_pressed() -> void:
	Global.numpunto = 6
	Global.UbiPunto = punto_7.global_position
	pass # Replace with function body.


func _on_punto_8_pressed() -> void:
	Global.numpunto = 7
	Global.UbiPunto = punto_8.global_position
	pass # Replace with function body.


func _on_punto_10_pressed() -> void:
	Global.numpunto = 9
	Global.UbiPunto = punto_10.global_position
	pass # Replace with function body.


func _on_punto_11_pressed() -> void:
	Global.numpunto = 10
	Global.UbiPunto = punto_11.global_position
	pass # Replace with function body.


func _on_punto_12_pressed() -> void:
	Global.numpunto = 11
	Global.UbiPunto = punto_12.global_position
	pass # Replace with function body.


func _on_punto_13_pressed() -> void:
	Global.numpunto = 12
	Global.UbiPunto = punto_13.global_position
	pass # Replace with function body.


func _on_punto_15_pressed() -> void:
	Global.numpunto = 14
	Global.UbiPunto = punto_15.global_position
	pass # Replace with function body.


func _on_punto_16_pressed() -> void:
	Global.numpunto = 15
	Global.UbiPunto = punto_16.global_position
	pass # Replace with function body.


func _on_punto_17_pressed() -> void:
	Global.numpunto = 16
	Global.UbiPunto = punto_17.global_position
	pass # Replace with function body.


func _on_punto_19_pressed() -> void:
	Global.numpunto = 18
	Global.UbiPunto = punto_19.global_position
	pass # Replace with function body.


func _on_punto_22_pressed() -> void:
	Global.numpunto = 21
	Global.UbiPunto = punto_22.global_position
	pass # Replace with function body.


func _on_punto_23_pressed() -> void:
	Global.numpunto = 22
	Global.UbiPunto = punto_23.global_position
	pass # Replace with function body.


func _on_punto_24_pressed() -> void:
	Global.numpunto = 23
	Global.UbiPunto = punto_24.global_position
	pass # Replace with function body.

######## Botones ###########

func _on_punto_1_pressed() -> void:
	Global.numpunto = 0
	Global.UbiPunto = punto.global_position



func _on_punto_2_pressed() -> void:
	Global.numpunto = 1
	Global.UbiPunto = punto_2.global_position
	pass # Replace with function body.


func _on_punto_6_pressed() -> void:
	Global.numpunto = 5
	Global.UbiPunto = punto_6.global_position
	pass # Replace with function body.


func _on_punto_9_pressed() -> void:
	Global.numpunto = 8
	Global.UbiPunto = punto_9.global_position
	pass # Replace with function body.


func _on_punto_14_pressed() -> void:
	Global.numpunto = 13
	Global.UbiPunto = punto_14.global_position
	pass # Replace with function body.


func _on_punto_18_pressed() -> void:
	Global.numpunto = 17
	Global.UbiPunto = punto_18.global_position
	pass # Replace with function body.


func _on_punto_20_pressed() -> void:
	Global.numpunto = 19
	Global.UbiPunto = punto_20.global_position
	pass # Replace with function body.


func _on_punto_21_pressed() -> void:
	Global.numpunto = 20
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
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(0)


	

func _on_punto_2_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(1,true,area)
	print("area ficha : "+ str(area) + " ha salido")
	pass # Replace with function body.


func _on_punto_2_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(1)



func _on_punto_3_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(2,true,area)
	pass # Replace with function body.


func _on_punto_3_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(2)


func _on_punto_4_area_entered(area: Area2D) -> void:

	cambiarEstoPunto(3,true,area)
	pass # Replace with function body.


func _on_punto_4_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(3)


func _on_punto_5_area_entered(area: Area2D) -> void:

	cambiarEstoPunto(4,true,area)
	pass # Replace with function body.


func _on_punto_5_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(4)


func _on_punto_6_area_entered(area: Area2D) -> void:

	cambiarEstoPunto(5,true,area)
	pass # Replace with function body.


func _on_punto_6_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(5)


func _on_punto_7_area_entered(area: Area2D) -> void:

	cambiarEstoPunto(6,true,area)
	pass # Replace with function body.


func _on_punto_7_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(6)


func _on_punto_8_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(7,true,area)


func _on_punto_8_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(7)


func _on_punto_9_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(8,true,area)


func _on_punto_9_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(8)


func _on_punto_10_area_entered(area: Area2D) -> void:
	
	cambiarEstoPunto(9,true,area)


func _on_punto_10_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(9)


func _on_punto_11_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(10,true,area)


func _on_punto_11_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(10)


func _on_punto_12_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(11,true,area)


func _on_punto_12_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(11)


func _on_punto_13_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(12,true,area)


func _on_punto_13_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(12)


func _on_punto_14_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(13,true,area)


func _on_punto_14_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(13)


func _on_punto_15_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(14,true,area)


func _on_punto_15_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(14)


func _on_punto_16_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(15,true,area)


func _on_punto_16_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(15)


func _on_punto_17_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(16,true,area)


func _on_punto_17_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(16)


func _on_punto_18_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(17,true,area)

func _on_punto_18_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(17)


func _on_punto_19_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(18,true,area)


func _on_punto_19_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(18)


func _on_punto_20_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(19,true,area)


func _on_punto_20_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(19)


func _on_punto_21_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(20,true,area)


func _on_punto_21_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(20)

func _on_punto_22_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(21,true,area)


func _on_punto_22_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(21)
		


func _on_punto_23_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(22,true,area)


func _on_punto_23_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(22)


func _on_punto_24_area_entered(area: Area2D) -> void:
	cambiarEstoPunto(23,true,area)


func _on_punto_24_area_exited(area: Area2D) -> void:
	if area.is_in_group("Fichas"):
		cambiarEstadoPunto(23)
