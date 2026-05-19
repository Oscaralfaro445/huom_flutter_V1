# QA Report — HUOM Flutter V1
**Fecha:** 2026-05-18  
**Rama:** `feature/rama_hughost`  
**Revisado por:** QA automatizado + revisión manual de código  
**Scope:** Sistema de alimentación · Minijuegos (todos) · `StatDecayService`

---

## 1. Hallazgos de revisión de código (minijuegos)

### 1.1 Fugas de memoria

#### 🔴 CRÍTICO — `ui.Image` nunca se disposa
**Archivos afectados:** `food_drop_game.dart`, `dodge_bombs_game.dart`, `whack_a_pet_game.dart`

Los tres juegos cargan el sprite con `ui.instantiateImageCodec` → `codec.getNextFrame()` → `frame.image`. El campo `_petImage` (tipo `ui.Image`) nunca es liberado cuando el juego termina o se desmonta el widget. `ui.Image` mantiene un buffer nativo en memoria; sin llamar `.dispose()`, el GC no puede reclamarlo de forma determinista.

```dart
// ❌ Patrón actual (idéntico en los 3 archivos)
Future<void> _loadPetImage() async {
  try {
    final data = await rootBundle.load('assets/$petSpritePath');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _petImage = frame.image; // ← nunca se disposa
    // codec tampoco se disposa ← segunda fuga
  } catch (_) { // ← swallow silencioso (ver §1.3)
    _petImage = null;
  }
}
```

**Fix recomendado:** Usar `game.images.load(petSpritePath)` de Flame (gestiona caché y ciclo de vida) o sobrescribir `onDetach()` para llamar `_petImage?.dispose()` y `codec.dispose()`.

---

#### 🟠 ALTO — `ui.Codec` nunca se disposa
**Archivos afectados:** mismos 3

La variable `codec` se crea dentro del `try` pero nunca se cierra. Aunque dart:ui libera los recursos internos del codec eventualmente, es una práctica incorrecta y puede provocar que el motor de imagen retenga más recursos de los necesarios.

---

### 1.2 Problemas de rendimiento

#### 🟠 ALTO — `TextPainter` instanciado en cada frame por cada objeto
**Archivos afectados:** `food_drop_game.dart` (`_drawFalling`), `dodge_bombs_game.dart` (`_drawBombs`)

```dart
// ❌ En _drawFalling / _drawBombs — se ejecuta 60 veces por segundo
void _drawFalling(Canvas canvas) {
  for (final f in _falling) {
    final tp = TextPainter(        // ← new allocation × N objetos × 60fps
      text: TextSpan(text: f.emoji, style: ...),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ...);
  }
}
```

Con 8+ items en pantalla esto genera ~480 allocations/segundo de un objeto relativamente pesado (incluye layout de texto). Causa GC stutters visibles en dispositivos de gama media-baja.

**Fix recomendado:** Mantener un `Map<String, TextPainter>` como caché por emoji. Sólo crear/layout cuando el texto cambia.

---

#### 🟡 MEDIO — `Paint` creado en cada frame (9 celdas × 2 Paints = 18/frame)
**Archivo afectado:** `whack_a_pet_game.dart` (`_drawGrid`)

```dart
void _drawGrid(Canvas canvas) {
  // ...
  final holePaint = Paint()..color = ...; // ← nuevo en cada frame
  final border   = Paint()..color = ...;  // ← nuevo en cada frame
  for (var r = 0; r < _rows; r++) { ... }
}
```

**Fix:** Declarar `holePaint` y `border` como campos `late final` e inicializarlos en `onLoad`.

---

#### 🟡 MEDIO — Hitbox puntual en FoodDropGame
**Archivo afectado:** `food_drop_game.dart`

```dart
_falling.removeWhere((f) {
  final hit = hitRect.contains(f.position); // ← solo el CENTRO del ítem (1 pixel)
  ...
});
```

