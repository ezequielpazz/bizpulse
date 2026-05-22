# CLAUDE.md — BizPulse · Sistema de Trabajo Multi-Agente

---

## DATOS DEL PROYECTO

- **Nombre:** BizPulse
- **Descripción corta:** App de gestión para profesionales de servicios en LATAM (agenda, stock, finanzas)
- **Stack tecnológico:** Flutter 3.41.2 / Dart 3.11.0 · Firebase Auth + Firestore · SQLite (sqflite) · Provider
- **Plataforma:** Android (Play Store) · Package: `com.impro.app`
- **Estado actual:** Free v1.0 — AAB release generado, listo para publicar en Play Store
- **Repositorio:** https://github.com/ezequielpazz/bizpulse
- **Dispositivos de prueba:** Xiaomi MIUI (`g6ifz5cyjnpbtgrw`) · Samsung Galaxy A51 Android 13 (`R58N33CXCMR`)

---

## ARQUITECTURA DE EQUIPO

```
┌─────────────────────────────────────────────────────┐
│                  JARVIS 1 (Chat)                    │
│          Arquitecto · Planificador · Director       │
│                                                     │
│  - Define la visión del proyecto                    │
│  - Toma decisiones de arquitectura                  │
│  - Diseña el roadmap y las fases                    │
│  - Aprueba o rechaza propuestas de los otros Jarvis │
│  - Resuelve conflictos entre agentes                │
│  - No toca código ni archivos directamente          │
└──────────┬──────────────────┬───────────────────────┘
           │                  │
           ▼                  ▼
┌────────────────────┐ ┌──────────────────────┐
│  JARVIS 2 (Cowork) │ │  JARVIS 3 (Code)     │
│  Contenido · Docs  │ │  Desarrollo · Código │
└────────┬───────────┘ └──────────┬───────────┘
         │                        │
         │   ┌──────────────┐     │
         └──►│changelog.md  │◄────┘
             └──────────────┘
```

---

## CONTEXTO ESPECÍFICO DEL PROYECTO

### Objetivo principal
Plataforma SaaS de gestión integral para profesionales de servicios en LATAM.
Monetización: Free (ads) → Pro USD 10/mes (cloud sync) → Enterprise USD 20/mes (multiusuario).

### Audiencia / Usuario target
Peluqueros, barberos, esteticistas, tatuadores, manicuras, masajistas, veterinarios,
psicólogos, abogados, contadores — cualquier profesional independiente de servicios en LATAM.

### Modelo de datos principal
```
Usuario (Firebase Auth)
├── Appointments (Firestore: users/{uid}/appointments)
├── Clients      (Firestore: users/{uid}/clients)
├── Services     (Firestore: users/{uid}/services)
├── Supplies     (SQLite local: supplies)
├── Products     (SQLite local: products)
└── Transactions (SQLite local: transactions)
```

### Servicios externos
- **Firebase Auth** — autenticación email/password
- **Cloud Firestore** — agenda, clientes, catálogo de servicios
- **SQLite (sqflite)** — insumos, productos, finanzas (offline-first)
- **flutter_local_notifications** — recordatorios de turnos
- **google_mobile_ads** — publicidad en plan Free
- **purchases_flutter** — RevenueCat para suscripciones Pro/Enterprise (pendiente integración)
- **Google AdMob** — pub-6053361862857322

### Planes y límites
| Plan | Precio | Estado |
|------|--------|--------|
| Free | $0 (con ads) | ✅ Implementado |
| Pro | USD 10/mes | 🔲 Pendiente (backend cloud) |
| Enterprise | USD 20/mes | 🔲 Pendiente (multiusuario) |

### Roadmap / Fases
- **Fase 1 (ACTUAL):** Free v1.0 — publicar en Play Store ← ESTAMOS AQUÍ
- **Fase 2:** Pro v1 — sync cloud multi-dispositivo, sin ads, backup automático
- **Fase 3:** Add-on Bot WhatsApp — recordatorios automáticos por WA
- **Fase 4:** Enterprise — multiusuario, roles, auditoría, reportes por local

