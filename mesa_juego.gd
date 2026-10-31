extends Node2D

## QUA - lógica de la partida.
##
## Fuente de verdad:
##   puntos[i]["ocupante"] = índice de ficha o -1
##   fichas[i]["punto"]    = índice de punto o -1
##
## No se usa el motor de física para saber qué punto está ocupado.
## Las colisiones de los Area2D quedan solo como legado visual.

enum Equipo { AZUL, ROJO }
enum Fase { COLOCACION, MOVIMIENTO, ELIMINACION, FIN }
enum EstadoLinea { LIBRE, USADA, ANULADA }

const TOTAL_PUNTOS := 24
const TOTAL_FICHAS := 10
const FICHAS_POR_EQUIPO := 5
const DURACION_MOVIMIENTO := 0.28
const DURACION_CAPTURA := 0.22
const RADIO_CLIC := 32.0
const PENSAR_IA := 0.55          ## pausa para que se vea la jugada de la máquina
const LIMITE_DEMO := 300         ## jugadas sin capturas antes de cerrar la demo

## 20 líneas de 3 puntos. Cada una es un camino de dos aristas del tablero.
const LINEAS := [
	[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11],
	[12, 13, 14], [15, 16, 17], [18, 19, 20], [21, 22, 23],
	[0, 18, 15], [3, 19, 12], [6, 20, 9], [1, 4, 7],
	[10, 13, 16], [8, 21, 11], [5, 22, 14], [2, 23, 17],
	[0, 3, 6], [15, 12, 9], [8, 5, 2], [11, 14, 17],
]

## Puntos conectados para moverse (un solo paso).
const ADYACENTES := [
	[1, 3, 18], [0, 4, 2], [1, 5, 23], [0, 19, 6, 4],
	[3, 7, 5, 1], [4, 8, 2, 22], [3, 20, 7], [6, 8, 4],
	[7, 5, 21], [12, 10, 20], [9, 13, 11], [10, 14, 21],
	[15, 19, 9, 13], [12, 10, 16, 14], [13, 11, 17, 22],
	[18, 12, 16], [15, 13, 17], [16, 14, 23],
	[0, 15, 19], [18, 3, 12, 20], [19, 6, 9],
	[22, 8, 11], [21, 14, 5, 23], [2, 22, 17],
]

@onready var text_turno: Label3D = $textTurno
@onready var nodos_puntos: Array[Area2D] = [
	$Puntos/punto, $Puntos/punto2, $Puntos/punto3, $Puntos/punto4,
	$Puntos/punto5, $Puntos/punto6, $Puntos/punto7, $Puntos/punto8,
	$Puntos/punto9, $Puntos/punto10, $Puntos/punto11, $Puntos/punto12,
	$Puntos/punto13, $Puntos/punto14, $Puntos/punto15, $Puntos/punto16,
	$Puntos/punto17, $Puntos/punto18, $Puntos/punto19, $Puntos/punto20,
	$Puntos/punto21, $Puntos/punto22, $Puntos/punto23, $Puntos/punto24,
]
@onready var nodos_fichas: Array[Area2D] = [
	$EquipoAzul/fichaAzulArea, $EquipoAzul/fichaAzulArea2,
	$EquipoAzul/fichaAzulArea3, $EquipoAzul/fichaAzulArea4,
	$EquipoAzul/fichaAzulArea5, $EquipoRojo/fichaRojaArea,
	$EquipoRojo/fichaRojaArea2, $EquipoRojo/fichaRojaArea3,
	$EquipoRojo/fichaRojaArea4, $EquipoRojo/fichaRojaArea5,
]

var puntos: Array[Dictionary] = []
var fichas: Array[Dictionary] = []
var estados_lineas: Array[int] = []
var resaltados: Array[Polygon2D] = []

var fase: int = Fase.COLOCACION
var equipo_actual: int = Equipo.AZUL
var equipo_con_qua: int = Equipo.AZUL
var capturas_pendientes: int = 0
var colocadas: int = 0

var ficha_sel: int = -1
var punto_pre: int = -1
var procesando: bool = false
var ia_activa: bool = false
var sin_progreso_ia: int = 0                   ## jugadas de la IA que no cambiaron nada
var jugadas_sin_captura_demo: int = 0           ## corte de la demo (sin regla de repetición)
var reservas_ia: int = 0                       ## veces que la IA necesitó el plan de reserva
var mover_automatico: bool = true              ## permite apagar la IA (pruebas)
var cambiar_escena_al_terminar: bool = true    ## permite apagar el cambio de escena

## Red (solo en Global.Modo.ONLINE).
var _esperando_red: bool = false               ## el cliente espera el snapshot del host
var _red_sello: int = 0                        ## invalida timeouts viejos
var _intencion_pendiente: Dictionary = {}      ## jugada del cliente mientras el host anima
var _fin_remoto: bool = false                  ## el cliente ya mostró el fin

var overlay: Control
var etiqueta: Label
@onready var soundtrack: AudioStreamPlayer2D = $soundtrack
@onready var menu_pausa: Control = $MenuPausa


func _ready() -> void:
	soundtrack.play()
	Global.Ganador = ""
	Global.Empate = false
	Global.cancelada = false
	Global.motivo_cancelacion = ""
	Global.UbiPunto = null
	Global.numpunto = null

	_construir_modelo()
	_crear_resaltados()
	_crear_etiqueta()
	_crear_overlay()

	_preparar_turno_inicial()
	_configurar_red()
	_actualizar_estado_visual()
	_continuar_flujo()


