# 🛑 Crítica Técnica y Reporte de Auditoría: BizPulse

**Fecha de evaluación:** 04 de Junio de 2026
**Proyecto:** BizPulse
**Autor de la revisión:** Antigravity (IA)

---

## ❌ ¿Qué está mal? (Problemas Críticos)

He revisado a fondo el código fuente y he encontrado inconsistencias graves que amenazan tanto el rendimiento de la aplicación como la confianza del usuario final:

1. **La Gran Mentira de la Privacidad (Contradicción Arquitectónica)**
   El `README.md` vende la aplicación como una herramienta *Offline-First* donde los datos financieros y de insumos son privados: *"Toda la información financiera [...] y stock interno vive estrictamente en el dispositivo mediante sqflite. No se exponen en la nube"*. 
   **Sin embargo, el código dice otra cosa.** Al revisar `finance_service.dart` y `supply_service.dart`, ambos guardan los datos directamente en **Firebase Firestore** (`FirebaseFirestore.instance.collection('users')...`). Irónicamente, el catálogo de servicios, que supuestamente iba en la nube, es el único que usa SQLite. Estás subiendo datos confidenciales a la nube bajo una falsa promesa de privacidad.

2. **Ruina Financiera por Malas Prácticas en NoSQL**
   En `client_service.dart`, la función de búsqueda de clientes es una bomba de tiempo:
   ```dart
   Future<List<ClientModel>> getByName(String query) async {
     final all = await getAll(); // Descarga TODOS los clientes
     // ... filtrado local ...
   }
   ```
   Estás descargando **toda** la base de datos de clientes del usuario a la memoria RAM cada vez que realiza una búsqueda. Si un usuario tiene 2,000 clientes y teclea el nombre "Juan", por cada letra que escriba Firestore te cobrará 2,000 lecturas. La app consumirá memoria excesiva y los costos de Firebase se dispararán.

3. **Acoplamiento de Base de Datos Local**
   En `service_catalog_service.dart`, el script de creación de la tabla SQLite (`CREATE TABLE...`) está fuertemente incrustado dentro de la lógica del servicio. Esto hace que escalar la base de datos local y manejar migraciones futuras sea una pesadilla de mantenimiento.

4. **Amontonamiento de Servicios**
   Aunque tus vistas están bien separadas por funcionalidad (`views/agenda`, `views/dashboard`), has tirado todos los servicios y modelos en las carpetas raíz `lib/services/` y `lib/models/`. Esto rompe el patrón "Feature-First" y hará que el proyecto sea inmanejable a medida que crezca.

---

## 🛠️ ¿Qué MODIFICARÍA inmediatamente?

1. **Sincronizar el Código con la Promesa Comercial:**
   Debes reescribir `finance_service.dart` y `supply_service.dart` para que utilicen `sqflite` verdaderamente de forma local. Si decides que es mejor tener todo en la nube para respaldos, entonces **debes reescribir el README y avisar a los usuarios** de que sus finanzas no son 100% privadas.
2. **Refactorizar el Buscador de Clientes (`ClientService`):**
   - **Opción A:** Agregar un campo `searchKeywords` (Array) en Firestore y usar la consulta nativa `.where('searchKeywords', arrayContains: query)`.
   - **Opción B:** Utilizar *Provider* para descargar la lista de clientes una sola vez al abrir la app (caché local) y hacer todas las búsquedas en memoria contra esa lista precargada.
3. **Extraer el Helper de SQLite:**
   Crear un archivo `lib/helpers/db_helper.dart` que centralice la inicialización, la versión y la creación de todas las tablas SQLite. Los servicios solo deberían llamar a `dbHelper.database` para ejecutar *queries*.
4. **Reestructurar Carpetas (Verdadero Feature-First):**
   Mover los modelos y servicios a sus respectivas carpetas de funcionalidades (ej. `lib/features/clients/views/`, `lib/features/clients/services/`, `lib/features/clients/models/`).

---

## ✅ ¿Qué NO modificaría? (Lo que se hizo bien)

No todo está mal. Tienes bases muy sólidas que no deberías tocar:

1. **La Inicialización de la App (`main.dart`):**
   El uso de `unawaited()` para inicializar servicios pesados (Anuncios, Cumpleaños, Notificaciones) en el *background* sin bloquear el *Splash Screen* es brillante. Mantiene la app rápida y responsiva desde el segundo 0.
2. **Aislamiento de Seguridad en Firestore:**
   La estructura de las colecciones `users/{uid}/...` es el estándar de oro para aplicaciones SaaS en NoSQL. Está bien diseñado.
3. **Manejo del Estado Global (Provider):**
   La inyección de `AppSettingsProvider` y el manejo dinámico de temas, idioma y escalas de texto a nivel global es robusto.
4. **Calidad del Código Dart:**
   El código es limpio, tipado de forma estricta y hace un uso correcto de las características modernas de asincronía y *Null-Safety* de Dart.
