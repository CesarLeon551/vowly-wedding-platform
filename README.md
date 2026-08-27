# 💍 Nuestra Boda — WebApp de gestión integral de bodas

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6C4EE0)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-En%20desarrollo-orange)

WebApp responsive para administrar en un solo lugar toda la organización de una boda: presupuesto, ahorro, invitados, RSVP, proveedores, tareas, mesas, cronograma, página pública y una **playlist colaborativa con integración oficial a la API de Spotify**. Pensada primero para uso personal y con una arquitectura preparada para evolucionar a una plataforma multi-tenant.

Proyecto propio, construido con **arquitectura limpia (Clean Architecture)** y con el objetivo explícito de mantener el costo de infraestructura en **$0**, usando únicamente el plan gratuito de Firebase.

---

## ✨ Funcionalidades (alcance completo del proyecto)

| Módulo | Descripción |
|---|---|
| 💰 Presupuesto y gastos | Categorías, anticipos, saldos, comprobantes |
| 💵 Ahorro | Meta de ahorro con proyección + mecánica de "rasca y gana" gamificada |
| 👥 Invitados | Grupos, acompañantes, restricciones alimentarias |
| 📲 RSVP público | Página sin login para que los invitados confirmen asistencia |
| 🏪 Proveedores | Contratos, cotizaciones, estado de pago por proveedor |
| 📋 Tareas | Checklist con prioridad y fechas límite |
| 🪑 Mesas | Organizador visual de acomodo con detección de sobrecupo |
| 📅 Cronograma | Timeline del día del evento |
| 🌐 Página pública | Landing personalizable por boda (`/boda/nombre-de-la-pareja`) |
| 🎵 Música + Spotify | Búsqueda oficial vía Spotify API, playlist colaborativa con votos, categorías por momento del evento |
| 📸 Galería | Subida de fotos por invitados vía QR, con compresión de imagen |
| 📄 Documentos | Almacenamiento privado de contratos y comprobantes |
| 🔔 Notificaciones | Recordatorios internos de pagos y tareas |
| 📊 Estadísticas | Progreso general del evento |
| 🤖 IA (roadmap) | Arquitectura preparada para un asistente que consulte los datos del evento |

## 🔐 Roles

- **Novios** — administración completa
- **Colaboradores** — acceso configurable módulo por módulo
- **Invitados** — solo funciones públicas (info del evento, RSVP, música)

## 🏗️ Arquitectura

Clean Architecture con separación estricta por capas y por feature — nada de lógica de negocio mezclada con Firebase ni con la UI:

```
lib/
├── app/          # routing (go_router), tema, entrypoint de la app
├── core/         # constantes, errores, utilidades compartidas
├── data/         # implementación Firebase (models, repositories)
├── domain/       # entidades y contratos, sin dependencias de Firebase
└── features/     # una carpeta por módulo (auth, budget, guests, music...)
```

**Por qué así:** si mañana cambia el backend, o el proyecto crece a una plataforma multi-tenant para otras parejas, solo se reescribe `data/` — el dominio y la UI no se tocan.

## 🛠️ Stack

- **Flutter Web + Dart**
- **Firebase**: Authentication, Cloud Firestore, Storage, Hosting (plan gratuito Spark)
- **Riverpod** — gestión de estado
- **go_router** — navegación con guards por rol
- **Spotify Web API** — búsqueda de canciones (sin reproducir ni almacenar audio)

## 🗺️ Roadmap por fases

- [x] **Fase 1** — Arquitectura, modelo de datos, roles y MVP
- [x] **Fase 2** — Setup del proyecto + Auth base + Routing
- [ ] Fase 3 — Registro, creación de boda, invitar colaboradores
- [ ] Fase 4 — Dashboard
- [ ] Fase 5 — Presupuesto y ahorro
- [ ] Fase 6 — Invitados y RSVP
- [ ] Fase 7 — Playlist y Spotify
- [ ] Fase 8 — Proveedores y tareas
- [ ] Fase 9 — Página pública
- [ ] Fase 10 — Mesas y cronograma
- [ ] Fase 11 — Galería y documentos
- [ ] Fase 12 — Notificaciones
- [ ] Fase 13 — Estadísticas
- [ ] Fase 14 — Asistente con IA

---

## 🚀 Setup local

### Requisitos

- Flutter SDK (canal stable) — `flutter --version`
- Cuenta de Firebase (plan gratuito Spark)
- Node.js (para el Firebase CLI)

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Crear el proyecto en Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → **Crear proyecto** (plan Spark)
2. Activar **Authentication** (Email/Password), **Firestore Database** (modo producción) y **Storage**

### 3. Conectar el proyecto Flutter con Firebase

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
flutterfire configure
```

Esto reemplaza el placeholder en `lib/data/firebase/firebase_options.dart` con las credenciales reales (ese archivo está en `.gitignore`, no se sube al repo).

### 4. Generar modelos (a partir de Fase 3)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Desplegar Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### 6. Correr la app

```bash
flutter run -d chrome
```

---

## 📄 Licencia

MIT — ver [LICENSE](LICENSE)

## 👤 Autor

**César León** — [@CesarLeon551](https://github.com/CesarLeon551)