# ---------------------------------------------------------------------------
# Construcción del modelo
# ---------------------------------------------------------------------------

func _construir_modelo() -> void:
	for i in TOTAL_PUNTOS:
		var area: Area2D = nodos_puntos[i]
		var boton: Button = _boton_de(area)
		var centro: Vector2 = area.global_position
		if boton != null:
			centro = boton.get_global_rect().get_center()
		puntos.append({
			"nodo": area,
			"boton": boton,
			"centro": centro,
			"ocupante": -1,
		})

	for i in TOTAL_FICHAS:
		var area: Area2D = nodos_fichas[i]
		var boton: Button = _boton_de(area)
		var offset := Vector2.ZERO
		if boton != null:
			offset = boton.get_global_rect().get_center() - area.global_position
		fichas.append({
			"nodo": area,
			"boton": boton,
			"equipo": Equipo.AZUL if i < FICHAS_POR_EQUIPO else Equipo.ROJO,
			"punto": -1,
			"viva": true,
			"offset": offset,
			"inicio": area.global_position,
		})

	estados_lineas.resize(LINEAS.size())
	estados_lineas.fill(EstadoLinea.LIBRE)


func _boton_de(nodo: Node) -> Button:
	for hijo in nodo.get_children():
		if hijo is Button:
			return hijo
	return null


func _crear_resaltados() -> void:
	var circulo := PackedVector2Array()
	for k in 24:
		var angulo := TAU * float(k) / 24.0
		circulo.append(Vector2(cos(angulo), sin(angulo)) * 11.0)
	for i in TOTAL_PUNTOS:
		var poligono := Polygon2D.new()
		poligono.polygon = circulo
		poligono.color = Color(1.0, 0.85, 0.2, 0.55)
		poligono.position = $Puntos.to_local(puntos[i]["centro"])
		poligono.visible = false
		$Puntos.add_child(poligono)
		resaltados.append(poligono)


func _crear_etiqueta() -> void:
	etiqueta = Label.new()
	etiqueta.position = Vector2(24, 14)
	etiqueta.size = Vector2(1050, 60)
	etiqueta.add_theme_font_size_override("font_size", 26)
	etiqueta.add_theme_color_override("font_color", Color(1, 1, 1))
	etiqueta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	etiqueta.add_theme_constant_override("shadow_offset_x", 2)
	etiqueta.add_theme_constant_override("shadow_offset_y", 2)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.z_index = 100
	add_child(etiqueta)


