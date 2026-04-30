<div align="center">

```
██╗  ██╗██╗   ██╗ ██████╗ ███╗   ███╗
██║  ██║██║   ██║██╔═══██╗████╗ ████║
███████║██║   ██║██║   ██║██╔████╔██║
██╔══██║██║   ██║██║   ██║██║╚██╔╝██║
██║  ██║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝
```

### Your virtual pet. Your pixel world.

![Flutter](https://img.shields.io/badge/Flutter-3.41.3-02569B?style=flat-square&logo=flutter)
![Flame](https://img.shields.io/badge/Flame-1.18.0-orange?style=flat-square)
![Dart](https://img.shields.io/badge/Dart-3.3.0+-0175C2?style=flat-square&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## What is HUOM?

HUOM is a virtual pet game inspired by **Tamagotchi**, built in Flutter using the **Flame** game engine. Hatch your pet from an egg, take care of it, play with it, and watch it evolve into one of **7 unique mutations** based on how you treat it.

Every pet has its own story. Some live for decades. Others die young. All of them are remembered.

---

## Features

| | |
|---|---|
| 🥚 **Full life cycle** | Egg → Baby → Adult → Elder → Death |
| 🧬 **7 dynamic mutations** | Evolution depends on how you raise your pet |
| 📊 **5 real-time stats** | Hunger, Mood, Play, Sleep, Health |
| ⏱️ **Offline decay** | Stats drop even when the app is closed |
| 🎮 **Jump Rope minigame** | Earn coins by skipping rope |
| 🪙 **Coin system** | Persistent rewards across sessions |
| 🌅 **Day/night cycle** | Background changes based on real time |
| 🪦 **Memorial** | Every pet you've lost is remembered |

---

## Life Cycle

```
        🥚 Egg
           │
           ▼
        🐣 Baby   ◄── Accumulated stats determine mutation
           │
           ▼
   🧬 Evolution  ◄── Spectacular animation!
           │
           ▼
      🐾 Adult
           │
           ▼
       👴 Elder   (slower decay, max 30 days)
           │
           ▼
        💀 Death  ──► 🪦 Memorial
```

Your pet can also die from **neglect**:
- Hunger at 0 for more than 6 hours
- Health at 0 for more than 12 hours

---

## The 7 Mutations

Mutation is determined at the end of the **Baby** stage, based on your average stats:

| Mutation | Condition | Playstyle |
|---|---|---|
| 🟢 **Slime Bit** | Balanced care | Neutral, no modifiers |
| 🌵 **Cactus Rex** | Hunger & sleep < 40 | Tough but grumpy |
| 💧 **Aqua Slime** | Health > 75 & mood > 60 | Healthy and stable |
| ⚡ **Thunder Leaf** | Play > 70 | Athletic, eats more |
| 🌸 **Blossom** | Mood > 75 | Naturally happy |
| 💀 **Shadow Bone** | Health < 30 consistently | Hard to keep alive |
| ⚠️ **Glitch Pet** | Overall average < 65 | Chaotic and unpredictable |

---

## Stats

Each stat decays naturally over time:

| Stat | Icon | Base decay | Restored by |
|---|---|---|---|
| Hunger | 🍖 | 3.0 pts/hour | Feeding |
| Mood | 😊 | 1.5 pts/hour | Playing |
| Play | 🎯 | 2.0 pts/hour | Playing |
| Sleep | 😴 | 2.5 pts/hour | Sleeping |
| Health | ❤️ | Variable | Overall care |

> Decay multipliers change based on **life stage** and **active mutation**.

### Emotional states

- **😊 Happy** — Everything is fine
- **😰 Stressed** — Hunger < 25 or sleep < 15
- **🤒 Sick** — Health < 20
- **💀 Dead** — Game over

---

## Minigame: Jump Rope 🎮

An arcade minigame where you jump rope and dodge obstacles. Coins earned depend on your score:

| Score | Coins |
|---|---|
| ≥ 20 points | 🪙 30 coins |
| ≥ 10 points | 🪙 20 coins |
| ≥ 5 points | 🪙 15 coins |
| < 5 points | 🪙 5 coins |

Playing also increases your pet's **Play** stat.

---

## Tech Stack

```
Flutter 3.41.3
├── flame ^1.18.0           — Game engine (sprites, animations, physics)
├── flame_audio ^2.10.0     — Audio and sound effects
├── flutter_riverpod ^2.5.0 — State management
├── hive + hive_flutter     — Local persistence (pet data, coins)
├── go_router ^14.1.4       — Navigation
└── get_it ^7.7.0           — Dependency injection
```

### Architecture

```
lib/
├── core/
│   ├── di/            — Dependency injection (GetIt)
│   ├── services/      — StatDecay, Coins, Mutation, MutationHistory
│   └── theme/         — Colors and dark/pixel theme
├── features/
│   ├── pet/
│   │   ├── domain/    — Entities, repositories, use cases
│   │   ├── data/      — Hive models, implementations
│   │   └── presentation/ — Screens, providers, widgets
│   ├── memorial/      — Deceased pets system
│   └── store/         — Coin system
└── game/
    ├── pet_flame_game.dart  — Main Flame game
    ├── pet_component.dart   — Animated pet sprite
    └── minigames/           — Jump Rope
```

---

## Getting Started

### Requirements

- Flutter SDK 3.41.3+
- Android Studio or VS Code
- Android device / Emulator / Chrome

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/IIAteeneaaII/huom_flutter_V1.git
cd huom_flutter_V1

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome (no extra setup needed)
flutter run -d chrome

# 4. Run on Android
flutter run
```

### Enabling Firebase (optional)

Firebase is temporarily disabled. To enable it:

1. Create a project in [Firebase Console](https://console.firebase.google.com)
2. Download `google-services.json` and place it in `android/app/`
3. Uncomment the dependencies in `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.3.0
   firebase_analytics: ^11.2.1
   firebase_crashlytics: ^4.0.4
   firebase_messaging: ^15.0.4
   flutter_local_notifications: ^17.2.1+2
   ```
4. Run `flutter pub get`

---

## Pet Animations

Sprites use **192×192px** sheets with a 48px grid:

| Row | Animation | Frames | Speed |
|---|---|---|---|
| 0 | Idle | 4 | 0.20s/frame |
| 1 | Eat | 4 | 0.15s/frame |
| 2 | Sleep | 4 | 0.30s/frame |
| 3 | Sad | 3 | 0.25s/frame |

The **Egg** state uses `egg.png` (96×48px, 2 frames) with a pulse animation.

---

## Roadmap

- [ ] Item shop powered by coins
- [ ] More minigames
- [ ] More mutations and biomes
- [ ] Push notifications when stats are critical
- [ ] Multiplayer / pet comparison

---

<div align="center">

Made with ❤️ and lots of pixel art

*"Every pet is unique. Take good care of it."*

</div>