El ítem cae con un tamaño visual de 32 px, pero la colisión se evalúa sólo sobre su punto central. El jugador puede "sentir" que atrapó el ítem y que el juego no lo registra (especialmente a velocidades altas). Debería usarse `hitRect.overlaps(itemRect)` donde `itemRect = Rect.fromCenter(center: f.position, width: _Falling.size, height: _Falling.size)`.

---

#### 🟡 MEDIO — Loop de generación de plataformas con terminación implícita
**Archivo afectado:** `sky_jump_game.dart` (`update`)

```dart
final highest = _platforms.fold<double>(0, (acc, p) => min(acc, p.position.dy));
while (highest - _cameraOffset > -200) {
  final newY = (_platforms.isEmpty ? petY : highest) - (70 + _rng.nextDouble() * 60);
  _platforms.add(_Platform(..., newY), _platformWidth));
  if (newY < highest) break; // safety — siempre verdadero en la primera iteración
}
```

`highest` no se recalcula dentro del loop y `_cameraOffset` no cambia en el mismo tick, por lo que la condición `while` es fija. El `break` se dispara siempre en la primera iteración. El loop es efectivamente un `if`, pero redactado como `while`, lo cual oculta la intención y puede sorprender a quien modifique el código.

---

### 1.3 Violaciones de linteo y calidad de código

| # | Severidad | Archivo | Línea aprox. | Descripción |
|---|-----------|---------|-------------|-------------|
| L1 | 🟠 | food_drop_game.dart | 108 | `catch (_)` swallows ALL exceptions; errores de asset o OOM quedan completamente silenciados. Usar `catch (e)` + `debugPrint` mínimamente. |
| L2 | 🟠 | dodge_bombs_game.dart | 98 | Mismo problema que L1. |
| L3 | 🟠 | whack_a_pet_game.dart | 114 | Mismo problema que L1. |
| L4 | 🟡 | sky_jump_game.dart | 20 | `DragCallbacks` declarado en `with` pero no hay ningún `onDragStart/Update/End` sobrescrito. Mixin muerto → ruido en la jerarquía. |
| L5 | 🟡 | color_tap_game.dart | 201 | `_slotColors[slot]!` con force-unwrap. Aunque actualmente seguro, es frágil ante refactoring. Preferir `_slotColors[slot]?.color ?? Colors.transparent`. |
| L6 | 🟡 | food_drop_game.dart, dodge_bombs_game.dart, whack_a_pet_game.dart | — | `_loadPetImage()` es código idéntico copiado en 3 archivos (violación DRY). Extraer a un `mixin SpritePetLoader` o función top-level. |
| L7 | 🔵 | whack_a_pet_game.dart | 231–235 | `holePaint` y `border` en `_drawGrid` deberían ser `late final` campos. |

---

## 2. Pruebas unitarias — `StatDecayService`

### 2.1 Cobertura implementada

El archivo `test/core/services/stat_decay_service_test.dart` cubre **34 casos** agrupados en 7 secciones:

| Grupo | Casos |
|-------|-------|
| Guard clauses | 4 |
| Multiplicadores de etapa | 4 |
| Multiplicadores de mutación | 7 (una por mutación) |
| Combinaciones etapa × mutación | 2 |
| Decay de cleanliness | 3 |
| Penalización por suciedad | 4 |
| Evaluación de estado | 13 |
| Integridad de stats | 3 |

### 2.2 Casos límite cubiertos