func _crear_overlay() -> void:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for p in puntos:
		var c: Vector2 = to_local(p["centro"])
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
		max_x = max(max_x, c.x)
		max_y = max(max_y, c.y)

	overlay = Control.new()
	overlay.name = "EntradaTablero"
	overlay.position = Vector2(min_x - 45.0, min_y - 45.0)
	overlay.size = Vector2(max_x - min_x + 90.0, max_y - min_y + 90.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	overlay.gui_input.connect(_on_tablero_gui_input)
	add_child(overlay)
	#move_child(overlay, menu_eliminar.get_index())


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _on_tablero_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_clic_tablero(overlay.get_global_mouse_position())


func _clic_tablero(pos: Vector2) -> void:
	var mejor := -1
	var mejor_dist := INF
	for i in TOTAL_PUNTOS:
		var d: float = pos.distance_squared_to(puntos[i]["centro"])
		if d < mejor_dist:
			mejor_dist = d
			mejor = i
	if mejor == -1 or mejor_dist > RADIO_CLIC * RADIO_CLIC:
		return
	_clic_punto(mejor)


func _clic_punto(idx: int) -> void:
	if _bloqueado() or fase == Fase.FIN:
		return

	var ocupante: int = puntos[idx]["ocupante"]

	if fase == Fase.ELIMINACION:
		var rival := _oponente(equipo_con_qua)
		if ocupante != -1 and fichas[ocupante]["equipo"] == rival:
			_capturar(ocupante)
		else:
			_anunciar("Choose a game piece %s to delete." % _nombre(rival))
		return

	if fase == Fase.COLOCACION:
		if ocupante != -1:
			_anunciar("That spot is already taken.")
			return
		if ficha_sel != -1:
			_colocar(ficha_sel, idx)
		else:
			_limpiar_seleccion()
			punto_pre = idx
			_actualizar_estado_visual()
		return

	# Fase de movimiento
	if ocupante != -1:
		if fichas[ocupante]["equipo"] == equipo_actual:
			if punto_pre != -1 and ficha_sel == -1:
				_intentar_mover(ocupante, punto_pre)
			else:
				_seleccionar_ficha(ocupante)
		else:
			_anunciar("That piece belongs to the opponent.")
	else:
		if ficha_sel != -1:
			_intentar_mover(ficha_sel, idx)
		else:
			_limpiar_seleccion()
			punto_pre = idx
			_actualizar_estado_visual()


func _clic_ficha(idx: int) -> void:
	if _bloqueado() or fase == Fase.FIN or fase == Fase.ELIMINACION:
		return
	if fichas[idx]["equipo"] != equipo_actual:
		_anunciar("That piece isn't yours.")
		return

	if fase == Fase.COLOCACION:
		if fichas[idx]["punto"] != -1:
			return
		if punto_pre != -1:
			_colocar(idx, punto_pre)
		else:
			_seleccionar_ficha(idx)
		return

	if fichas[idx]["punto"] == -1:
		return
	if punto_pre != -1:
		_intentar_mover(idx, punto_pre)
	else:
		_seleccionar_ficha(idx)


# ---------------------------------------------------------------------------
# Selección y ayudas visuales
# ---------------------------------------------------------------------------

func _seleccionar_ficha(idx: int) -> void:
	if ficha_sel == idx:
		_limpiar_seleccion()
		_actualizar_estado_visual()
		return
	_limpiar_seleccion()
	ficha_sel = idx
	var nodo = fichas[idx]["nodo"]
	if is_instance_valid(nodo):
		nodo.modulate = Color(1.35, 1.35, 0.7)
	_mostrar_destinos(idx)
	_actualizar_estado_visual()


func _limpiar_seleccion() -> void:
	for f in fichas:
		var nodo = f["nodo"]
		if is_instance_valid(nodo):
			nodo.modulate = Color.WHITE
	_ocultar_resaltados()
	ficha_sel = -1
	punto_pre = -1


func _mostrar_destinos(idx: int) -> void:
	_ocultar_resaltados()
	if fase == Fase.COLOCACION:
		for p in TOTAL_PUNTOS:
			if puntos[p]["ocupante"] == -1:
				resaltados[p].visible = true
		return
	if fase == Fase.MOVIMIENTO:
		var origen: int = fichas[idx]["punto"]
		if origen == -1:
			return
		for destino in ADYACENTES[origen]:
			if puntos[destino]["ocupante"] == -1:
				resaltados[destino].visible = true


func _ocultar_resaltados() -> void:
	for r in resaltados:
		r.visible = false


# ---------------------------------------------------------------------------
# Colocación
# ---------------------------------------------------------------------------

func _colocar(ficha_idx: int, punto_idx: int) -> void:
	if Global.modo == Global.Modo.ONLINE and Red.es_cliente():
		if not _validar_colocacion(ficha_idx, punto_idx):
			return
		_limpiar_seleccion()
		_enviar_intencion({"t": "colocar", "f": ficha_idx, "p": punto_idx})
		return
	await _aplicar_colocacion(ficha_idx, punto_idx)


func _validar_colocacion(ficha_idx: int, punto_idx: int) -> bool:
	if fase != Fase.COLOCACION or procesando:
		return false
	if ficha_idx < 0 or ficha_idx >= TOTAL_FICHAS:
		return false
	if punto_idx < 0 or punto_idx >= TOTAL_PUNTOS:
		return false
	if fichas[ficha_idx]["equipo"] != equipo_actual:
		return false
	if fichas[ficha_idx]["punto"] != -1:
		return false
	if puntos[punto_idx]["ocupante"] != -1:
		_anunciar("That spot is already occupied.")
		return false
	return true


func _aplicar_colocacion(ficha_idx: int, punto_idx: int) -> bool:
	if not _validar_colocacion(ficha_idx, punto_idx):
		return false

	procesando = true
	_limpiar_seleccion()

	# Mutar el modelo ANTES de animar: en red se difunde el estado final.
	puntos[punto_idx]["ocupante"] = ficha_idx
	fichas[ficha_idx]["punto"] = punto_idx
	colocadas += 1

	# Regla 3: cualquier línea formada durante la colocación (incluida la ficha 10)
	# queda anulada para el resto de la partida.
	var anuladas := detectar_lineas(equipo_actual, true)

	if colocadas >= TOTAL_FICHAS:
		fase = Fase.MOVIMIENTO

	equipo_actual = _oponente(equipo_actual)
	_actualizar_estado_visual()
	_comprobar_pasos()
	_difundir_si_host({"t": "colocar", "f": ficha_idx, "p": punto_idx})
	if anuladas > 0:
		_anunciar("QUA! during installation: %d línea(s) anulada(s)." % anuladas)

	var nodo: Area2D = fichas[ficha_idx]["nodo"]
	var destino: Vector2 = puntos[punto_idx]["centro"] - fichas[ficha_idx]["offset"]
	if is_instance_valid(nodo):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(nodo, "global_position", destino, DURACION_MOVIMIENTO)
		await tween.finished
		nodo.global_position = destino

	procesando = false
	_continuar_flujo()
	_procesar_pendiente()
	return true


# ---------------------------------------------------------------------------
# Movimiento
# ---------------------------------------------------------------------------

func _intentar_mover(ficha_idx: int, destino_idx: int) -> void:
	if Global.modo == Global.Modo.ONLINE and Red.es_cliente():
		if not _validar_movimiento(ficha_idx, destino_idx):
			return
		_limpiar_seleccion()
		_enviar_intencion({"t": "mover", "f": ficha_idx, "p": destino_idx})
		return
	await _aplicar_movimiento(ficha_idx, destino_idx)


func _validar_movimiento(ficha_idx: int, destino_idx: int) -> bool:
	if fase != Fase.MOVIMIENTO or procesando:
		return false
	if ficha_idx < 0 or ficha_idx >= TOTAL_FICHAS:
		return false
	if destino_idx < 0 or destino_idx >= TOTAL_PUNTOS:
		return false
	if fichas[ficha_idx]["equipo"] != equipo_actual:
		return false
	if not fichas[ficha_idx]["viva"]:
		return false

	var origen: int = fichas[ficha_idx]["punto"]
	if origen == -1:
		_limpiar_seleccion()
		_actualizar_estado_visual()
		_anunciar("That piece is not on the board.")
		return false
	if not (destino_idx in ADYACENTES[origen]):
		_limpiar_seleccion()
		_actualizar_estado_visual()
		_anunciar("Movement not permitted: only to a connected point.")
		return false
	if puntos[destino_idx]["ocupante"] != -1:
		_limpiar_seleccion()
		_actualizar_estado_visual()
		_anunciar("That spot is occupied.")
		return false
	return true


func _aplicar_movimiento(ficha_idx: int, destino_idx: int) -> bool:
	if not _validar_movimiento(ficha_idx, destino_idx):
		return false

	procesando = true
	_limpiar_seleccion()

	var origen: int = fichas[ficha_idx]["punto"]
	puntos[origen]["ocupante"] = -1
	puntos[destino_idx]["ocupante"] = ficha_idx
	fichas[ficha_idx]["punto"] = destino_idx

	var nuevas := detectar_lineas(equipo_actual, false)
	if nuevas > 0:
		equipo_con_qua = equipo_actual
		fase = Fase.ELIMINACION
	else:
		equipo_actual = _oponente(equipo_actual)

	_actualizar_estado_visual()
	_comprobar_pasos()
	_difundir_si_host({"t": "mover", "f": ficha_idx, "p": destino_idx})

	var nodo: Area2D = fichas[ficha_idx]["nodo"]
	var destino: Vector2 = puntos[destino_idx]["centro"] - fichas[ficha_idx]["offset"]
	if is_instance_valid(nodo):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(nodo, "global_position", destino, DURACION_MOVIMIENTO)
		await tween.finished
		nodo.global_position = destino

	procesando = false
	_continuar_flujo()
	_procesar_pendiente()
	return true


# ---------------------------------------------------------------------------
# Detección de líneas
# ---------------------------------------------------------------------------

func detectar_lineas(equipo: int, anular: bool) -> int:
	var afectadas := 0
	for i in LINEAS.size():
		if estados_lineas[i] != EstadoLinea.LIBRE:
			continue
		var linea: Array = LINEAS[i]
		if _equipo_en(linea[0]) == equipo \
		and _equipo_en(linea[1]) == equipo \
		and _equipo_en(linea[2]) == equipo:
			if anular:
				estados_lineas[i] = EstadoLinea.ANULADA
			else:
				estados_lineas[i] = EstadoLinea.USADA
			afectadas += 1

	if not anular:
		capturas_pendientes += afectadas
	return afectadas


func _equipo_en(p: int) -> int:
	var ocupante: int = puntos[p]["ocupante"]
	if ocupante == -1:
		return -1
	return fichas[ocupante]["equipo"]


# ---------------------------------------------------------------------------
# Máquina
# ---------------------------------------------------------------------------

func _preparar_turno_inicial() -> void:
	jugadas_sin_captura_demo = 0
	if Global.modo == Global.Modo.DEMO:
		equipo_actual = Equipo.AZUL
		return
	if Global.modo == Global.Modo.CONTRA_MAQUINA:
		# La máquina siempre empieza, sin importar el color que elija el jugador.
		equipo_actual = _equipo_maquina()
		return
	if Global.modo == Global.Modo.ONLINE:
		# El host siempre es Azul y empieza.
		equipo_actual = Equipo.AZUL
		return
	equipo_actual = Equipo.AZUL


func _equipo_maquina() -> int:
	return Equipo.ROJO if Global.bando_humano == Equipo.AZUL else Equipo.AZUL


func _es_maquina(equipo: int) -> bool:
	if Global.modo == Global.Modo.DEMO:
		return true
	if Global.modo != Global.Modo.CONTRA_MAQUINA:
		return false
	return equipo == _equipo_maquina()


func _bloqueado() -> bool:
	if procesando or ia_activa or _esperando_red:
		return true
	if Global.modo == Global.Modo.ONLINE and not _es_mi_turno():
		return true
	return false


## En online, ¿le toca a este jugador? (Azul = host, Rojo = cliente).
func _es_mi_turno() -> bool:
	if Global.modo != Global.Modo.ONLINE:
		return true
	if not Red.activo():
		return true
	return _actor_actual() == Global.equipo_local


## Se llama al terminar cualquier jugada. Si le toca a la máquina, juega.
##
## No hay bucle: cada jugada aplicada vuelve a llamar a este método, así que
## el flujo se re-dispara solo y nunca queda un `while` esperando para siempre.
func _continuar_flujo() -> void:
	if not mover_automatico:
		return
	if ia_activa or procesando or fase == Fase.FIN:
		return
	if not _es_maquina(_actor_actual()):
		return
	_jugar_turno_maquina()


## De quién es el turno ahora mismo.
func _actor_actual() -> int:
	return equipo_con_qua if fase == Fase.ELIMINACION else equipo_actual


## Una sola jugada de la máquina, con una pausa para que se vea.
func _jugar_turno_maquina() -> void:
	ia_activa = true
	if etiqueta != null:
		etiqueta.text = "%s is thinking…" % _nombre(_actor_actual())
		etiqueta.modulate = Color(1.0, 0.85, 0.4)

	await get_tree().create_timer(PENSAR_IA).timeout
	ia_activa = false

	if fase == Fase.FIN or procesando:
		return

	# Recalcular el turno DESPUÉS de la pausa: durante la espera pudo cambiar.
	var actor := _actor_actual()
	if not _es_maquina(actor):
		return

	var plan: Dictionary = IAQua.decidir(self, actor)
	if not IAQua.es_legal(self, actor, plan):
		reservas_ia += 1
		plan = _plan_de_reserva(actor)
	elif String(plan.get("accion", "pasar")) == "pasar":
		plan = _plan_de_reserva(actor)

	if String(plan.get("accion", "pasar")) == "pasar":
		_comprobar_pasos()
		# Si el turno pasó al otro bando, que el flujo siga (puede ser máquina).
		if fase != Fase.FIN and not procesando:
			_continuar_flujo()
		return

	var antes := _firma_estado()
	match String(plan["accion"]):
		"colocar":
			await _colocar(int(plan["ficha"]), int(plan["punto"]))
		"mover":
			await _intentar_mover(int(plan["ficha"]), int(plan["punto"]))
		"capturar":
			await _capturar(int(plan["ficha"]))

	# Demo: sin regla de repetición, dos máquinas pueden mover para siempre.
	# Se corta por cantidad de jugadas sin capturas para que la demo siempre cierre.
	if Global.modo == Global.Modo.DEMO:
		if String(plan["accion"]) == "capturar":
			jugadas_sin_captura_demo = 0
		else:
			jugadas_sin_captura_demo += 1
			if jugadas_sin_captura_demo >= LIMITE_DEMO:
				jugadas_sin_captura_demo = 0
				_terminar("", "Demo: %d Moves without captures result in a draw." % LIMITE_DEMO)
				return

	# La jugada debería haber cambiado el estado y re-disparado el flujo.
	# Si no cambió nada, reintentar un par de veces y luego ceder el turno.
	if _firma_estado() == antes:
		sin_progreso_ia += 1
		if sin_progreso_ia < 3:
			_continuar_flujo()
		else:
			sin_progreso_ia = 0
			_comprobar_pasos()
	else:
		sin_progreso_ia = 0


## Huella del estado para detectar jugadas que no hicieron nada.
func _firma_estado() -> Array:
	var ocupados := 0
	for p in puntos:
		if p["ocupante"] != -1:
			ocupados += 1
	return [fase, equipo_actual, equipo_con_qua, colocadas, capturas_pendientes, ocupados]


## Red de seguridad: si la IA devuelve algo ilegal, se usa cualquier jugada válida.
func _plan_de_reserva(actor: int) -> Dictionary:
	if fase == Fase.COLOCACION:
		for i in TOTAL_FICHAS:
			if fichas[i]["equipo"] == actor and fichas[i]["punto"] == -1:
				for p in TOTAL_PUNTOS:
					if puntos[p]["ocupante"] == -1:
						return {"accion": "colocar", "ficha": i, "punto": p}
	elif fase == Fase.ELIMINACION:
		for i in TOTAL_FICHAS:
			if fichas[i]["viva"] and fichas[i]["equipo"] != actor and fichas[i]["punto"] != -1:
				return {"accion": "capturar", "ficha": i}
	else:
		for i in TOTAL_FICHAS:
			if not fichas[i]["viva"] or fichas[i]["equipo"] != actor:
				continue
			var origen: int = fichas[i]["punto"]
			if origen == -1:
				continue
			for destino in ADYACENTES[origen]:
				if puntos[destino]["ocupante"] == -1:
					return {"accion": "mover", "ficha": i, "punto": destino}
	return {"accion": "pasar"}


# ---------------------------------------------------------------------------
# Captura y victoria
# ---------------------------------------------------------------------------

func _capturar(ficha_idx: int) -> void:
	if Global.modo == Global.Modo.ONLINE and Red.es_cliente():
		if not _validar_captura(ficha_idx):
			return
		_limpiar_seleccion()
		_enviar_intencion({"t": "capturar", "f": ficha_idx, "p": -1})
		return
	await _aplicar_captura(ficha_idx)


func _validar_captura(ficha_idx: int) -> bool:
	if fase != Fase.ELIMINACION or procesando:
		return false
	if ficha_idx < 0 or ficha_idx >= TOTAL_FICHAS:
		return false
	if not fichas[ficha_idx]["viva"]:
		return false
	if fichas[ficha_idx]["equipo"] != _oponente(equipo_con_qua):
		return false
	return true


func _aplicar_captura(ficha_idx: int) -> bool:
	if not _validar_captura(ficha_idx):
		return false

	procesando = true
	_limpiar_seleccion()

	var punto: int = fichas[ficha_idx]["punto"]
	if punto != -1:
		puntos[punto]["ocupante"] = -1
	fichas[ficha_idx]["viva"] = false
	fichas[ficha_idx]["punto"] = -1
	capturas_pendientes -= 1

	var termino := _comprobar_victoria()
	if not termino:
		if capturas_pendientes > 0:
			_actualizar_estado_visual()
		else:
			fase = Fase.MOVIMIENTO
			equipo_actual = _oponente(equipo_con_qua)
			_actualizar_estado_visual()
			_comprobar_pasos()

	_difundir_si_host({"t": "capturar", "f": ficha_idx, "p": -1})

	var nodo: Area2D = fichas[ficha_idx]["nodo"]
	if is_instance_valid(nodo):
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(nodo, "modulate:a", 0.0, DURACION_CAPTURA)
		tween.tween_property(nodo, "scale", nodo.scale * 0.2, DURACION_CAPTURA)
		await tween.finished
		nodo.queue_free()
	fichas[ficha_idx]["nodo"] = null
	fichas[ficha_idx]["boton"] = null

	procesando = false
	if not termino:
		_continuar_flujo()
	_procesar_pendiente()
	return true


func _comprobar_victoria() -> bool:
	var rival := _oponente(equipo_con_qua)
	if _contar_vivas(rival) <= 2:
		_terminar(_nombre(equipo_con_qua))
		return true
	if _contar_vivas(equipo_con_qua) <= 2:
		_terminar(_nombre(rival))
		return true
	return false


func _contar_vivas(equipo: int) -> int:
	var total := 0
	for f in fichas:
		if f["viva"] and f["equipo"] == equipo:
			total += 1
	return total


func _tiene_movimientos(equipo: int) -> bool:
	for f in fichas:
		if not f["viva"] or f["equipo"] != equipo:
			continue
		var p: int = f["punto"]
		if p == -1:
			continue
		for d in ADYACENTES[p]:
			if puntos[d]["ocupante"] == -1:
				return true
	return false


func _comprobar_pasos() -> void:
	if fase != Fase.MOVIMIENTO:
		return
	if _tiene_movimientos(equipo_actual):
		return

	var otro := _oponente(equipo_actual)
	if _tiene_movimientos(otro):
		var sin_mov := _nombre(equipo_actual)
		equipo_actual = otro
		_actualizar_estado_visual()
		_anunciar("%s Has no moves: pass the turn." % sin_mov)
	else:
		_terminar("")


func _terminar(ganador: String = "", motivo: String = "") -> void:
	if fase == Fase.FIN:
		return
	fase = Fase.FIN
	procesando = true
	_limpiar_seleccion()
	Global.UbiPunto = null
	Global.numpunto = null

	if ganador == "":
		Global.Empate = true
		Global.Ganador = ""
		if etiqueta != null:
			_anunciar(motivo if motivo != "" else "Draw: neither player has any possible moves.")
	else:
		Global.Empate = false
		Global.Ganador = ganador
		if etiqueta != null:
			_anunciar("victory %s." % ganador)

	await get_tree().create_timer(1.2).timeout
	if cambiar_escena_al_terminar:
		get_tree().change_scene_to_file("res://Scenes/juego_terminado.tscn")


# ---------------------------------------------------------------------------
# Red (LAN / IP directa)
# ---------------------------------------------------------------------------

func _configurar_red() -> void:
	if Global.modo != Global.Modo.ONLINE:
		return
	mover_automatico = false
	Red.registrar_mesa(self)
	Red.jugada_recibida.connect(_on_jugada_recibida)
	Red.rival_salio.connect(_on_rival_salio)


func _exit_tree() -> void:
	if Global.modo != Global.Modo.ONLINE:
		return
	if Red.jugada_recibida.is_connected(_on_jugada_recibida):
		Red.jugada_recibida.disconnect(_on_jugada_recibida)
	if Red.rival_salio.is_connected(_on_rival_salio):
		Red.rival_salio.disconnect(_on_rival_salio)
	Red.olvidar_mesa(self)


## El cliente manda la jugada y espera el snapshot. Si el host no responde
## (por ejemplo, rechazó la jugada en silencio), se pide el estado y se sigue.
func _enviar_intencion(accion: Dictionary) -> void:
	_esperando_red = true
	_red_sello += 1
	var sello := _red_sello
	Red.enviar_intencion(accion)
	await get_tree().create_timer(3.0).timeout
	if _esperando_red and _red_sello == sello:
		_esperando_red = false
		Red.pedir_estado()


func _on_jugada_recibida(accion: Dictionary, snapshot: Dictionary) -> void:
	if Global.modo != Global.Modo.ONLINE or Red.es_host():
		return
	_red_sello += 1
	_esperando_red = false
	cargar_estado_red(snapshot)
	_limpiar_seleccion()
	await _refrescar_desde_modelo(accion)
	_actualizar_estado_visual()
	if fase == Fase.FIN:
		_mostrar_fin_remoto()


func _on_rival_salio(motivo: String) -> void:
	if Global.modo != Global.Modo.ONLINE or fase == Fase.FIN:
		return
	fase = Fase.FIN
	procesando = true
	_esperando_red = false
	_intencion_pendiente = {}
	Global.Empate = true
	Global.Ganador = ""
	Global.cancelada = true
	Global.motivo_cancelacion = motivo
	_limpiar_seleccion()
	_anunciar(motivo)
	await get_tree().create_timer(1.2).timeout
	if cambiar_escena_al_terminar and is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/juego_terminado.tscn")


func _mostrar_fin_remoto() -> void:
	if _fin_remoto:
		return
	_fin_remoto = true
	if Global.Empate:
		_anunciar("draw.")
	elif str(Global.Ganador) != "":
		_anunciar("victory %s." % Global.Ganador)
	await get_tree().create_timer(1.2).timeout
	if cambiar_escena_al_terminar and is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/juego_terminado.tscn")


## Snapshot completo del estado, para que el cliente quede idéntico al host.
func estado_red() -> Dictionary:
	var pts: Array = []
	for p in puntos:
		pts.append(int(p["ocupante"]))
	var fs: Array = []
	for f in fichas:
		fs.append({"punto": int(f["punto"]), "viva": bool(f["viva"])})
	return {
		"fase": fase,
		"equipo_actual": equipo_actual,
		"equipo_con_qua": equipo_con_qua,
		"capturas_pendientes": capturas_pendientes,
		"colocadas": colocadas,
		"estados_lineas": estados_lineas.duplicate(),
		"puntos": pts,
		"fichas": fs,
		"ganador": str(Global.Ganador),
		"empate": bool(Global.Empate),
	}


func cargar_estado_red(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	fase = int(snapshot.get("fase", fase))
	equipo_actual = int(snapshot.get("equipo_actual", equipo_actual))
	equipo_con_qua = int(snapshot.get("equipo_con_qua", equipo_con_qua))
	capturas_pendientes = int(snapshot.get("capturas_pendientes", capturas_pendientes))
	colocadas = int(snapshot.get("colocadas", colocadas))

	var lineas: Array = snapshot.get("estados_lineas", [])
	for i in mini(lineas.size(), estados_lineas.size()):
		estados_lineas[i] = int(lineas[i])

	var pts: Array = snapshot.get("puntos", [])
	for i in mini(pts.size(), puntos.size()):
		puntos[i]["ocupante"] = int(pts[i])

	var fs: Array = snapshot.get("fichas", [])
	for i in mini(fs.size(), fichas.size()):
		var d: Dictionary = fs[i]
		fichas[i]["punto"] = int(d.get("punto", -1))
		fichas[i]["viva"] = bool(d.get("viva", true))

	Global.Ganador = str(snapshot.get("ganador", ""))
	Global.Empate = bool(snapshot.get("empate", false))


## Reproduce en la vista la acción que acaba de aplicar el host.
func _refrescar_desde_modelo(accion: Dictionary) -> void:
	var t := String(accion.get("t", ""))
	var f := int(accion.get("f", -1))
	var p := int(accion.get("p", -1))

	if t == "capturar" and f >= 0 and f < TOTAL_FICHAS:
		var nodo: Area2D = fichas[f]["nodo"]
		if is_instance_valid(nodo):
			procesando = true
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(nodo, "modulate:a", 0.0, DURACION_CAPTURA)
			tween.tween_property(nodo, "scale", nodo.scale * 0.2, DURACION_CAPTURA)
			await tween.finished
			nodo.queue_free()
		fichas[f]["nodo"] = null
		fichas[f]["boton"] = null
		procesando = false
		return

	if (t == "colocar" or t == "mover") and f >= 0 and f < TOTAL_FICHAS and p >= 0:
		var nodo2: Area2D = fichas[f]["nodo"]
		if is_instance_valid(nodo2):
			procesando = true
			var destino: Vector2 = puntos[p]["centro"] - fichas[f]["offset"]
			var tween2 := create_tween()
			tween2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween2.tween_property(nodo2, "global_position", destino, DURACION_MOVIMIENTO)
			await tween2.finished
			nodo2.global_position = destino
			procesando = false
		return

	_colocar_todas_en_su_lugar()


## Resincronización completa, sin animación.
func _colocar_todas_en_su_lugar() -> void:
	for i in TOTAL_FICHAS:
		var nodo = fichas[i]["nodo"]
		if not bool(fichas[i]["viva"]):
			if is_instance_valid(nodo):
				nodo.queue_free()
			fichas[i]["nodo"] = null
			fichas[i]["boton"] = null
			continue
		if not is_instance_valid(nodo):
			continue
		var p := int(fichas[i]["punto"])
		if p == -1:
			nodo.global_position = fichas[i]["inicio"]
		else:
			nodo.global_position = puntos[p]["centro"] - fichas[i]["offset"]
		nodo.modulate = Color.WHITE
		nodo.scale = Vector2.ONE


# ---------------------------------------------------------------------------
# Intenciones (host autoritativo)
# ---------------------------------------------------------------------------

## El host recibe acá las jugadas del cliente.
func recibir_intencion(accion: Dictionary, id_remoto: int) -> void:
	if Global.modo != Global.Modo.ONLINE or not Red.es_host():
		return
	if not Red.en_partida or fase == Fase.FIN:
		return
	if Red.equipo_de(id_remoto) != _actor_actual():
		Red.enviar_estado_a(id_remoto)
		return
	if procesando or ia_activa:
		_intencion_pendiente = {"accion": accion.duplicate(true), "id": id_remoto}
		return
	_ejecutar_intencion(accion, id_remoto)


func _ejecutar_intencion(accion: Dictionary, id_remoto: int) -> void:
	var ok := false
	match String(accion.get("t", "")):
		"colocar":
			ok = await _aplicar_colocacion(int(accion.get("f", -1)), int(accion.get("p", -1)))
		"mover":
			ok = await _aplicar_movimiento(int(accion.get("f", -1)), int(accion.get("p", -1)))
		"capturar":
			ok = await _aplicar_captura(int(accion.get("f", -1)))
	if not ok:
		Red.enviar_estado_a(id_remoto)
	_procesar_pendiente()


func _procesar_pendiente() -> void:
	if _intencion_pendiente.is_empty():
		return
	if procesando or ia_activa or fase == Fase.FIN:
		return
	var pendiente := _intencion_pendiente
	_intencion_pendiente = {}
	_ejecutar_intencion(pendiente["accion"], int(pendiente["id"]))


func _difundir_si_host(accion: Dictionary) -> void:
	if Global.modo != Global.Modo.ONLINE:
		return
	if not Red.es_host() or not Red.en_partida:
		return
	Red.difundir(accion, estado_red())


# ---------------------------------------------------------------------------
# Texto de estado
# ---------------------------------------------------------------------------

func _actualizar_estado_visual() -> void:
	if etiqueta == null:
		return

	var actor := equipo_con_qua if fase == Fase.ELIMINACION else equipo_actual
	if fase != Fase.FIN and _es_maquina(actor):
		text_turno.text = _nombre(actor)
		text_turno.modulate = _color(actor)
		etiqueta.text = "%s is thinking…" % _nombre(actor)
		etiqueta.modulate = Color(1.0, 0.85, 0.4)
		return

	if fase != Fase.FIN and Global.modo == Global.Modo.ONLINE and not _es_mi_turno():
		text_turno.text = _nombre(actor)
		text_turno.modulate = _color(actor)
		etiqueta.text = "Turn of %s…" % _nombre(actor)
		etiqueta.modulate = Color(0.8, 0.8, 0.8)
		return

	var nombre := _nombre(equipo_actual)
	var color := _color(equipo_actual)

	match fase:
		Fase.COLOCACION:
			text_turno.text = nombre
			text_turno.modulate = color
			if ficha_sel != -1:
				etiqueta.text = "%s: I chose an empty spot." % nombre
			elif punto_pre != -1:
				etiqueta.text = "%s: Choose a tile from your tray." % nombre
			else:
				etiqueta.text = "%s: Choose a piece to place." % nombre
		Fase.MOVIMIENTO:
			text_turno.text = nombre
			text_turno.modulate = color
			if ficha_sel != -1:
				etiqueta.text = "%s: I chose a connected, empty point." % nombre
			elif punto_pre != -1:
				etiqueta.text = "%s: Choose a piece to move to that spot." % nombre
			else:
				etiqueta.text = "%s: Choose a piece to move." % nombre
		Fase.ELIMINACION:
			var n := _nombre(equipo_con_qua)
			text_turno.text = n
			text_turno.modulate = _color(equipo_con_qua)
			etiqueta.text = "¡QUA! %s: choose a piece %s to delete (%d captura/s pendiente/s)." % [
				n, _nombre(_oponente(equipo_con_qua)), capturas_pendientes
			]
		Fase.FIN:
			etiqueta.text = "Game over."

	etiqueta.modulate = Color.WHITE


func _anunciar(mensaje: String) -> void:
	if etiqueta == null:
		return
	etiqueta.text = mensaje
	etiqueta.modulate = Color(1.0, 0.85, 0.4)


func _nombre(equipo: int) -> String:
	if equipo == Equipo.AZUL:
		var n := str(Global.NameP1).strip_edges()
		return n if n != "" else "Blue"
	var n2 := str(Global.NameP2).strip_edges()
	return n2 if n2 != "" else "Red"


func _color(equipo: int) -> Color:
	if equipo == Equipo.AZUL:
		return Color(0.35, 0.65, 1.0)
	return Color(1.0, 0.35, 0.35)


func _oponente(equipo: int) -> int:
	return Equipo.ROJO if equipo == Equipo.AZUL else Equipo.AZUL


# ---------------------------------------------------------------------------
# Compatibilidad con las conexiones de MesaJuego.tscn
# ---------------------------------------------------------------------------

func _on_punto_1_pressed() -> void: _clic_punto(0)
func _on_punto_2_pressed() -> void: _clic_punto(1)
func _on_punto_3_pressed() -> void: _clic_punto(2)
func _on_punto_4_pressed() -> void: _clic_punto(3)
func _on_punto_5_pressed() -> void: _clic_punto(4)
func _on_punto_6_pressed() -> void: _clic_punto(5)
func _on_punto_7_pressed() -> void: _clic_punto(6)
func _on_punto_8_pressed() -> void: _clic_punto(7)
func _on_punto_9_pressed() -> void: _clic_punto(8)
func _on_punto_10_pressed() -> void: _clic_punto(9)
func _on_punto_11_pressed() -> void: _clic_punto(10)
func _on_punto_12_pressed() -> void: _clic_punto(11)
func _on_punto_13_pressed() -> void: _clic_punto(12)
func _on_punto_14_pressed() -> void: _clic_punto(13)
func _on_punto_15_pressed() -> void: _clic_punto(14)
func _on_punto_16_pressed() -> void: _clic_punto(15)
func _on_punto_17_pressed() -> void: _clic_punto(16)
func _on_punto_18_pressed() -> void: _clic_punto(17)
func _on_punto_19_pressed() -> void: _clic_punto(18)
func _on_punto_20_pressed() -> void: _clic_punto(19)
func _on_punto_21_pressed() -> void: _clic_punto(20)
func _on_punto_22_pressed() -> void: _clic_punto(21)
func _on_punto_23_pressed() -> void: _clic_punto(22)
func _on_punto_24_pressed() -> void: _clic_punto(23)

func _on_azul_button_1_pressed() -> void: _clic_ficha(0)
func _on_azul_button_2_pressed() -> void: _clic_ficha(1)
func _on_azul_button_3_pressed() -> void: _clic_ficha(2)
func _on_azul_button_4_pressed() -> void: _clic_ficha(3)
func _on_azul_button_5_pressed() -> void: _clic_ficha(4)
func _on_rojo_button_1_pressed() -> void: _clic_ficha(5)
func _on_rojo_button_2_pressed() -> void: _clic_ficha(6)
func _on_rojo_button_3_pressed() -> void: _clic_ficha(7)
func _on_rojo_button_4_pressed() -> void: _clic_ficha(8)
func _on_rojo_button_5_pressed() -> void: _clic_ficha(9)




func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ui_inicio_juego.tscn")
	pass # Replace with function body.


func _on_cancelar_pressed() -> void:
	menu_pausa.visible = false
	pass # Replace with function body.


func _on_button_pressed() -> void:
	menu_pausa.visible = true
	pass # Replace with function body.
