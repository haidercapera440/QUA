extends Control

## Lobby de LAN / IP directa.
## El que crea la sala es el host y juega con Azul; el que se une juega con Rojo.
@onready var sountrack: AudioStreamPlayer2D = $Sountrack
@onready var nombre: LineEdit = $Centro/Nombre
@onready var puerto: SpinBox = $Centro/Puerto
@onready var crear: Button = $Centro/Crear
@onready var ips: Label = $Centro/Ips
@onready var ip: LineEdit = $Centro/Ip
@onready var unirse: Button = $Centro/Unirse
@onready var estado: Label = $Centro/Estado
@onready var jugadores: Label = $Centro/Jugadores
@onready var empezar: Button = $Centro/Empezar
@onready var volver: Button = $Centro/Volver


func _ready() -> void:
	Red.salir()
	sountrack.play()
	nombre.text = "Player"
	puerto.value = Red.PUERTO_POR_DEFECTO
	ip.text = ""
	empezar.disabled = true
	estado.text = ""
	_actualizar_ips()
	_actualizar_jugadores("", "")

	Red.estado_cambio.connect(_on_estado_cambio)
	Red.sala_actualizada.connect(_on_sala_actualizada)
	Red.conexion_fallida.connect(_on_conexion_fallida)


func _exit_tree() -> void:
	if Red.estado_cambio.is_connected(_on_estado_cambio):
		Red.estado_cambio.disconnect(_on_estado_cambio)
	if Red.sala_actualizada.is_connected(_on_sala_actualizada):
		Red.sala_actualizada.disconnect(_on_sala_actualizada)
	if Red.conexion_fallida.is_connected(_on_conexion_fallida):
		Red.conexion_fallida.disconnect(_on_conexion_fallida)


func _actualizar_ips() -> void:
	var lista := Red.ips_locales()
	if lista.is_empty():
		ips.text = "No local IPs were detected."
	else:
		ips.text = "IPs locals: " + ", ".join(PackedStringArray(lista))


func _actualizar_jugadores(azul: String, rojo: String) -> void:
	var a := azul if azul != "" else "—"
	var r := rojo if rojo != "" else "—"
	jugadores.text = "Blue (host): %s\nRed: %s" % [a, r]


func _on_crear_pressed() -> void:
	if not Red.hostear(int(puerto.value), nombre.text):
		return
	crear.disabled = true
	unirse.disabled = true
	empezar.disabled = true
	estado.text = "Room created. Share your IP and port. %d." % int(puerto.value)


func _on_unirse_pressed() -> void:
	var destino := ip.text.strip_edges()
	if destino == "":
		estado.text = "I noted down the host's IP address."
		return
	if not Red.unirse(destino, int(puerto.value), nombre.text):
		return
	crear.disabled = true
	unirse.disabled = true
	estado.text = "Connecting to %s:%d…" % [destino, int(puerto.value)]
	_esperar_conexion()


func _esperar_conexion() -> void:
	await get_tree().create_timer(6.0).timeout
	if not is_inside_tree():
		return
	if Red.es_cliente() and Red.nombre_azul == "":
		estado.text = "The host did not respond."
		Red.salir()
		crear.disabled = false
		unirse.disabled = false


func _on_sala_actualizada(azul: String, rojo: String) -> void:
	_actualizar_jugadores(azul, rojo)
	empezar.disabled = not (Red.es_host() and rojo != "")


func _on_estado_cambio(texto: String) -> void:
	estado.text = texto


func _on_conexion_fallida(motivo: String) -> void:
	estado.text = motivo
	crear.disabled = false
	unirse.disabled = false


func _on_empezar_pressed() -> void:
	Red.iniciar_partida()


func _on_volver_pressed() -> void:
	Red.salir()
	get_tree().change_scene_to_file("res://Scenes/ui_inicio_juego.tscn")
