extends Node

## Red LAN / IP directa (ENet).
##
## Vive en un autoload para que la conexión sobreviva a los cambios de escena
## (menú → mesa → fin → revancha).
##
## Modelo: el host (peer 1) es siempre AZUL y es la autoridad. Valida y aplica
## las jugadas contra la mesa; el cliente solo manda INTENCIONES y dibuja los
## snapshots que recibe. Así el cliente no puede inventar jugadas ni desincronizarse.

signal estado_cambio(texto: String)
signal sala_actualizada(azul: String, rojo: String)
signal conexion_fallida(motivo: String)
signal partida_iniciada
signal jugada_recibida(accion: Dictionary, snapshot: Dictionary)
signal rival_salio(motivo: String)
signal revancha_actualizada(azul_listo: bool, rojo_listo: bool)

const PUERTO_POR_DEFECTO := 7777
const MAX_CLIENTES := 1
const AZUL := 0
const ROJO := 1

enum Rol { NINGUNO, HOST, CLIENTE }

var rol: int = Rol.NINGUNO
var mi_equipo: int = AZUL
var nombre_local := "Jugador"
var nombre_azul := ""
var nombre_rojo := ""
var puerto := PUERTO_POR_DEFECTO
var en_partida := false
var revancha_azul := false
var revancha_rojo := false

var _mesa: Node = null


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

func activo() -> bool:
	return rol != Rol.NINGUNO


func es_host() -> bool:
	return rol == Rol.HOST


func es_cliente() -> bool:
	return rol == Rol.CLIENTE


func equipo_de(id: int) -> int:
	return AZUL if id == 1 else ROJO


func nombre_de(equipo: int) -> String:
	return nombre_azul if equipo == AZUL else nombre_rojo


func ips_locales() -> Array[String]:
	var resultado: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip.contains(":"):
			continue  # IPv6
		if ip.begins_with("127."):
			continue
		resultado.append(ip)
	return resultado


# ---------------------------------------------------------------------------
# Ciclo de vida de la conexión
# ---------------------------------------------------------------------------

func hostear(puerto_nuevo: int, nombre: String) -> bool:
	salir()
	puerto = puerto_nuevo
	nombre_local = _limpiar_nombre(nombre)

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_CLIENTES)
	if err != OK:
		conexion_fallida.emit("No se pudo abrir el puerto %d (error %d)." % [puerto, err])
		return false

	multiplayer.multiplayer_peer = peer
	rol = Rol.HOST
	mi_equipo = AZUL
	nombre_azul = nombre_local
	nombre_rojo = ""
	estado_cambio.emit("Sala creada en el puerto %d. Esperando rival…" % puerto)
	sala_actualizada.emit(nombre_azul, nombre_rojo)
	return true


func unirse(ip: String, puerto_nuevo: int, nombre: String) -> bool:
	salir()
	puerto = puerto_nuevo
	nombre_local = _limpiar_nombre(nombre)

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), puerto)
	if err != OK:
		conexion_fallida.emit("No se pudo conectar a %s:%d (error %d)." % [ip, puerto, err])
		return false

	multiplayer.multiplayer_peer = peer
	rol = Rol.CLIENTE
	mi_equipo = ROJO
	estado_cambio.emit("Conectando a %s:%d…" % [ip.strip_edges(), puerto])
	return true


func salir() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	rol = Rol.NINGUNO
	en_partida = false
	revancha_azul = false
	revancha_rojo = false
	_mesa = null
	nombre_azul = ""
	nombre_rojo = ""


## La mesa se registra para que el host pueda validar intenciones.
func registrar_mesa(mesa: Node) -> void:
	_mesa = mesa


func olvidar_mesa(mesa: Node) -> void:
	if _mesa == mesa:
		_mesa = null


# ---------------------------------------------------------------------------
# Señales del MultiplayerAPI
# ---------------------------------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	if es_host():
		estado_cambio.emit("Rival conectado. Esperando sus datos…")


func _on_connected_to_server() -> void:
	rpc_id(1, "rpc_hola", nombre_local)
	estado_cambio.emit("Conectado. Esperando al anfitrión…")


func _on_peer_disconnected(_id: int) -> void:
	if not es_host():
		return
	var estaba_jugando := en_partida
	en_partida = false
	nombre_rojo = ""
	sala_actualizada.emit(nombre_azul, "")
	estado_cambio.emit("El rival se desconectó.")
	if estaba_jugando:
		rival_salio.emit("El rival se desconectó. Partida cancelada.")


func _on_connection_failed() -> void:
	rol = Rol.NINGUNO
	multiplayer.multiplayer_peer = null
	conexion_fallida.emit("No se pudo conectar con el anfitrión.")


func _on_server_disconnected() -> void:
	var estaba_jugando := en_partida
	rol = Rol.NINGUNO
	multiplayer.multiplayer_peer = null
	if estaba_jugando:
		en_partida = false
		rival_salio.emit("El anfitrión se desconectó. Partida cancelada.")
	else:
		conexion_fallida.emit("Se perdió la conexión con el anfitrión.")


