class_name IAQua
extends RefCounted

## IA de QUA, nivel medio.
##
## No ejecuta jugadas: solo devuelve una INTENCIÓN que mesa_juego.gd valida
## y aplica con _colocar / _intentar_mover / _capturar.
##
## Formato del plan:
##   {"accion": "colocar",  "ficha": i, "punto": p}
##   {"accion": "mover",    "ficha": i, "punto": p}
##   {"accion": "capturar", "ficha": i}
##   {"accion": "pasar"}
##
## Toda la evaluación es de una jugada (sin mutar el estado real):
## se simula sobre copias lógicas con _equipo_simulado().

const PESO_QUA := 1000.0
const PESO_ANULAR := -1200.0      ## hacer QUA en colocación anula la línea
const PESO_BLOQUEO := 95.0
const PESO_AMENAZA := -230.0
const PESO_POTENCIAL := 14.0
const PESO_MOVILIDAD := 3.5
const PESO_CAPTURA_AMENAZA := 110.0
const RUIDO := 7.0                ## desempate: que no juegue siempre igual


static func decidir(mesa, equipo: int) -> Dictionary:
	match mesa.fase:
		mesa.Fase.COLOCACION:
			return _decidir_colocacion(mesa, equipo)
		mesa.Fase.ELIMINACION:
			return _decidir_captura(mesa, equipo)
		mesa.Fase.MOVIMIENTO:
			return _decidir_movimiento(mesa, equipo)
	return {"accion": "pasar"}


## Comprobación de seguridad: la mesa acepta este plan?
static func es_legal(mesa, equipo: int, plan: Dictionary) -> bool:
	match String(plan.get("accion", "")):
		"colocar":
			var f: int = int(plan.get("ficha", -1))
			var p: int = int(plan.get("punto", -1))
			if f < 0 or p < 0:
				return false
			if mesa.fichas[f]["equipo"] != equipo or mesa.fichas[f]["punto"] != -1:
				return false
			return mesa.puntos[p]["ocupante"] == -1
		"mover":
			var f2: int = int(plan.get("ficha", -1))
			var p2: int = int(plan.get("punto", -1))
			if f2 < 0 or p2 < 0:
				return false
			if not mesa.fichas[f2]["viva"] or mesa.fichas[f2]["equipo"] != equipo:
				return false
			var origen: int = mesa.fichas[f2]["punto"]
			if origen == -1:
				return false
			return p2 in mesa.ADYACENTES[origen] and mesa.puntos[p2]["ocupante"] == -1
		"capturar":
			var f3: int = int(plan.get("ficha", -1))
			if f3 < 0:
				return false
			return mesa.fichas[f3]["viva"] and mesa.fichas[f3]["equipo"] != equipo
		"pasar":
			return true
	return false


# ---------------------------------------------------------------------------
# Colocación
# ---------------------------------------------------------------------------

static func _decidir_colocacion(mesa, equipo: int) -> Dictionary:
	var ficha := _ficha_en_bandeja(mesa, equipo)
	if ficha == -1:
		return {"accion": "pasar"}

	var mejor := -1
	var mejor_score := -INF

	for p in mesa.puntos.size():
		if mesa.puntos[p]["ocupante"] != -1:
			continue

		var s := 0.0
		# Regla 3: si completamos una línea ahora, queda anulada para siempre.
		var propias := _lineas_nuevas(mesa, equipo, -1, p, ficha)
		s += propias * PESO_ANULAR

		# Bloquear una línea rival a punto de cerrarse.
		s += _bloqueos(mesa, equipo, -1, p, ficha) * PESO_BLOQUEO

		# Construir amenazas propias (2 en línea, tercero libre).
		s += _potencial(mesa, equipo, -1, p, ficha) * PESO_POTENCIAL
		# Y no regalarle amenazas al rival.
		s -= _potencial(mesa, 1 - equipo, -1, p, ficha) * PESO_POTENCIAL * 0.6

		s += _valor_punto(mesa, p) * PESO_MOVILIDAD
		s += randf() * RUIDO

		if s > mejor_score:
			mejor_score = s
			mejor = p

	if mejor == -1:
		return {"accion": "pasar"}
	return {"accion": "colocar", "ficha": ficha, "punto": mejor}


# ---------------------------------------------------------------------------
# Movimiento
# ---------------------------------------------------------------------------

static func _decidir_movimiento(mesa, equipo: int) -> Dictionary:
	var mejor := {"accion": "pasar"}
	var mejor_score := -INF

	for f in mesa.fichas.size():
		if not mesa.fichas[f]["viva"] or mesa.fichas[f]["equipo"] != equipo:
			continue
		var origen: int = mesa.fichas[f]["punto"]
		if origen == -1:
			continue

		for destino in mesa.ADYACENTES[origen]:
			if mesa.puntos[destino]["ocupante"] != -1:
				continue

			var s := 0.0
			s += _lineas_nuevas(mesa, equipo, origen, destino, f) * PESO_QUA
			s += _bloqueos(mesa, equipo, origen, destino, f) * PESO_BLOQUEO
			s += _amenazas_rival(mesa, equipo, origen, destino, f) * PESO_AMENAZA
			s += _potencial(mesa, equipo, origen, destino, f) * PESO_POTENCIAL
			s -= _potencial(mesa, 1 - equipo, origen, destino, f) * PESO_POTENCIAL * 0.5
			s += _valor_punto(mesa, destino) * PESO_MOVILIDAD
			s += randf() * RUIDO

			if s > mejor_score:
				mejor_score = s
				mejor = {"accion": "mover", "ficha": f, "punto": destino}

	return mejor


