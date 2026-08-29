# 💍 Nuestra Boda — WebApp de gestión integral de bodas

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Functions-FFCA28?logo=firebase&logoColor=black)
![Cloudflare R2](https://img.shields.io/badge/Storage-Cloudflare%20R2-F38020?logo=cloudflare&logoColor=white)
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
- **Firebase**: Authentication, Cloud Firestore (plan gratuito Spark — sin tarjeta, sin plan Blaze)
- **Cloudflare R2** — almacenamiento de archivos (fotos, documentos). Se usa en vez de Firebase Storage porque, desde feb. 2026, Firebase exige el plan Blaze (tarjeta vinculada) solo para aprovisionar un bucket, aunque el consumo real sea $0.
- **Cloudflare Worker** — firma las URLs de subida hacia R2. Se usa en vez de Firebase Cloud Functions porque **desplegar cualquier Cloud Function también exige Blaze** (usa Cloud Build + Artifact Registry por debajo) — así que no evitaba el problema, solo lo movía. El Worker corre en el plan gratis de Cloudflare (100K requests/día, sin tarjeta).
- **Riverpod** — gestión de estado
- **go_router** — navegación con guards por rol
- **Spotify Web API** — búsqueda de canciones (sin reproducir ni almacenar audio)

### Sobre la Fase 4 — nota de robustez pendiente

El dashboard combina 7 streams de Firestore en uno solo (presupuesto, gastos, ahorro, invitados, tareas, proveedores + la boda). Si el usuario es colaborador y le falta permiso sobre alguno de esos módulos, esa lectura específica falla y **rompe el stream combinado completo** (el dashboard se cae, no solo esa sección). Para el MVP (solo ustedes dos como "novios" con acceso total) esto no aplica, pero antes de dar acceso real a colaboradores con permisos parciales hay que hacer que cada sección falle de forma aislada en vez de tumbar todo el dashboard.

### Sobre la Fase 3 — nota de seguridad pendiente

Crear boda y aceptar invitaciones se resuelve hoy con escrituras batch directas desde el cliente (ver `WeddingRepositoryImpl`), protegidas por `firestore.rules`. Es suficiente para el MVP, pero antes de abrir el proyecto a más gente que solo su propia boda conviene mover ambas operaciones a un endpoint server-side propio — así la validación de "solo puedes crear tu propia membresía inicial" vive en el servidor, no en reglas declarativas que confían en la forma del payload.

### Sobre el almacenamiento de archivos (sin plan Blaze)

Ni Firebase Storage ni Firebase Cloud Functions se pueden usar sin vincular tarjeta (plan Blaze), sin importar que el consumo real sea $0 — es un requisito de aprovisionamiento de Google, no de uso. Este proyecto evita Blaze por completo:

- **Auth + Firestore** se quedan en Firebase (Spark, gratis, sin tarjeta) — no los toca esta restricción.
- **Archivos** (fotos, documentos) van a **Cloudflare R2** (10GB gratis, cero costo de salida, sin tarjeta).
- **Firmar las URLs de subida** (necesario porque el secret de R2 no puede vivir en el cliente) lo hace un **Cloudflare Worker** en `/cloudflare-worker` (100K requests/día gratis, sin tarjeta) — no una Cloud Function de Firebase.

⚠️ El Worker valida el Firebase ID Token del usuario contra `aud` (proyecto) y `exp` (expiración), pero el código actual **no verifica la firma RS256 completa** (ver comentario en `cloudflare-worker/src/index.ts`). Es suficiente para desarrollo, pero antes de producción real hay que agregar verificación de firma con una librería como `jose` o `firebase-auth-cloudflare-workers`.

## 🗺️ Roadmap por fases

- [x] **Fase 1** — Arquitectura, modelo de datos, roles y MVP
- [x] **Fase 2** — Setup del proyecto + Auth base + Routing
- [x] **Fase 3** — Registro, creación de boda, invitar colaboradores
- [x] **Fase 4** — Dashboard (cuenta regresiva, finanzas, invitados, organización, alertas)
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
- Cuenta de Firebase (plan gratuito Spark — **nunca subir a Blaze**, no hace falta)
- Cuenta gratuita de Cloudflare
- Node.js (para el Firebase CLI y Wrangler)

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Crear el proyecto en Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → **Crear proyecto** (plan Spark)
2. Activar **Authentication** (Email/Password) y **Firestore Database** (modo producción)
3. No actives Cloud Storage ni Cloud Functions — ninguno de los dos se usa en este proyecto (ambos exigirían Blaze)

### 3. Crear el bucket en Cloudflare R2

1. Cuenta gratuita en [dash.cloudflare.com](https://dash.cloudflare.com) → **R2** → **Create bucket** (nómbralo `vowly-wedding-files`)
2. En **Settings** del bucket, activa un dominio público (o usa el subdominio `r2.dev` que da Cloudflare) — esa URL es tu `R2_PUBLIC_BASE_URL`
3. **R2 → Manage API tokens** → crea un token con permiso de lectura/escritura sobre ese bucket → guarda el **Access Key ID** y el **Secret Access Key**
4. Anota tu **Account ID** (dashboard de Cloudflare, panel derecho)

### 4. Desplegar el Cloudflare Worker (firma las URLs de subida)

```bash
cd cloudflare-worker
npm install

npx wrangler login
```

Completa `wrangler.toml` con tu `R2_ACCOUNT_ID`, `R2_BUCKET_NAME` y `R2_PUBLIC_BASE_URL` (no son secretos, van en texto plano). Los que sí son secretos:

```bash
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
```

Despliega:

```bash
npx wrangler deploy
```

Te da una URL tipo `https://vowly-storage-worker.tu-cuenta.workers.dev` — guárdala, la necesitas en el paso 7.

### 5. Conectar el proyecto Flutter con Firebase

```bash
npm install -g firebase-tools
firebase login
firebase use --add   # elige tu proyecto de Firebase

dart pub global activate flutterfire_cli
flutterfire configure
```

Esto reemplaza el placeholder en `lib/data/firebase/firebase_options.dart` con las credenciales reales (ese archivo está en `.gitignore`, no se sube al repo).

### 6. Generar modelos (a partir de Fase 3)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 7. Desplegar Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### 8. Correr la app

Pásale la URL del Worker que guardaste en el paso 4:

```bash
flutter run -d chrome --dart-define=STORAGE_WORKER_URL=https://vowly-storage-worker.tu-cuenta.workers.dev
```


```bash
flutter run -d chrome
```

---

## 📄 Licencia

MIT — ver [LICENSE](LICENSE)

## 👤 Autor

**César León** — [@CesarLeon551](https://github.com/CesarLeon551)