# ---------------------------------------------------------------------------
# RPC de sala
# ---------------------------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func rpc_hola(nombre: String) -> void:
	if not es_host() or en_partida:
		return
	var id := multiplayer.get_remote_sender_id()
	if id == 1 or nombre_rojo != "":
		return
	nombre_rojo = _limpiar_nombre(nombre)
	rpc_id(id, "rpc_bienvenida", nombre_azul, nombre_rojo)
	sala_actualizada.emit(nombre_azul, nombre_rojo)
	estado_cambio.emit("Rival: %s" % nombre_rojo)


@rpc("authority", "call_remote", "reliable")
func rpc_bienvenida(azul: String, rojo: String) -> void:
	nombre_azul = azul
	nombre_rojo = rojo
	sala_actualizada.emit(nombre_azul, nombre_rojo)
	estado_cambio.emit("Conectado con %s." % azul)


func iniciar_partida() -> void:
	if not es_host() or nombre_rojo == "":
		return
	rpc("rpc_iniciar", nombre_azul, nombre_rojo)


@rpc("authority", "call_local", "reliable")
func rpc_iniciar(azul: String, rojo: String) -> void:
	nombre_azul = azul
	nombre_rojo = rojo
	en_partida = true
	revancha_azul = false
	revancha_rojo = false

	Global.modo = Global.Modo.ONLINE
	Global.es_host = es_host()
	Global.equipo_local = mi_equipo
	Global.NameP1 = nombre_azul
	Global.NameP2 = nombre_rojo

	partida_iniciada.emit()
	get_tree().change_scene_to_file("res://MesaJuego.tscn")


# ---------------------------------------------------------------------------
# RPC de partida
# ---------------------------------------------------------------------------

## El cliente (o el host, directo) pide aplicar una jugada.
func enviar_intencion(accion: Dictionary) -> void:
	if not activo() or not en_partida:
		return
	if es_host():
		if _mesa != null and _mesa.has_method("recibir_intencion"):
			_mesa.recibir_intencion(accion, 1)
	else:
		rpc_id(1, "rpc_intencion", accion)


@rpc("any_peer", "call_remote", "reliable", 1)
func rpc_intencion(accion: Dictionary) -> void:
	if not es_host() or not en_partida:
		return
	if _mesa == null or not _mesa.has_method("recibir_intencion"):
		return
	_mesa.recibir_intencion(accion, multiplayer.get_remote_sender_id())


## El host manda la jugada + snapshot final a todos.
func difundir(accion: Dictionary, snapshot: Dictionary) -> void:
	if not es_host() or not en_partida:
		return
	rpc("rpc_aplicar", accion, snapshot)


@rpc("authority", "call_remote", "reliable")
func rpc_aplicar(accion: Dictionary, snapshot: Dictionary) -> void:
	jugada_recibida.emit(accion, snapshot)


## Resincronización manual (por si el cliente se une tarde o perdió algo).
func pedir_estado() -> void:
	if es_cliente() and en_partida:
		rpc_id(1, "rpc_pedir_estado")


## El host reenvía el estado a un cliente concreto (por ejemplo, si rechazó
## una intención ilegal y el cliente quedó esperando respuesta).
func enviar_estado_a(id: int) -> void:
	if not es_host() or _mesa == null:
		return
	if not _mesa.has_method("estado_red"):
		return
	rpc_id(id, "rpc_estado", _mesa.estado_red())


@rpc("any_peer", "call_remote", "reliable")
func rpc_pedir_estado() -> void:
	if not es_host() or _mesa == null:
		return
	if not _mesa.has_method("estado_red"):
		return
	rpc_id(multiplayer.get_remote_sender_id(), "rpc_estado", _mesa.estado_red())


@rpc("authority", "call_remote", "reliable")
func rpc_estado(snapshot: Dictionary) -> void:
	jugada_recibida.emit({}, snapshot)


# ---------------------------------------------------------------------------
# Revancha
# ---------------------------------------------------------------------------

func marcar_revancha_local() -> void:
	if not activo() or not en_partida:
		return
	if es_host():
		revancha_azul = true
		rpc("rpc_marcar_azul")
		_chequear_revancha()
	else:
		rpc_id(1, "rpc_revancha")


@rpc("authority", "call_remote", "reliable")
func rpc_marcar_azul() -> void:
	revancha_azul = true
	revancha_actualizada.emit(revancha_azul, revancha_rojo)


@rpc("any_peer", "call_remote", "reliable")
func rpc_revancha() -> void:
	if not es_host():
		return
	revancha_rojo = true
	rpc("rpc_marcar_rojo")
	_chequear_revancha()


@rpc("authority", "call_remote", "reliable")
func rpc_marcar_rojo() -> void:
	revancha_rojo = true
	revancha_actualizada.emit(revancha_azul, revancha_rojo)


func _chequear_revancha() -> void:
	revancha_actualizada.emit(revancha_azul, revancha_rojo)
	if revancha_azul and revancha_rojo:
		iniciar_partida()


# ---------------------------------------------------------------------------

func _limpiar_nombre(nombre: String) -> String:
	var limpio := nombre.strip_edges()
	return limpio if limpio != "" else "Jugador"
