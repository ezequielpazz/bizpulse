# Plan de Mejoras — BizPulse

> Actualizado: 2026-07-01 · Responsable: Jarvis 3 (Code)
> Estado general: Free v1.0 lista para publicar · Infraestructura Pro implementada

---

## 🎯 Prioridad 1 — UI/UX (en ejecución AHORA)

Criterio de diseño unificado (ya aplicado en Dashboard, Agenda, Clientes, Shell):
- Material 3, cards radius 16–18 con borde sutil
- CERO colores hardcodeados → todo desde `Theme.of(context)` (light/dark OK)
- Empty states con círculo tintado + título + subtítulo accionable
- Acciones en mini-botones cuadrados tintados
- Jerarquía tipográfica clara (w800 títulos, hintColor secundarios)

| # | Pantalla | Problema | Estado |
|---|----------|----------|--------|
| 1 | `widgets/ui_kit.dart` | No existe — código de cards duplicado en 4 pantallas | 🔨 crear |
| 2 | `finance_screen.dart` | Summary con `Color(0xFF1E1E1E)` fijo (ilegible en modo claro), empty state con `Colors.white24/54/30`, form con `0xFF2A2A2A` | 🔨 |
| 3 | `report_screen.dart` | 11 colores fijos — cards, gráfico y comparación rotos en modo claro | 🔨 |
| 4 | `inventory_screen.dart` | Empty state hardcodeado, tiles planos, sin stepper moderno | 🔨 |
| 5 | `products_screen.dart` | Empty state pobre ("No hay productos."), banner rojo oscuro fijo, acentos redAccent fijos | 🔨 |
| 6 | `dashboard_screen.dart` | `_showPlansDialog` muestra AlertDialog viejo → debe navegar a `PlansScreen` real (RevenueCat) | 🔨 |
| 7 | `onboarding_screen.dart` | 2 lints: import innecesario + `withOpacity` deprecado | 🔨 |
| 8 | `account_screen.dart` / `settings_screen.dart` / `backup_screen.dart` | 12 colores fijos combinados | 🔨 |
| 9 | `service_catalog_screen.dart` | 5 colores fijos | 🔨 |
| 10 | `agenda_screen.dart` (vista semanal) | 8 colores fijos restantes | 🔨 |
| 11 | `privacy_policy_screen.dart` / `splash_screen.dart` | 3 colores fijos menores | 🔨 |

## 🎯 Prioridad 2 — Técnica (antes de publicar)

| # | Tarea | Detalle |
|---|-------|---------|
| 1 | IDs reales de AdMob | Reemplazar test IDs en `ad_service.dart`, `ad_banner.dart`, `AndroidManifest.xml` cuando la cuenta salga de revisión |
| 2 | API key RevenueCat | `subscription_service.dart` → `YOUR_REVENUECAT_API_KEY` + crear productos en Play Console (`bizpulse_pro_monthly`, `bizpulse_enterprise_monthly`) |
| 3 | Publicar política de privacidad | `store/privacy_policy.html` → GitHub Pages (URL obligatoria para Play Console) |
| 4 | Screenshots reales | Sacar del Samsung A51 → `docs/screenshots/` (el README ya tiene los placeholders) |
| 5 | Obfuscación release | `flutter build appbundle --obfuscate --split-debug-info=./debug-info/` |
| 6 | try/catch en servicios | Auditar `product_service`, `supply_service`, `finance_service` (SQLite) — hoy confían en el caller |
| 7 | Índice compuesto Firestore | `streamNeedingWhatsApp()` usa 3 where — va a pedir índice. Crearlo en `firestore.indexes.json` |

## 🎯 Prioridad 3 — Features Pro (post-lanzamiento, ya hay base)

| # | Feature | Base existente |
|---|---------|----------------|
| 1 | WhatsApp automático 24h antes | `streamNeedingWhatsApp()` + `markWhatsAppSent()` ya en AppointmentService |
| 2 | Backup automático diario | `backup_service.dart` + gate `Feature.autoBackup` |
| 3 | Reportes PDF exportables | Agregar paquete `pdf` + gate `Feature.advancedReports` |
| 4 | Trial 7 días Pro | Configurar en Play Console + RevenueCat |

## 🎯 Prioridad 4 — Enterprise (futuro)

Multi-empleado · Dashboard de equipo · Link público de reservas · Comisiones · Excel export

---

## 🚀 FASE ESCALA — Mejoras para cuando haya éxito (500+ usuarios)

> Disparador: superar ~500 usuarios activos o ~50 suscriptores Pro.
> Regla: nada de esto bloquea el lanzamiento, pero los ítems E1–E4 conviene
> hacerlos ANTES de llegar a esa cifra porque se instalan en 1 día y sin datos
> históricos después es tarde (no se puede medir retroactivamente).

### E — Observabilidad (hacer ANTES del éxito, no después)