---

## ESTRUCTURA DE CARPETAS

```
lib/
├── firebase_options.dart
├── main.dart
├── helpers/
│   └── vocabulary_helper.dart        ← adapta términos por tipo de negocio
├── models/
│   ├── appointment.dart
│   ├── client_model.dart
│   ├── product.dart
│   ├── service_model.dart
│   ├── supply.dart
│   ├── transaction_model.dart
│   └── user_plan.dart
├── providers/
│   └── app_settings.dart             ← tema, colores, businessType, stealthMode
├── services/
│   ├── ad_service.dart
│   ├── appointment_service.dart      ← Firestore
│   ├── auth_service.dart
│   ├── backup_service.dart           ← export/import JSON
│   ├── client_service.dart           ← Firestore
│   ├── feature_gate.dart             ← control de features por plan
│   ├── finance_service.dart
│   ├── notification_service.dart     ← flutter_local_notifications
│   ├── product_service.dart          ← SQLite
│   ├── service_catalog_service.dart  ← Firestore
│   ├── subscription_service.dart     ← RevenueCat (pendiente)
│   ├── supply_service.dart           ← SQLite
│   └── user_service.dart
├── views/
│   ├── account/                      ← perfil, backup, settings
│   ├── agenda/                       ← turnos diario/semanal
│   ├── auth/                         ← login, registro
│   ├── clients/                      ← CRUD clientes
│   ├── dashboard/                    ← 4 cards resumen
│   ├── finance/                      ← ingresos/egresos
│   ├── inventory/                    ← insumos con alertas
│   ├── onboarding/                   ← wizard inicial
│   ├── plans/                        ← pantalla de planes
│   ├── products/                     ← productos de venta
│   ├── reports/                      ← reporte mensual
│   ├── services/                     ← catálogo de servicios
│   ├── shell/                        ← navegación principal
│   └── splash/                       ← splash screen
└── widgets/
    └── ad_banner.dart
```

---

## BUILD CONFIG

```
applicationId:   com.impro.app
minSdk:          24 (Android 7.0)
versionCode:     1
versionName:     1.0.0
JDK:             17 (C:\Program Files\Microsoft\jdk-17.0.17.10-hotspot)
Flutter:         C:\Users\javie\flutter\bin
AGP:             8.9.1
Gradle:          8.11.1
Kotlin:          2.1.0
Keystore:        android/app/impro-release.jks (alias: impro)
AAB release:     build\app\outputs\bundle\release\app-release.aab
```

---

## ROLES Y RESPONSABILIDADES

### JARVIS 1 — El Arquitecto (este chat)
- Planifica, decide arquitectura, genera tareas para Jarvis 2 y 3
- Recibe reportes y define siguientes pasos
- NO toca archivos ni escribe código

### JARVIS 2 — El Creativo (Cowork)
**Qué hace en BizPulse:**
- Textos de marketing (Play Store, redes, landing)
- Documentación para usuarios (FAQ, guías de uso)
- Política de privacidad y textos legales
- Contenido de onboarding y mensajes de la app
- Investigación de competidores y propuestas de mejora UX

**Qué NO hace:**
- No toca archivos `.dart`, `.gradle`, `.xml`, `.json` de config
- No modifica código ni configuraciones técnicas
- No corre comandos de build/test

**Reglas:**
- Anotar cambios en `docs/changelog-content.md`
- Revisar archivos existentes antes de crear nuevos
- Seguir el tono: directo, profesional, latinoamericano (voseo)

### JARVIS 3 — El Desarrollador (Code)
**Qué hace en BizPulse:**
- Implementa features de Flutter (Dart)
- Configura dependencias en `pubspec.yaml`
- Maneja Firebase, SQLite, notificaciones
- Debuggea crashes y errores de runtime
- Genera builds (debug APK, release AAB)
- Hace commits y push a GitHub

