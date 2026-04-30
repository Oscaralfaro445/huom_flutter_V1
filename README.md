<div align="center">

```
██╗  ██╗██╗   ██╗ ██████╗ ███╗   ███╗
██║  ██║██║   ██║██╔═══██╗████╗ ████║
███████║██║   ██║██║   ██║██╔████╔██║
██╔══██║██║   ██║██║   ██║██║╚██╔╝██║
██║  ██║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝
```

### Tu mascota virtual. Tu mundo pixel.

![Flutter](https://img.shields.io/badge/Flutter-3.41.3-02569B?style=flat-square&logo=flutter)
![Flame](https://img.shields.io/badge/Flame-1.18.0-orange?style=flat-square)
![Dart](https://img.shields.io/badge/Dart-3.3.0+-0175C2?style=flat-square&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## ¿Qué es HUOM?

HUOM es un juego de mascota virtual al estilo **Tamagotchi**, construido en Flutter con el motor de juegos **Flame**. Crea tu mascota desde un huevo, cuídala, juega con ella y observa cómo evoluciona en una de **7 mutaciones únicas** según cómo la hayas tratado.

Cada mascota tiene su propia historia. Algunas viven décadas. Otras mueren jóvenes. Todas son recordadas.

---

## Características

| | |
|---|---|
| 🥚 **Ciclo de vida completo** | Huevo → Cría → Adulto → Anciano → Muerte |
| 🧬 **7 mutaciones dinámicas** | La evolución depende de cómo cuidas a tu mascota |
| 📊 **5 estadísticas en tiempo real** | Hambre, Humor, Juego, Sueño, Salud |
| ⏱️ **Decay offline** | Las stats bajan aunque la app esté cerrada |
| 🎮 **Minijuego: Jump Rope** | Gana monedas saltando la cuerda |
| 🪙 **Sistema de monedas** | Recompensas persistentes entre sesiones |
| 🌅 **Ciclo día/noche** | El fondo cambia según la hora real |
| 🪦 **Memorial** | Todas tus mascotas fallecidas quedan registradas |

---

## Ciclo de vida

```
        🥚 Huevo
           │
           ▼
        🐣 Cría  ◄── Stats acumulados definen la mutación
           │
           ▼
   🧬 Evolución  ◄── ¡Animación espectacular!
           │
           ▼
      🐾 Adulto
           │
           ▼
       👴 Anciano  (decay más lento, máx 30 días)
           │
           ▼
        💀 Muerte  ──► 🪦 Memorial
```

La mascota también puede morir por **negligencia**:
- Hambre en 0 por más de 6 horas
- Salud en 0 por más de 12 horas

---

## Las 7 Mutaciones

La mutación se determina al final de la etapa de **Cría**, según el promedio de tus stats:

| Mutación | Condición | Estilo de juego |
|---|---|---|
| 🟢 **Slime Bit** | Cuidado equilibrado | Neutral, sin modificadores |
| 🌵 **Cactus Rex** | Hambre y sueño < 40 | Resistente pero gruñón |
| 💧 **Aqua Slime** | Salud > 75 y humor > 60 | Saludable y estable |
| ⚡ **Thunder Leaf** | Juego > 70 | Atlética, come más |
| 🌸 **Blossom** | Humor > 75 | Feliz naturalmente |
| 💀 **Shadow Bone** | Salud < 30 consistentemente | Difícil de cuidar |
| ⚠️ **Glitch Pet** | Promedio general < 65 | Caótica e impredecible |

---

## Estadísticas

Cada stat decae con el tiempo de forma natural:

| Stat | Icono | Decay base | Se recupera con |
|---|---|---|---|
| Hambre | 🍖 | 3.0 pts/hora | Alimentar |
| Humor | 😊 | 1.5 pts/hora | Jugar |
| Juego | 🎯 | 2.0 pts/hora | Jugar |
| Sueño | 😴 | 2.5 pts/hora | Dormir |
| Salud | ❤️ | Variable | Cuidado general |

> Los multiplicadores de decay cambian según la **etapa de vida** y la **mutación**.

### Estados emocionales

- **😊 Happy** — Todo en orden
- **😰 Stressed** — Hambre < 25 o sueño < 15
- **🤒 Sick** — Salud < 20
- **💀 Dead** — Game over

---

## Minijuego: Jump Rope 🎮

Un minijuego arcade donde debes saltar la cuerda y evitar obstáculos. Las monedas ganadas dependen de tu puntuación:

| Puntuación | Monedas |
|---|---|
| ≥ 20 puntos | 🪙 30 monedas |
| ≥ 10 puntos | 🪙 20 monedas |
| ≥ 5 puntos | 🪙 15 monedas |
| < 5 puntos | 🪙 5 monedas |

Jugar también sube el stat de **Juego** de tu mascota.

---

## Stack tecnológico

```
Flutter 3.41.3
├── flame ^1.18.0           — Motor de juego (sprites, animaciones, física)
├── flame_audio ^2.10.0     — Audio y efectos de sonido
├── flutter_riverpod ^2.5.0 — State management
├── hive + hive_flutter     — Persistencia local (mascota, monedas)
├── go_router ^14.1.4       — Navegación
└── get_it ^7.7.0           — Inyección de dependencias
```

### Arquitectura

```
lib/
├── core/
│   ├── di/            — Inyección de dependencias (GetIt)
│   ├── services/      — StatDecay, Coins, Mutation, MutationHistory
│   └── theme/         — Colores y tema dark/pixel
├── features/
│   ├── pet/
│   │   ├── domain/    — Entidades, repositorios, casos de uso
│   │   ├── data/      — Modelos Hive, implementaciones
│   │   └── presentation/ — Screens, providers, widgets
│   ├── memorial/      — Sistema de mascotas fallecidas
│   └── store/         — Sistema de monedas
└── game/
    ├── pet_flame_game.dart  — Juego principal Flame
    ├── pet_component.dart   — Sprite animado de la mascota
    └── minigames/           — Jump Rope
```

---

## Instalación y setup

### Requisitos

- Flutter SDK 3.41.3+
- Android Studio o VS Code
- Dispositivo Android / Emulador / Chrome

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/IIAteeneaaII/huom_flutter_V1.git
cd huom_flutter_V1

# 2. Instalar dependencias
flutter pub get

# 3. Correr en Chrome (sin configuración adicional)
flutter run -d chrome

# 4. Correr en Android
flutter run
```

### Para habilitar Firebase (opcional)

Firebase está temporalmente desactivado. Para activarlo:

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Descarga `google-services.json` y colócalo en `android/app/`
3. Descomenta las dependencias en `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.3.0
   firebase_analytics: ^11.2.1
   firebase_crashlytics: ^4.0.4
   firebase_messaging: ^15.0.4
   flutter_local_notifications: ^17.2.1+2
   ```
4. Corre `flutter pub get`

---

## Animaciones de la mascota

Los sprites usan sheets de **192×192px** con grillas de 48px:

| Fila | Animación | Frames | Velocidad |
|---|---|---|---|
| 0 | Idle | 4 | 0.20s/frame |
| 1 | Comer | 4 | 0.15s/frame |
| 2 | Dormir | 4 | 0.30s/frame |
| 3 | Triste | 3 | 0.25s/frame |

El estado **Huevo** usa `egg.png` (96×48px, 2 frames) con animación de pulsación.

---

## Roadmap

- [ ] Tienda de items con monedas
- [ ] Más minijuegos
- [ ] Más mutaciones y biomas
- [ ] Notificaciones push (cuando las stats estén críticas)
- [ ] Modo multijugador / comparar mascotas

---

<div align="center">

Hecho con ❤️ y mucho pixel art

*"Cada mascota es única. Cuídala bien."*

</div>
