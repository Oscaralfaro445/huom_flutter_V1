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

---
---

# QA Report — Sistema de Salud · Tienda · Lesiones en Minijuegos
**Fecha:** 2026-05-18  
**Rama:** `feature/rama_hughost`  
**Autor del cambio:** Hugh0st  
**Revisado por:** Claude Code (análisis estático + revisión de código)  
**Scope:** Sistema de condiciones · IllnessService · Tienda de medicamentos · Lesiones en minijuegos · Sueño como factor de riesgo

---

## 1. Descripción general del cambio

Esta entrega introduce el **sistema de salud completo** para la mascota virtual. Anteriormente la mascota nunca se enfermaba, lesionaba ni padecía consecuencias por privación de sueño. Desde esta versión el juego contempla:

- **Condiciones de salud activas** (enfermedades y lesiones) que degradan stats con el tiempo.
- **Progresión de enfermedades** respiratorias: Resfriado → Gripe → Fiebre si no se tratan.
- **Agotamiento** causado por privación prolongada de sueño.
- **Lesiones en minijuegos** proporcionales al desempeño del jugador.
- **Tienda de medicamentos** con coste en monedas, dando por fin propósito a esa mecánica.

---

## 2. Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/core/services/illness_service.dart` | Lógica central de enfermedades: probabilidad de contagio, factores de riesgo, decay por condición, aplicación de lesiones |
| `lib/features/pet/domain/usecases/treat_pet_usecase.dart` | Use case de tratamiento + enum `TreatmentItem` con todos los ítems de tienda |
| `lib/features/store/presentation/screens/store_screen.dart` | Pantalla de tienda de medicamentos |

---

## 3. Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `pet.dart` | Nuevo enum `ConditionType`, nueva clase `PetCondition`, campo `conditions` en `Pet`, helpers `isInjured / isIll / isExhausted` |
| `pet_model.dart` | Campos Hive 15 (`conditionTypeIndexes`) y 16 (`conditionTimestamps`) |
| `pet_model.g.dart` | Adaptador Hive actualizado manualmente (17 campos totales, backward-compatible) |
| `pet_mapper.dart` | Serialización/deserialización de condiciones como listas paralelas de int |
| `stat_decay_service.dart` | Recibe `IllnessService` por constructor; aplica decay por condición y chequeo de nuevas enfermedades en cada ciclo |
| `pet_provider.dart` | Nuevos métodos `treatPet()` y `applyInjury()` |
| `injection.dart` | Registro de `IllnessService` y `TreatPetUseCase` |
| `stats_bar_widget.dart` | Añadido indicador de Salud ❤️ (6to stat) y banda de condiciones activas bajo las barras |
| `action_buttons_widget.dart` | Añadido 5to botón "Tienda 🏪" |
| `game_screen.dart` | Header con acceso a tienda, banner actualizado con condiciones activas |
| `dodge_bombs_screen.dart` | Sistema de lesiones post-game según score |
| `sky_jump_screen.dart` | Sistema de lesiones post-game según score |
| `food_drop_screen.dart` | Sistema de lesiones post-game según score |
| `whack_a_pet_screen.dart` | Sistema de lesiones post-game según score |
| `stat_decay_service_test.dart` | Actualizado `setUp` para pasar `IllnessService()` al nuevo constructor |

---

## 4. Cómo funciona el sistema

### 4.1 Condiciones (`ConditionType`)

La mascota puede tener **múltiples condiciones simultáneas** almacenadas en `Pet.conditions`. Cada condición tiene tipo y fecha de contagio.

| Condición | Ícono | Efectos por hora (sobre stats) |
|-----------|-------|-------------------------------|
| `cold` (Resfriado) | 🤧 | health −1.5, mood −0.5 |
| `flu` (Gripe) | 🤒 | health −3.0, mood −2.0 |
| `fever` (Fiebre) | 🥵 | health −5.0, mood −4.0, hunger −2.0 |
| `minorInjury` (Lesión leve) | 🩹 | health −1.0, play −2.0 |
| `seriousInjury` (Lesión grave) | 🤕 | health −2.0, play −4.0, mood −1.5 |
| `exhaustion` (Agotamiento) | 😵 | Multiplica ×1.5 todos los penalizadores anteriores |

Las enfermedades son **progresivas**: si el resfriado no se trata, puede progresar a gripe y luego a fiebre. Nunca se pueden tener dos grados simultáneos de la misma cadena (cold → flu → fever).

### 4.2 Sueño como factor de riesgo

El sueño bajo tiene dos efectos mecánicos:

