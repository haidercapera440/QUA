extends Node

## Estado que sobrevive al cambio de escena.
## Nada de estado temporal de la mesa acá (para eso están las variables de mesa_juego.gd).

enum Modo {
	DOS_JUGADORES,
	CONTRA_MAQUINA,
	DEMO,          ## máquina contra máquina, solo para pruebas
	ONLINE,        ## LAN / IP directa (el host siempre es Azul)
}

const NOMBRE_MAQUINA := "Machine"

var UbiPunto  #legado: ya no se usa para la lógica
var numpunto  #legado: ya no se usa para la lógica
var NameP1 = "player 1"
var NameP2 = "player 2"
var Ganador
var Empate = false

## Configuración de la partida en curso.
var modo: Modo = Modo.DOS_JUGADORES
var dificultad: int = 1          ## 0 = fácil, 1 = medio, 2 = reservado
var bando_humano: int = 0        ## 0 = azul, 1 = rojo (solo en CONTRA_MAQUINA)
var ia_primero: bool = true      ## la máquina siempre empieza

## Online (LAN / IP directa).
var equipo_local: int = 0        ## 0 = azul, 1 = rojo
var es_host: bool = false

## Partida cancelada porque el rival se desconectó.
var cancelada: bool = false
var motivo_cancelacion: String = ""

## Modo demo: la IA juega los dos bandos.
var demo_autoplay: bool = false
