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