| Nivel de sueño | Efecto |
|----------------|--------|
| < 40 | Probabilidad de enfermar ×1.5 |
| < 20 | Probabilidad de enfermar ×3.0 |
| < 10 por más de 1 hora | Se activa `exhaustion` automáticamente |

El agotamiento a su vez duplica la probabilidad de contraer otras enfermedades (`×2.0` adicional), creando un ciclo negativo si no se hace dormir a la mascota.

### 4.3 Probabilidad de enfermedad

En cada apertura de la app, `IllnessService.checkForNewConditions()` evalúa si la mascota contrae una nueva condición. La fórmula es:

```
chance = baseChance(0.01/hora) × horasTranscurridas × multiplicadorRiesgo
```

**Multiplicadores de riesgo acumulables:**

| Factor | Multiplicador |
|--------|--------------|
| Mutación `aquaSlime` | ×0.5 (resistente) |
| Mutación `shadowBone` | ×1.5 (frágil) |
| Etapa `baby` | ×1.3 |
| Estado `stressed` | ×1.5 |
| Cleanliness < 25 | ×1.8 |
| Health < 30 | ×2.0 |
| Sleep < 40 | ×1.5 |
| Sleep < 20 | ×3.0 |
| Tiene `exhaustion` | ×2.0 |

### 4.4 Lesiones en minijuegos

Cuatro juegos pueden causar lesiones al terminar. La probabilidad se evalúa según el score final:

| Juego | Score 0 | Score 1–2 | Score ≥ 3 |
|-------|---------|-----------|-----------|
| **Dodge Bombs** | 40% (15% grave / 25% leve) | 20% leve | Sin lesión |
| **Sky Jump** | 25% leve | 12% leve | Sin lesión |
| **Food Drop** | 20% leve | Sin lesión | Sin lesión |
| **Whack-A-Pet** | 10% leve | Sin lesión | Sin lesión |

`Color Tap`, `Memory` y `Reaction Tap` no generan lesiones físicas.

### 4.5 Tienda de medicamentos

Accesible desde el botón **🏪 Tienda** en la barra de acciones o desde el contador de monedas en el header. La tienda muestra las condiciones activas de la mascota y resalta los tratamientos útiles en el momento.

| Ítem | Ícono | Coste | Efecto |
|------|-------|-------|--------|
| Antihistamínico | 💊 | 15 🪙 | Cura `cold` |
| Antibiótico | 🧪 | 35 🪙 | Cura `flu` |
| Antibiótico Fuerte | 💉 | 60 🪙 | Cura `fever` |
| Venda | 🩹 | 20 🪙 | Cura `minorInjury` y `seriousInjury` |
| Vitaminas | 🌿 | 25 🪙 | +20 de salud (sin curar condición específica) |
| Descanso Forzado | 😴 | Gratis | Cura `exhaustion` + +40 sueño |

Si el jugador no tiene monedas suficientes, el botón de compra aparece inactivo (gris).

---

## 5. Pruebas manuales — Sistema de salud y tienda

### 5.1 Pre-condiciones
- Mascota activa en cualquier etapa
- Conocer el saldo de monedas antes de comprar
- Para pruebas de enfermedad por sueño: dejar la mascota sin dormir hasta que `sleep < 10`

### 5.2 Tabla de validación — Condiciones y visualización

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| HS-01 | Indicador de salud visible | 1. Abrir GameScreen | Barra ❤️ aparece como 6to stat junto a hambre, mood, juego, sueño, limpieza | ☐ Pendiente |
| HS-02 | Condición aparece bajo las barras | 1. Forzar una condición (ver HS-07) → 2. Observar el widget de stats | Banda de condiciones activas aparece bajo las barras con ícono y nombre | ☐ Pendiente |
| HS-03 | Banner de advertencia menciona condición | 1. Mascota con condición activa | Banner rojo superior muestra ícono + nombre de condición + "visita la tienda" | ☐ Pendiente |
| HS-04 | Múltiples condiciones visibles | 1. Mascota con lesión + resfriado | Ambas condiciones aparecen en la banda inferior del widget de stats | ☐ Pendiente |
| HS-05 | Estado `sick` cuando hay condición | 1. Mascota con cualquier condición activa | `PetState` es `sick` y la mascota muestra animación triste | ☐ Pendiente |