# ---------------------------------------------------------------------------
# Captura
# ---------------------------------------------------------------------------

static func _decidir_captura(mesa, equipo: int) -> Dictionary:
	var rival := 1 - equipo
	var mejor := -1
	var mejor_score := -INF

	for f in mesa.fichas.size():
		if not mesa.fichas[f]["viva"] or mesa.fichas[f]["equipo"] != rival:
			continue
		if mesa.fichas[f]["punto"] == -1:
			continue

		var s := _amenaza_que_aporta(mesa, rival, f) * PESO_CAPTURA_AMENAZA
		s += mesa.ADYACENTES[mesa.fichas[f]["punto"]].size() * PESO_MOVILIDAD
		s += randf() * RUIDO

		if s > mejor_score:
			mejor_score = s
			mejor = f

	if mejor == -1:
		return {"accion": "pasar"}
	return {"accion": "capturar", "ficha": mejor}


# ---------------------------------------------------------------------------
# Evaluación pura (sin mutar el estado real)
# ---------------------------------------------------------------------------

## Equipo que ocuparía `p` si `ficha` se mueve de `origen` a `destino`.
## Para colocación, origen = -1.
static func _equipo_simulado(mesa, p: int, origen: int, destino: int, ficha: int) -> int:
	if p == origen:
		return -1
	if p == destino:
		return mesa.fichas[ficha]["equipo"]
	var oc: int = mesa.puntos[p]["ocupante"]
	if oc == -1:
		return -1
	return mesa.fichas[oc]["equipo"]


## Líneas LIBRE que quedarían completas por el equipo tras la jugada.
static func _lineas_nuevas(mesa, equipo: int, origen: int, destino: int, ficha: int) -> int:
	var n := 0
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		var l: Array = mesa.LINEAS[i]
		if _equipo_simulado(mesa, l[0], origen, destino, ficha) == equipo \
		and _equipo_simulado(mesa, l[1], origen, destino, ficha) == equipo \
		and _equipo_simulado(mesa, l[2], origen, destino, ficha) == equipo:
			n += 1
	return n


## Líneas LIBRE donde el rival tiene 2 y nuestra jugada tapa el tercer punto.
static func _bloqueos(mesa, equipo: int, origen: int, destino: int, ficha: int) -> int:
	var rival := 1 - equipo
	var n := 0
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		var l: Array = mesa.LINEAS[i]
		if not (destino in l):
			continue
		var rivales := 0
		var vacios := 0
		for p in l:
			var e := _equipo_simulado(mesa, p, origen, destino, ficha)
			if e == rival:
				rivales += 1
			elif e == -1:
				vacios += 1
		if rivales == 2 and vacios == 1:
			n += 1
	return n


## Líneas LIBRE donde el equipo quedaría con 2 y un hueco libre.
static func _potencial(mesa, equipo: int, origen: int, destino: int, ficha: int) -> int:
	var n := 0
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		var l: Array = mesa.LINEAS[i]
		var propios := 0
		var vacios := 0
		for p in l:
			var e := _equipo_simulado(mesa, p, origen, destino, ficha)
			if e == equipo:
				propios += 1
			elif e == -1:
				vacios += 1
		if propios == 2 and vacios == 1:
			n += 1
	return n


## Líneas LIBRE que el rival podría cerrar en su próximo turno.
static func _amenazas_rival(mesa, equipo: int, origen: int, destino: int, ficha: int) -> int:
	var rival := 1 - equipo
	var n := 0
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		var l: Array = mesa.LINEAS[i]
		var rivales := 0
		var propios := 0
		var hueco := -1
		for p in l:
			var e := _equipo_simulado(mesa, p, origen, destino, ficha)
			if e == rival:
				rivales += 1
			elif e == equipo:
				propios += 1
			else:
				hueco = p
		if rivales == 2 and propios == 0 and hueco != -1 and _rival_puede_llegar(mesa, rival, hueco):
			n += 1
	return n


static func _rival_puede_llegar(mesa, rival: int, hueco: int) -> bool:
	for f in mesa.fichas:
		if not f["viva"] or f["equipo"] != rival:
			continue
		var q: int = f["punto"]
		if q == -1:
			continue
		if hueco in mesa.ADYACENTES[q]:
			return true
	return false


## Cuántas amenazas rivales dependen de esta ficha (para elegir qué capturar).
static func _amenaza_que_aporta(mesa, rival: int, ficha: int) -> int:
	var p: int = mesa.fichas[ficha]["punto"]
	var n := 0
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		var l: Array = mesa.LINEAS[i]
		if not (p in l):
			continue
		var rivales := 0
		for q in l:
			if mesa.puntos[q]["ocupante"] != -1 and mesa.fichas[mesa.puntos[q]["ocupante"]]["equipo"] == rival:
				rivales += 1
		if rivales >= 2:
			n += 1
	return n


## Movilidad + potencial de líneas del punto.
static func _valor_punto(mesa, p: int) -> int:
	var v: int = mesa.ADYACENTES[p].size()
	for i in mesa.LINEAS.size():
		if mesa.estados_lineas[i] != mesa.EstadoLinea.LIBRE:
			continue
		if p in mesa.LINEAS[i]:
			v += 1
	return v


static func _ficha_en_bandeja(mesa, equipo: int) -> int:
	for i in mesa.fichas.size():
		if mesa.fichas[i]["equipo"] == equipo and mesa.fichas[i]["viva"] and mesa.fichas[i]["punto"] == -1:
			return i
	return -1