**Qué NO hace:**
- No genera contenido de usuario ni textos de marketing
- No toma decisiones de arquitectura sin consultar a Jarvis 1

**Reglas de calidad:**
- Siempre leer archivos completos antes de editar
- Mostrar solo diffs, nunca reescribir sin que se pida
- Agregar try/catch + `if (!mounted) return` después de cada await
- Nunca usar `AnimationController` fuera de un State con TickerProvider
- Responder en español
- Cada tarea debe compilar antes de reportar como terminada
- Hacer commit con mensaje descriptivo después de cada fix

---

## SISTEMA DE COMUNICACIÓN

### Canal principal: El humano
```
Jarvis 3 termina → reporta → humano pasa a Jarvis 1
→ Jarvis 1 decide → humano pasa tarea a Jarvis 3
```

### Canal asíncrono: docs/changelog-content.md
**Formato:**
```markdown
## [FECHA] Cambio #N
- **Archivo:** ruta
- **Acción:** creado / modificado / eliminado
- **Qué cambió:** descripción
- **Impacto en código:** ninguno / revisar X
```

---

## FLUJO DE TRABAJO

### Loop de desarrollo
```
1. Jarvis 1 define tarea
2. Humano se la pasa a Jarvis 3 (Code)
3. Jarvis 3 implementa y reporta
4. Humano pasa reporte a Jarvis 1
5. Jarvis 1 evalúa y da siguiente tarea
6. Repetir
```

---

## REGLAS GLOBALES

1. **Una tarea por vez.** No adelantarse.
2. **Reportar siempre** al terminar: qué se hizo, decisiones tomadas, qué no se verificó.
3. **No romper lo que funciona.**
4. **Preguntar antes de asumir** en decisiones no obvias.

---

## ESTADO ACTUAL DEL PROYECTO (Free v1.0)

### ✅ Completado
- Dashboard con 4 cards
- Agenda diaria y semanal con recordatorios
- Insumos (stock interno) con alertas de mínimo
- Productos (venta) con stock y precio
- Finanzas (ingresos/egresos) + reporte mensual
- Clientes con historial de visitas
- Catálogo de servicios con templates por rubro
- Onboarding wizard
- Backup export/import JSON
- Notificaciones Android 8-13 (Samsung + Xiaomi)
- Configuración de colores y tema
- Splash screen BizPulse
- AAB release firmado generado (54.2MB)
- Permiso INTERNET agregado
- Repo GitHub limpio

### 🔲 Pendiente antes de publicar
- Publicar política de privacidad en GitHub Pages
- Crear cuenta Play Store ($25)
- Subir AAB a Play Console
- Completar Data Safety
- Subir capturas de pantalla
- Testeo completo en Samsung A51
- Verificar notificaciones en Samsung A51

### 🔲 Post-lanzamiento (v1.1)
- Try/catch completo en todos los servicios
- Optimizar queries Firestore (filtrado en DB no en memoria)
- Botón de prueba de notificación (temporal, remover antes de publicar)

### 🔲 Futuro (Pro/Enterprise)
- Sync cloud multi-dispositivo
- RevenueCat integración completa
- Bot WhatsApp
- Multiusuario con roles

---

## MENSAJES DE INICIO

### Primer mensaje a Jarvis 2 (Cowork):
```
Leé el CLAUDE.md en esta carpeta. Tu rol es JARVIS 2.
BizPulse es una app Flutter para profesionales de servicios en LATAM.
Confirmame que entendés el proyecto y tu rol.
Después te paso tu primera tarea.
```

### Primer mensaje a Jarvis 3 (Code):
```
Leé el CLAUDE.md. Tu rol es JARVIS 3.
Path del proyecto: C:\navajas_latinas_v2
Repo: https://github.com/ezequielpazz/bizpulse
Respondé siempre en español.
Confirmame que leíste todo y entendés tu rol.
```