### 5.3 Tabla de validación — Agotamiento por privación de sueño

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| SL-01 | Agotamiento se activa con sueño crítico | 1. Dejar `sleep` bajar a < 10 sin hacer dormir | Tras ~1 hora de tiempo real, aparece condición `😵 Agotamiento` | ☐ Pendiente |
| SL-02 | Agotamiento amplifica decay | 1. Mascota agotada | Los stats decaen más rápido que sin agotamiento (multiplicador ×1.5) | ☐ Pendiente |
| SL-03 | Descanso Forzado cura el agotamiento | 1. Mascota con agotamiento → 2. Ir a tienda → 3. Usar "Descanso Forzado" (gratis) | Condición de agotamiento desaparece, sueño +40 | ☐ Pendiente |
| SL-04 | Sueño bajo aumenta riesgo de enfermedad | 1. Mantener `sleep` < 20 por varias sesiones | Mayor frecuencia de aparición de resfriado en comparación a mascota con sueño normal | ☐ Pendiente |

### 5.4 Tabla de validación — Progresión de enfermedades

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| IL-01 | Resfriado degrada salud | 1. Mascota con `cold` → 2. No tratar, cerrar app 2 horas → 3. Reabrir | Salud bajó ~3 puntos (1.5/hora × 2 horas) respecto al valor previo | ☐ Pendiente |
| IL-02 | Resfriado puede progresar a gripe | 1. Mascota con `cold` sin tratar por varias sesiones | Eventualmente aparece `flu` reemplazando o junto al `cold` | ☐ Pendiente |
| IL-03 | Gripe degrada salud más rápido | 1. Mascota con `flu` → 2. No tratar, cerrar 2 horas → 3. Reabrir | Salud bajó ~6 puntos (3.0/hora × 2 horas) | ☐ Pendiente |
| IL-04 | Fiebre es la condición más dañina | 1. Mascota con `fever` → 2. No tratar, cerrar 1 hora → 3. Reabrir | Salud −5, mood −4, hunger −2 respecto a valores previos | ☐ Pendiente |
| IL-05 | Mascota no puede tener cold y flu simultáneos | 1. Mascota con `flu` | En la banda de condiciones NO aparece `cold` al mismo tiempo que `flu` | ☐ Pendiente |

### 5.5 Tabla de validación — Tienda

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| ST-01 | Tienda accesible desde botón | 1. GameScreen → 2. Tocar botón 🏪 Tienda | Se abre `StoreScreen` con lista de medicamentos | ☐ Pendiente |
| ST-02 | Tienda accesible desde monedas | 1. GameScreen → 2. Tocar el contador de monedas 🪙 en el header | Se abre `StoreScreen` | ☐ Pendiente |
| ST-03 | Condiciones activas mostradas en tienda | 1. Mascota con condición → 2. Abrir tienda | Banda roja superior muestra las condiciones activas de la mascota | ☐ Pendiente |
| ST-04 | Tratamiento útil resaltado | 1. Mascota con `cold` → 2. Abrir tienda | La tarjeta "Antihistamínico" tiene borde rojo destacado y texto "✓ Útil ahora" | ☐ Pendiente |
| ST-05 | Compra exitosa descuenta monedas | 1. Tener ≥ 15 monedas → 2. Comprar Antihistamínico | Saldo de monedas disminuye en 15, snack verde de confirmación | ☐ Pendiente |
| ST-06 | Compra cura la condición | 1. Mascota con `cold` → 2. Comprar Antihistamínico | La condición `cold` desaparece de la banda de stats en GameScreen | ☐ Pendiente |
| ST-07 | Sin monedas suficientes = botón inactivo | 1. Tener < 35 monedas → 2. Abrir tienda | El botón de compra del Antibiótico aparece gris, no responde al tap | ☐ Pendiente |
| ST-08 | Descanso Forzado es gratuito | 1. Abrir tienda | La tarjeta "Descanso Forzado" muestra botón "USAR" (sin precio en monedas) | ☐ Pendiente |
| ST-09 | Vitaminas suben salud | 1. Tener ≥ 25 monedas → 2. Comprar Vitaminas | `health += 20` en la barra de stats (sin curar condición) | ☐ Pendiente |
| ST-10 | Venda cura lesión grave y leve | 1. Mascota con `seriousInjury` → 2. Comprar Venda (20🪙) | Ambos tipos de lesión son curados si están presentes | ☐ Pendiente |
| ST-11 | Saldo actualizado al volver a GameScreen | 1. Comprar en tienda → 2. Cerrar tienda | El contador de monedas en GameScreen refleja el nuevo saldo | ☐ Pendiente |

