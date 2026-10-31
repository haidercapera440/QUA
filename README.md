

# ♟️ QUA - Juego de Estrategia Abstracta

![Godot Engine](https://img.shields.io/badge/Godot_Engine-%23478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)
![Open Source](https://img.shields.io/badge/Open_Source-%232ea44f?style=for-the-badge&logo=github&logoColor=white)
![License](https://img.shields.io/badge/Licencia-MIT-yellow.svg?style=for-the-badge)

**Qua** es un videojuego de estrategia abstracta por turnos de código abierto, desarrollado en **Godot Engine**. Inspirado en la geometría de los juegos de molino tradicionales (*Morabaraba*), **Qua** reinventa la fórmula clásica con reglas de desgaste de tablero: líneas de un solo uso y partidas rápidas de alta tensión donde cada movimiento cuenta.

---

## 🎯 Características Principales

* **Tablero Geométrico Complejo:** Estructura cuadrada compuesta por **24 vértices** interconectados que forman **20 líneas posibles** de ataque.
* **Mecánica de "Quemado de Líneas":** A diferencia del tres en línea o el molino tradicional, cada línea donde se logra un **¡QUA!** se consume y no puede volver a utilizarse, obligando a los jugadores a desplazarse constantemente.
* **Partidas Rápidas y Letales:** Con solo 5 fichas por jugador, perder 3 piezas significa la derrota.
* **100% Open Source:** Código limpio y modular en **GDScript**, ideal para aprender sobre lógica de grafos, matrices de adyacencia y máquinas de estados en Godot.

---

## 📜 Reglas del Juego

### Conceptos Clave
* **Línea:** Segmento del tablero formado por **3 vértices** (uno en cada extremo y uno en el centro). El tablero cuenta con 20 líneas en total.
* **¡QUA!:** Alinear **3 fichas propias** sobre los 3 puntos de una misma línea activa.

### Fase 1: Despliegue
1. Cada jugador inicia con **5 fichas** (10 fichas en total sobre un tablero de 24 puntos).
2. Los jugadores alternan turnos colocando una ficha a la vez en cualquier vértice vacío.
3. **Penalización por ¡QUA! prematuro:** No está permitido hacer ¡QUA! durante la fase de colocación. Si un jugador alinea 3 fichas antes de que las 10 estén en el tablero, no captura ninguna pieza y **esa línea queda anulada permanentemente** por el resto de la partida.

### Fase 2: Movimiento y Captura
4. Una vez desplegadas las 10 fichas, los jugadores se turnan para mover **una ficha por turno**.
5. Las fichas solo pueden desplazarse **un punto a la vez** hacia un vértice adyacente vacío. No se permite saltar sobre otras fichas.
6. **Recompensa por ¡QUA!:** Al formar un ¡QUA! válido durante esta fase, el jugador **elimina inmediatamente una ficha del oponente** a su elección.
7. **Líneas de un solo uso:** Una línea en la que ya se hizo ¡QUA! queda desactivada. Volver a alinear 3 fichas en ella no tendrá ningún efecto.

### Condición de Victoria
8. Pierde inmediatamente el jugador que se quede con solo **2 fichas** en el tablero (al serle imposible formar un nuevo ¡QUA!) o aquel que quede completamente bloqueado sin movimientos válidos.

---

## 💻 Requisitos e Instalación (Windows)

Actualmente, **Qua** está disponible únicamente para **Windows**. No requiere instalación; es una versión portable lista para jugar.

### Pasos para jugar:
1. Ve a la sección de [**ITCHIO**](https://capera.itch.io/qua) descarga el archivo comprimido más reciente (`Qua_Windows.zip`).
2. **Descomprime el archivo** en una carpeta de tu preferencia (clic derecho -> *Extraer todo...*). ⚠️ *Importante: No ejecutes el juego directamente desde adentro del archivo .zip o podría presentar errores.*
3. Abre la carpeta extraída y haz doble clic en `Qua.exe` para iniciar el juego.

---

## 🌐 Configuración para Multijugador (LAN / Red Local)

Para jugar partidas multijugador en red local (LAN), el juego necesita comunicarse a través de tu red con el otro equipo:

1. Al iniciar el modo multijugador por primera vez, aparecerá una ventana emergente del **Firewall de Windows Defender**.
2. Asegúrate de marcar las casillas de **Redes privadas** y **Redes públicas**.
3. Haz clic en **Permitir acceso**. 

> **Nota:** Si no aceptas este permiso o cierras la ventana por error, el Firewall bloqueará la conexión y los jugadores no podrán verse ni unirse a la partida en la red local.

---

## 🛠️ Para Desarrolladores (Código Fuente)

Si deseas explorar el código, modificar el juego o compilarlo para otros sistemas operativos:

1. Clona este repositorio:
   ```bash
   git clone https://github.com/haidercapera440/QUA.git