| Caso límite | Descripción |
|-------------|-------------|
| `hoursElapsed < 0.01` | No aplica decay (umbral de 36 s exacto) |
| `hoursElapsed = 0.01` (36 s exactos) | SÍ aplica decay (límite inclusivo) |
| `hunger = 0 && hoursElapsed < 6` | Pet stressed pero viva |
| `hunger = 0 && hoursElapsed = 6` | Pet dead (límite exacto) |
| `health = 20` (límite) | NOT sick (condición `< 20`, no `≤ 20`) |
| `hunger = 25` (límite) | NOT stressed (condición `< 25`) |
| `daysAlive = 29` elder | NOT dead por vejez |
| `daysAlive = 30` elder | dead por vejez |
| Stats negativos tras 100 h | Todos clamped a 0 |
| `now < lastInteraction` | Sin decay (tiempo negativo) |
| `daysAlive` desactualizado | Se recalcula desde `createdAt` |
| Penalización dirty sin stageMult | Baby y adult reciben el mismo daño en health |

---

## 3. Reporte de pruebas manuales — Sistema de alimentación

### 3.1 Pre-condiciones
- Mascota activa en estado `happy`
- Stats iniciales conocidos (anotar `hunger` y `mood` antes de cada prueba)

### 3.2 Tabla de validación

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| F-01 | Alimentar con Snack | 1. Abrir menú comida → 2. Tocar "Snack" | `hunger += 10`, `mood` sin cambio, menú se cierra | ☐ Pendiente |
| F-02 | Alimentar con Comida Básica | 1. Abrir menú → 2. Tocar "Comida básica" | `hunger += 25`, `mood` sin cambio | ☐ Pendiente |
| F-03 | Alimentar con Comida Premium | 1. Abrir menú → 2. Tocar "Comida premium" | `hunger += 40`, `mood += 5` | ☐ Pendiente |
| F-04 | Alimentar con Comida Especial | 1. Abrir menú → 2. Tocar "Comida especial" | `hunger += 35`, `mood += 10` | ☐ Pendiente |
| F-05 | Cap de hunger al 100 | 1. Pet con hunger=95 → 2. Dar Comida Básica (+25) | `hunger` se muestra en 100, no en 120 | ☐ Pendiente |
| F-06 | Decay previo al alimentar | 1. Cerrar app 2 horas → 2. Reabrir → 3. Alimentar | El valor de hunger al alimentar ya refleja el decay (no se aplica sobre el valor antiguo) | ☐ Pendiente |
| F-07 | Mascota en estado stressed | 1. Dejar hunger < 25 → 2. Abrir menú → 3. Alimentar | Estado cambia de `stressed` a `happy` si hunger supera umbrales | ☐ Pendiente |
| F-08 | Mascota muerta no acepta comida | 1. Pet dead → 2. Intentar abrir menú comida | Botón deshabilitado o menú no aparece | ☐ Pendiente |
| F-09 | Overflow en pantalla pequeña | 1. Abrir menú comida en dispositivo con pantalla 5" | Los 4 tiles visibles sin overflow, sin scroll innecesario | ☐ Pendiente |
| F-10 | Cerrar menú sin seleccionar | 1. Abrir menú → 2. Arrastrar hacia abajo / botón back | Menú cierra, hunger no cambia | ☐ Pendiente |

---

## 4. Reporte de pruebas manuales — Minijuegos

### 4.1 Pre-condiciones comunes
- Abrir los juegos desde el menú de minijuegos (botón "Jugar")
- Probar en al menos un dispositivo físico Android (no sólo emulador)
- Sprite de mascota debe cargarse visiblemente (sin círculo de fallback rosa)