### 5.6 Tabla de validación — Lesiones en minijuegos

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| MJ-01 | Dodge Bombs: lesión con score 0 | 1. Jugar Dodge Bombs → 2. Terminar con score 0 (dejar que bomba golpee al inicio) | Repetir 5 veces: al menos 1–2 casos deben mostrar el mensaje de lesión en el Game Over | ☐ Pendiente |
| MJ-02 | Dodge Bombs: lesión grave posible | 1. Score 0 en Dodge Bombs, repetir 10 veces | Al menos 1 caso debe mostrar "Lesión grave 🤕" | ☐ Pendiente |
| MJ-03 | Dodge Bombs: sin lesión con score alto | 1. Terminar Dodge Bombs con score ≥ 5 | Mensaje de lesión NO aparece en el Game Over | ☐ Pendiente |
| MJ-04 | Sky Jump: lesión por caída | 1. Jugar Sky Jump → 2. Caer inmediatamente (score 0) | Repetir 5 veces: al menos 1 caso muestra "🩹 Tu mascota se lastimó al caer" | ☐ Pendiente |
| MJ-05 | Food Drop: lesión por bomba | 1. Jugar Food Drop → 2. Dejar que una bomba golpee de inmediato (score 0) | Repetir 5 veces: al menos 1 caso muestra "🩹 ¡La bomba lastimó a tu mascota!" | ☐ Pendiente |
| MJ-06 | Whack-A-Pet: lesión con score 0 | 1. Jugar Whack-A-Pet → 2. No tocar nada (3 fallos, score 0) | Repetir 10 veces: al menos 1 caso muestra "🩹 Tu mascota recibió un golpe" | ☐ Pendiente |
| MJ-07 | Lesión aplica condición al pet | 1. Obtener lesión en cualquier juego → 2. Volver a GameScreen | Banda de condiciones bajo las barras muestra la lesión activa | ☐ Pendiente |
| MJ-08 | Lesión grave sobreescribe leve | 1. Pet con `minorInjury` → 2. Obtener `seriousInjury` en juego | Solo aparece `seriousInjury` (la leve desaparece) | ☐ Pendiente |
| MJ-09 | Color Tap sin lesión | 1. Terminar Color Tap con cualquier score | No aparece ningún mensaje de lesión en el Game Over | ☐ Pendiente |
| MJ-10 | Memory sin lesión | 1. Terminar Memory con cualquier score | No aparece ningún mensaje de lesión en el Game Over | ☐ Pendiente |
| MJ-11 | Reaction Tap sin lesión | 1. Terminar Reaction Tap con cualquier score | No aparece ningún mensaje de lesión en el Game Over | ☐ Pendiente |

---

## 6. Pruebas de persistencia — Condiciones entre sesiones

| ID | Escenario | Pasos | Resultado esperado |
|----|-----------|-------|--------------------|
| PS-01 | Condición persiste al cerrar app | 1. Mascota con `cold` → 2. Cerrar app completamente → 3. Reabrir | La condición `cold` sigue activa y visible | ☐ Pendiente |
| PS-02 | Condición curada persiste | 1. Curar condición en tienda → 2. Cerrar app → 3. Reabrir | La condición curada ya no aparece | ☐ Pendiente |
| PS-03 | Mascota existente (sin condiciones guardadas) no crashea | 1. Pet creada antes de esta versión → 2. Actualizar app → 3. Abrir | App abre normalmente, mascota sin condiciones, sin crash (backward-compatible por defaults en Hive) | ☐ Pendiente |
| PS-04 | Condición acumula decay offline | 1. Mascota con `fever` → 2. Cerrar app 3 horas → 3. Reabrir | Salud bajó ~15 puntos adicionales (5.0/hora × 3h) respecto al valor previo al cerrar | ☐ Pendiente |

---

## 7. Notas técnicas para el equipo

### Backward compatibility con Hive
Los nuevos campos `HiveField(15)` y `HiveField(16)` tienen valores por defecto de lista vacía en `pet_model.g.dart`. Mascotas guardadas con la versión anterior cargarán sin condiciones, lo que es el comportamiento correcto.

### Probabilidades de enfermedad
Las enfermedades son probabilísticas. Para QA manual acelerado, se puede reducir temporalmente `_baseChancePerHour` de `0.01` a `0.5` en `illness_service.dart` y aumentar `hoursElapsed` simulando más tiempo. Revertir antes del PR.

### El test existente puede ser levemente no-determinista
`stat_decay_service_test.dart` ahora usa el `IllnessService` real (con `Random()`). Los tests que verifican `PetState.happy` tienen un ~1% de falso negativo si la mascota contrae una condición durante el test. Es aceptable para esta etapa; en el futuro se puede inyectar un `Random` semillado.