| # | Tarea | Porqué |
|---|-------|--------|
| E1 | **Firebase Crashlytics** | Con 500 usuarios los crashes existen aunque nadie los reporte. Sin esto estamos ciegos: no sabemos qué se rompe ni en qué dispositivo. Play Store baja el ranking de apps con crash rate alto. |
| E2 | **Firebase Analytics** (eventos clave: turno_creado, cobro_rapido, whatsapp_enviado, paywall_visto, suscripcion_iniciada) | Sin funnel no se puede saber dónde se pierden los usuarios ni qué feature convierte a Pro. Es imposible medir retroactivamente. |
| E3 | **Firebase Remote Config** | Cambiar frecuencia de interstitials, textos del paywall o activar/desactivar features SIN publicar versión nueva (una release en Play tarda días en propagarse). |
| E4 | **In-app review** (`in_app_review` tras 5 turnos creados) | Las reseñas orgánicas llegan solas solo cuando son malas. Pedir la reseña en el momento de satisfacción define el rating de la ficha. |

### F — Costos Firebase (la factura crece con cada usuario)

| # | Tarea | Porqué |
|---|-------|--------|
| F1 | **Paginar/limitar FinanceService.stream()** — hoy baja TODAS las transacciones sin límite | Bomba de costos #1: un usuario con 1 año de uso relee ~1.000 docs por apertura de Ganancias/Reportes. Con 500 usuarios se revienta el free tier (50K reads/día) y se pasa a facturar. Fix: query por rango de mes + limit. |
| F2 | **Cachear _checkBirthdays()** — hoy hace getAll() de clientes en cada arranque | 1 read por cliente por apertura de app. 500 usuarios × 100 clientes × 3 aperturas/día = 150K reads/día solo en cumpleaños. Fix: correr 1 vez/día (SharedPreferences con fecha del último chequeo). |
| F3 | **Migrar a plan Blaze con alertas de presupuesto** | El free tier (Spark) se agota con ~300 usuarios activos. Configurar alerta de gasto en $10/$25/$50 para no tener sorpresas. |
| F4 | **Firebase App Check** | Sin App Check, cualquiera que extraiga la config del APK puede hacer requests contra nuestro Firestore y vaciarnos la cuota / inflarnos la factura. |
| F5 | **Firestore scheduled backups** (export diario a Cloud Storage) | Con usuarios reales, un bug que corrompa datos sin backup = perder el negocio. Las rules protegen de accesos, no de bugs propios. |

### G — Confianza del cobro (dinero real exige validación server-side)

| # | Tarea | Porqué |
|---|-------|--------|
| G1 | **Webhook RevenueCat → Cloud Function → Firestore** | Hoy el plan se escribe en Firestore desde el CLIENTE (manipulable con root). Con pocos usuarios es riesgo teórico; con cientos, alguien lo va a intentar. El webhook server-side es la fuente de verdad. |
| G2 | **Firestore rules que validen el campo `plan`** | Que solo la Cloud Function (Admin SDK) pueda escribir `users/{uid}.plan`, nunca el cliente. |
| G3 | **Grace period / recuperación de pagos fallidos** | Tarjetas LATAM rechazan mucho. Configurar grace period en Play Console reduce churn involuntario ~20%. |

### H — Soporte y retención

| # | Tarea | Porqué |
|---|-------|--------|
| H1 | **Eliminación de cuenta in-app** | Política de Google Play OBLIGATORIA para apps con registro: si la detectan sin esto, la bajan de la tienda. Hoy solo se ofrece por email. |
| H2 | **FCM push notifications** (re-engagement) | Las notificaciones actuales son locales (solo si la app corrió). Con FCM se puede recuperar usuarios inactivos ("hace 7 días no cargás turnos"). |
| H3 | **Centro de ayuda / FAQ in-app** | Con 500 usuarios, el email de soporte se satura de preguntas repetidas. Un FAQ baja el 70% de tickets. |
| H4 | **Programa de referidos** ("invitá a un colega, 1 mes de Pro gratis") | El rubro (peluqueras, barberos) se conoce entre sí — el boca a boca es el canal de adquisición más barato. |
| H5 | **CI/CD con GitHub Actions** (analyze + test + build en cada push) | Con usuarios reales, romper producción cuesta reseñas de 1 estrella. Staged rollout (5%→20%→100%) en Play Console. |

### Orden sugerido al llegar el éxito
1. **Semana 1:** E1+E2 (ceguera cero) · F2 (fix de 30 min) · H1 (riesgo de baja de la tienda)
2. **Semana 2:** F1 (paginación) · F3+F4 (Blaze + App Check) · E4 (reviews)
3. **Semana 3-4:** G1+G2 (webhook server-side) · F5 (backups) · E3 (Remote Config)
4. **Mes 2:** H2 (FCM) · H3 (FAQ) · H5 (CI/CD) · H4 (referidos)

---

## ✅ Completado (histórico)

- Free v1.0 completa (agenda, clientes, stock, finanzas, reportes, backup)
- Ads: banner + interstitial + rewarded (test IDs)
- Turnos recurrentes + cumpleaños + WhatsApp manual
- Notificaciones con timezone real (flutter_timezone) + compat Xiaomi/Huawei/OPPO/Samsung
- Suscripciones RevenueCat (infra completa, falta API key)
- FeatureGate + PlansScreen + ads off para Pro
- Notas técnicas por turno + historial de cliente (Pro)
- UI Material 3: Dashboard, Agenda, Clientes, Navegación
- README profesional + ficha Play Store + política de privacidad
- Keystore con triple backup
