extends Control
@onready var sountrack: AudioStreamPlayer2D = $sountrack

@onready var ganador: Label = $Ganador
@onready var titulo: Label = $Ganaste
@onready var boton_volver: Button = $Button
@onready var estado: Label = $Estado
@onready var boton_revancha: Button = $Revancha

var _revancha_pedida := false


func _ready() -> void:
	sountrack.play()
	estado.text = ""
	boton_revancha.visible = false
	boton_volver.pressed.connect(_on_volver_pressed)

	if Global.cancelada:
		titulo.text = "Cancelled"
		ganador.text = "Draw"
		estado.text = Global.motivo_cancelacion
	elif Global.Empate:
		titulo.text = ""
		ganador.text = ""
	else:
		ganador.text = str(Global.Ganador)
		if Global.modo == Global.Modo.CONTRA_MAQUINA:
			if str(Global.Ganador) == Global.NOMBRE_MAQUINA:
				titulo.text = "You lost"
			else:
				titulo.text = "Victory"
		elif Global.modo == Global.Modo.DEMO:
			titulo.text = "Demo"
		elif Global.modo == Global.Modo.ONLINE:
			if str(Global.Ganador) == Red.nombre_de(Global.equipo_local):
				titulo.text = "Victory"
			else:
				titulo.text = "You lost"
		else:
			titulo.text = "Victory"

	if Global.modo == Global.Modo.ONLINE:
		_configurar_online()


func _configurar_online() -> void:
	if Global.cancelada:
		return
	if not Red.activo() or not Red.en_partida:
		return
	boton_revancha.visible = true
	boton_revancha.pressed.connect(_on_revancha_pressed)
	Red.revancha_actualizada.connect(_on_revancha_actualizada)
	Red.rival_salio.connect(_on_rival_salio)
	_mostrar_estado_revancha(Red.revancha_azul, Red.revancha_rojo)


func _on_revancha_pressed() -> void:
	if _revancha_pedida:
		return
	_revancha_pedida = true
	boton_revancha.disabled = true
	estado.text = "Waiting for the opponent…"
	Red.marcar_revancha_local()


func _on_revancha_actualizada(azul_listo: bool, rojo_listo: bool) -> void:
	_mostrar_estado_revancha(azul_listo, rojo_listo)


func _mostrar_estado_revancha(azul_listo: bool, rojo_listo: bool) -> void:
	var yo_listo := azul_listo if Global.equipo_local == 0 else rojo_listo
	var rival_listo := rojo_listo if Global.equipo_local == 0 else azul_listo
	if rival_listo:
		estado.text = "The opponent accepted. Starting now.…"
	elif yo_listo:
		estado.text = "Waiting for the opponent…"
	else:
		estado.text = ""


func _on_rival_salio(_motivo: String) -> void:
	# La partida ya terminó: no es una cancelación, el rival simplemente se fue.
	boton_revancha.visible = false
	estado.text = "The rival left the room."


func _exit_tree() -> void:
	if Red.revancha_actualizada.is_connected(_on_revancha_actualizada):
		Red.revancha_actualizada.disconnect(_on_revancha_actualizada)
	if Red.rival_salio.is_connected(_on_rival_salio):
		Red.rival_salio.disconnect(_on_rival_salio)


func _on_volver_pressed() -> void:
	Global.Ganador = ""
	Global.Empate = false
	Global.cancelada = false
	Global.motivo_cancelacion = ""
	Global.UbiPunto = null
	Global.numpunto = null
	if Global.modo == Global.Modo.ONLINE:
		Red.salir()
	get_tree().change_scene_to_file("res://Scenes/ui_inicio_juego.tscn")