### 4.2 Tabla de validación — Food Drop

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| FD-01 | Inicio del juego | 1. Entrar a Food Drop | Instrucción "ARRASTRA" visible, mascota centrada, sin items cayendo | ☐ Pendiente |
| FD-02 | Primer input inicia partida | 1. Arrastrar o tocar pantalla | Instrucción desaparece, items empiezan a caer | ☐ Pendiente |
| FD-03 | Recoger item de comida | 1. Mover mascota debajo de un ítem de comida | Score incrementa en +1 | ☐ Pendiente |
| FD-04 | Bomba termina el juego | 1. Dejar que una bomba toque a la mascota | Game Over inmediato, se muestra score final | ☐ Pendiente |
| FD-05 | Level-up cada 5 puntos | 1. Conseguir 5, 10, 15 puntos | Velocidad y spawn rate aumentan perceptiblemente | ☐ Pendiente |
| FD-06 | Movimiento horizontal con wrap | 1. Arrastrar mascota hasta el borde | Mascota no se sale de la pantalla | ☐ Pendiente |
| FD-07 | Sprite de mascota visible | 1. Iniciar partida | Sprite pixel-art de la mascota (no círculo rosa) | ☐ Pendiente |
| FD-08 | Hitbox de colisión (regresión) | 1. Mover mascota justo debajo de un ítem | El ítem es recogido cuando visualmente toca a la mascota | ⚠️ Defecto conocido (hitbox puntual) |

### 4.3 Tabla de validación — Dodge Bombs

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| DB-01 | Inicio y primer input | 1. Entrar al juego → 2. Arrastrar | Instrucción desaparece, bombas empiezan a caer | ☐ Pendiente |
| DB-02 | Bomba esquivada suma punto | 1. Dejar que una bomba salga por debajo | Score + 1 | ☐ Pendiente |
| DB-03 | Colisión con bomba | 1. No mover, dejar impacto | Game Over con score actual | ☐ Pendiente |
| DB-04 | Aumento de dificultad | 1. Llegar a score 10 | Bombas claramente más rápidas y frecuentes que al inicio | ☐ Pendiente |
| DB-05 | Sprite visible | 1. Iniciar partida | Sprite pixel-art (no círculo rosa) | ☐ Pendiente |

### 4.4 Tabla de validación — Whack-A-Pet

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| WA-01 | Grid 3×3 visible | 1. Iniciar juego | 9 celdas azules visibles, score y fallas en 0 | ☐ Pendiente |
| WA-02 | Tap en mascota = acierto | 1. Tocar celda cuando mascota aparece | Score + 1, celda se vacía | ☐ Pendiente |
| WA-03 | Tap en celda vacía = fallo | 1. Tocar celda vacía | Fallas + 1, label actualizado ("Fallas: X/3") | ☐ Pendiente |
| WA-04 | Mascota se esconde sola = fallo | 1. No tocar la celda activa hasta que desaparezca | Fallas + 1 | ☐ Pendiente |
| WA-05 | 3 fallos = Game Over | 1. Acumular 3 fallos | Game Over con score | ☐ Pendiente |
| WA-06 | Aceleración tras aciertos | 1. Acertar 5+ veces | Mascotas aparecen y desaparecen más rápido | ☐ Pendiente |

### 4.5 Tabla de validación — Reaction Tap

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| RT-01 | Target aleatorio y coloreado | 1. Iniciar juego | Círculo de color aleatorio aparece en posición aleatoria | ☐ Pendiente |
| RT-02 | Tap dentro del target | 1. Tocar dentro del círculo | Score + 1, nuevo target generado | ☐ Pendiente |
| RT-03 | Tap fuera del target | 1. Tocar fuera del círculo | Game Over | ☐ Pendiente |
| RT-04 | Timeout por no tocar | 1. No tocar durante el tiempo asignado | Game Over | ☐ Pendiente |
| RT-05 | Aro animado se contrae | 1. Observar el target | El aro exterior se contrae con el tiempo (visual de urgencia) | ☐ Pendiente |
| RT-06 | Reducción del target | 1. Conseguir 5+ puntos | El radio del círculo visiblemente más pequeño | ☐ Pendiente |

### 4.6 Tabla de validación — Sky Jump

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| SJ-01 | Mascota salta automáticamente | 1. Esperar sin input | Mascota rebota en plataformas solo | ☐ Pendiente |
| SJ-02 | Tap izquierdo mueve la mascota | 1. Tocar mitad izquierda de la pantalla | Mascota se desplaza a la izquierda | ☐ Pendiente |
| SJ-03 | Wrap horizontal | 1. Mover mascota hasta el borde izquierdo | Reaparece por el lado derecho | ☐ Pendiente |
| SJ-04 | Score aumenta al subir | 1. Subir lo más alto posible | Score aumenta proporcionalmente a la altura | ☐ Pendiente |
| SJ-05 | Game Over al caer | 1. Dejar que la mascota caiga fuera del viewport | Game Over con score alcanzado | ☐ Pendiente |
| SJ-06 | Plataformas generadas infinitamente | 1. Jugar 2+ minutos | No aparece pantalla vacía, siempre hay plataformas arriba | ☐ Pendiente |

### 4.7 Tabla de validación — Color Tap

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| CT-01 | 4 cuadrantes coloreados | 1. Iniciar juego | Pantalla dividida en 4 colores distintos (ROJO, AZUL, VERDE, AMARILLO) | ☐ Pendiente |
| CT-02 | Color objetivo mostrado | 1. Observar el label central | El texto indica el nombre del color a tocar (ej. "ROJO") | ☐ Pendiente |
| CT-03 | Tap correcto | 1. Tocar el cuadrante del color pedido | Score + 1, nueva ronda con colores reordenados | ☐ Pendiente |
| CT-04 | Tap incorrecto | 1. Tocar cuadrante equivocado | Game Over | ☐ Pendiente |
| CT-05 | Timeout | 1. No tocar dentro del tiempo | Game Over | ☐ Pendiente |
| CT-06 | Header no tap-able | 1. Tocar la zona del score / label (parte superior) | Sin acción (zona deshabilitada, `y < size.y * 0.3`) | ☐ Pendiente |

---

## 5. Pruebas de regresión — Menús (post-fix overflow)

| ID | Escenario | Pasos | Resultado esperado | Resultado obtenido |
|----|-----------|-------|-------------------|-------------------|
| MN-01 | Menú comida en pantalla pequeña | Dispositivo 360×640 dp → Abrir menú | 4 tiles visibles sin texto cortado ni overflow amarillo | ☐ Pendiente |
| MN-02 | Menú juegos en pantalla pequeña | Mismo dispositivo → Abrir menú juegos | Grid 2×4 visible y scrollable, sin overflow | ☐ Pendiente |
| MN-03 | Menú juegos es scrollable | Pantalla pequeña → Intentar hacer scroll en el grid | El grid responde al scroll cuando el contenido es mayor que el espacio disponible | ☐ Pendiente |
| MN-04 | Safe area respetada | Dispositivo con notch → Abrir ambos menús | El contenido no queda detrás del notch ni de la barra de navegación | ☐ Pendiente |

---

## 6. Resumen ejecutivo

| Categoría | Críticos 🔴 | Altos 🟠 | Medios 🟡 | Bajos 🔵 |
|-----------|------------|---------|---------|---------|
| Fugas de memoria | 1 | 1 | — | — |
| Rendimiento | — | 1 | 2 | 1 |
| Calidad de código / lint | — | 3 | 3 | 1 |
| **Total** | **1** | **5** | **5** | **2** |

### Acciones prioritarias

1. **[CRÍTICO]** Agregar `onDetach()` en los 3 juegos con sprite para llamar `_petImage?.dispose()` y `codec.dispose()`.
2. **[ALTO]** Reemplazar `catch (_)` por `catch (e)` + log en `_loadPetImage()` (× 3 archivos).
3. **[ALTO]** Cachear `TextPainter` en `FoodDropGame` y `DodgeBombsGame`.
4. **[MEDIO]** Corregir hitbox puntual en `FoodDropGame`.
5. **[MEDIO]** Eliminar `DragCallbacks` no utilizado en `SkyJumpGame`.
6. **[REFACTOR]** Extraer `_loadPetImage()` a un mixin compartido para eliminar duplicación.
