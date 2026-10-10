# Documentación técnica — Local Material Notes (fork personal)

> Manual completo para cualquier desarrollador o inteligencia artificial que trabaje en este
> repositorio. No asume conocimiento previo: explica qué es el proyecto, cómo está construido,
> cómo se compila, cómo se publica y qué reglas hay que respetar al modificarlo.

---

## 1. Qué es este proyecto

**Local Material Notes** es una app Android de notas 100 % locales (sin nube, sin cuentas, sin
rastreo), escrita en **Flutter** con Material 3 y colores dinámicos. El proyecto original es de
[maelchiotti](https://github.com/maelchiotti/LocalMaterialNotes), licencia **MIT**.

Este repositorio es un **fork personal** mantenido por `GlhD0`. La base del fork es la versión
**2.2.2+38** del proyecto original (fecha 2026-07-14). Sobre esa base se aplicaron cambios
propios de usabilidad, correcciones de errores y una cadena de compilación y publicación propia.
El objetivo del fork es **uso personal**: se compila en GitHub Actions y se instala manualmente
el APK en el teléfono del dueño del repositorio.

Identidad de la app en este fork:

| Campo | Valor | Dónde está |
|---|---|---|
| `applicationId` | `com.glhd0.localmaterialnotes` | `android/app/build.gradle` (línea ~53) |
| `namespace` | `com.maelchiotti.localmaterialnotes` | `android/app/build.gradle` (línea ~38) |
| Versión base | `2.2.2+38` | `pubspec.yaml` (`version:`) |
| Flutter | 3.44.0 (stable) | `pubspec.yaml` (`environment`) y ambos workflows |
| Versión personal | sufijo `1.3` (actual) | `.github/workflows/build-release.yaml` (`PERSONAL_VERSION`) |

El `namespace` sigue siendo el del proyecto original a propósito: cambiarlo rompería
la compatibilidad de recursos generados sin ningún beneficio. El `applicationId` sí se cambió
para que esta app pueda convivir (en caso necesario) con la original y para firmar con un
keystore propio.

---

## 2. Historial del fork (qué se cambió y por qué)

### Ronda 1.0 — Menú lateral y accesos directos
- **Botones `+` discretos** en el menú lateral (side navigation) para crear nota sin etiqueta y
  nota con etiqueta. Requisitos de diseño fijados por el dueño: el `+` es "plano", del mismo
  gris que los textos, **sin círculo ni fondo**.
- **El menú lateral se abre automáticamente en cada arranque** de la app.
- Se corrigió un fallo de refresco: el menú usaba `ref.read` sobre los providers de notas y
  etiquetas (instantánea estática); se pasó a `ref.watch` para que el menú reaccione a cambios.

### Ronda 1.1 — Etiquetas al instante
- **Bug corregido:** una etiqueta recién creada no aparecía en el menú lateral hasta reiniciar.
- **Causa raíz:** el provider auto-dispose `Labels` se destruía a mitad de la operación `edit()`
  (auto-dispose tras un tiempo sin listeners). Se arregló la raíz; **no** se añadieron refrescos
  de seguridad redundantes (regla del proyecto: no parchear sobre parches).

### Ronda 1.2 — Tipos de nota y releases personales
- **"Texto sin formato" (plainText) dejó de ofrecerse** como opción al crear notas. El botón `+`
  y Ajustes → Tipos de nota solo ofrecen **texto enriquecido, Markdown y checklist**.
  Las notas antiguas de texto sin formato siguen funcionando; si se comparten, se comparten como
  texto enriquecido. **Importante:** el valor `plainText` sigue existiendo en el `enum NoteType`
  (ver §7, decisión 1).
- **Cada actualización crea un GitHub Release nuevo** con sufijo personal:
  tag y título `v2.2.2+38-personal_vX` (X = `PERSONAL_VERSION`). El release incluye el changelog
  de la versión base y los APKs por ABI como assets.

### Corrección de CI posterior a 1.2
- Un intento de fijar la paleta inicial del selector de color con `pickerType:` falló en CI:
  `flex_color_picker 3.8.0` **no tiene** ese parámetro. Se retiró (ver §7, decisión 3).

### Ronda 1.3 — Versión visible y paleta Primary (versión actual)
- **La versión personal se ve en la app:** Ajustes → Acerca de muestra
  `v2.2.2 (382) 1.3` (versión + número de compilación + sufijo personal). El sufijo se inyecta
  en tiempo de compilación con `--dart-define=PERSONAL_VERSION=…` (ver §6.3).
- **Diálogo de color de etiquetas:** las opciones *Primary* y *Wheel* siguen visibles y
  seleccionables, pero el diálogo **abre en Primary**. Se consigue dando a las etiquetas nuevas
  un color Material estándar (`Colors.blue`) como color inicial: el paquete elige la paleta
  inicial según el color actual (si pertenece a una paleta Material, abre en Primary; si no,
  abre en Wheel). No se oculta ninguna opción.

### Ronda 1.4 — APK distinguible y versión centralizada (versión actual)
- **El número interno del APK (versionCode) sube con cada actualización personal.** El workflow
  deriva `--build-number` con la fórmula `BASE_CODE + MAJOR*10 + MINOR` (base 38; `1.4` → 52),
  y los splits por ABI producen 521/522/523. Antes el APK quedaba idéntico al original en
  gestores de archivos e instaladores (siempre 2.2.2/382); ahora cada release personal es
  distinguible y actualizable sin conflicto.
- **La etiqueta de versión se construye en un solo lugar:** `SystemUtils.versionLabel`
  (`v{appVersion} ({buildNumber}) {personalVersion}`), usada por Ajustes → Acerca de.

---

## 3. Stack tecnológico

- **Flutter 3.44.0 / Dart** (stable). UI Material 3 con colores dinámicos (Material You).
- **Riverpod** (generators + riverpod_lint): inyección de dependencias y estado. Providers
  generados con `build_runner`.
- **Isar** (`isar_community` + `isar_community_generator`): base de datos local NoSQL.
  **Ojo:** Isar persiste los enums **por índice** (posición en el enum). Reordenar o eliminar
  valores de un enum corrupto los datos existentes.
- **Generación de código:** `dart run build_runner build --delete-conflicting-outputs` genera
  `*.g.dart` (Isar, Riverpod, JSON). Los `*.g.dart` **no se commitean** (están en `.gitignore`);
  se generan en CI y en local bajo demanda.
- **Localizaciones:** `flutter gen-l10n` a partir de `lib/l10n/*.arb` (config en `l10n.yaml`).
  Idioma principal: inglés; el dueño usa español (traducciones vía Crowdin en el proyecto
  original; en el fork, lo relevante está en español por defecto vía strings propios).
- **Dependencias destacadas:** `flex_color_picker ^3.8.0` (selector de color), `settings_tiles`
  (tiles de ajustes), `url_launcher`, `simple_icons`.

---

## 4. Estructura del repositorio (mapa orientativo)

```
.
├── .github/workflows/
│   ├── dart.yaml            # CI de verificación en cada push (analyze + format + generated)
│   └── build-release.yaml   # Compila APKs firmados y publica el Release (manual)
├── android/
│   └── app/build.gradle     # applicationId, namespace, versionCode/Name, splits por ABI
├── assets/                  # iconos, fuentes
├── lib/
│   ├── common/
│   │   ├── navigation/      # barras, navegación, side_navigation.dart y sus widgets (botón +)
│   │   ├── preferences/     # preference_key.dart (claves y valores por defecto)
│   │   └── ...              # utilidades, extensiones, constantes
│   ├── database/            # esquemas Isar (nota, etiqueta) y sus providers
│   ├── l10n/                # archivos .arb (idiomas)
│   ├── models/
│   │   └── note/types/      # note_type.dart (enum NoteType y listas available/share)
│   ├── pages/
│   │   ├── editor/          # editor de notas (richtext, markdown, checklist)
│   │   ├── labels/
│   │   │   └── dialogs/label_dialog.dart   # diálogo crear/editar etiqueta + color
│   │   ├── notes/           # lista de notas
│   │   └── settings/
│   │       └── pages/
│   │           ├── settings_about_page.dart       # "Acerca de" (muestra la versión)
│   │           └── settings_notes_types_page.dart # tipos de nota disponibles
│   └── main.dart
├── test/
├── docs/screenshots/        # capturas para el README (viven solo en GitHub)
├── pubspec.yaml             # versión base 2.2.2+38, dependencias
├── pubspec.lock             # versiones fijadas (flex_color_picker 3.8.0)
├── analysis_options.yaml    # lints: page_width 120, strict-inference, public_member_api_docs
├── CHANGELOG.md             # sección del fork al inicio (2.2.2+38 - 2026-10-09)
├── README.md                # presentación breve en español
└── DOCUMENTACION.md         # este archivo
```

---

## 5. Los puntos del código que este fork modificó

Ruta → qué hace → qué cambió el fork:

1. `lib/common/navigation/side_navigation.dart` y
   `lib/common/navigation/widgets/side_navigation_add_note_button.dart`
   → Menú lateral y botón `+`. El fork añadió botones `+` discretos (nota / nota con etiqueta),
   apertura automática del menú en cada arranque, y `ref.watch` en vez de `ref.read` para los
   providers. El `+` crea **`NoteType.richText`**.
2. `lib/models/note/types/note_type.dart`
   → `enum NoteType { plainText, markdown, checklist, richText, drawing }` (el orden **no se
   toca**, ver §7.1). Getters del fork:
   - `share => [markdown, richText]` (atajos de compartir sin plainText).
   - `available` filtra `'plainText'` de la preferencia guardada.
   - `defaultShare` traduce un `plainText` guardado → `richText`.
3. `lib/common/preferences/preference_key.dart`
   → Valores por defecto del fork: `availableNotesTypes = ['richText','markdown','checklist']`,
   `defaultShareNoteType = 'richText'`.
4. `lib/pages/settings/pages/settings_notes_types_page.dart`
   → La lista de tipos de nota excluye `plainText`
   (`NoteType.values.where((type) => type != NoteType.plainText)`).
5. `lib/pages/labels/dialogs/label_dialog.dart`
   → Diálogo de etiqueta. Color inicial: `widget.label?.color ?? Colors.blue` (Material
   estándar → el selector abre en la paleta Primary). `pickersEnabled`: `primary: true`,
   `wheel: true`, resto `false`.
6. `lib/pages/settings/pages/settings_about_page.dart`
   → "Acerca de". Muestra `SystemUtils().versionLabel` (p. ej. `v2.2.2 (522) 1.4`).
7. `lib/common/system_utils.dart`
   → Getters `appVersion`, `buildNumber`, `personalVersion`
   (`String.fromEnvironment('PERSONAL_VERSION')`, vacía sin inyectar) y `versionLabel`
   (etiqueta completa; sin sufijo muestra `v2.2.2 (382)`).
8. `.github/workflows/build-release.yaml` → ver §6.3.
9. `CHANGELOG.md`, `README.md`, `android/app/build.gradle` (applicationId) → texto/identidad.

---

## 6. Compilación y publicación

### 6.1 Requisitos locales
- Flutter 3.44.0 stable. Tras clonar: `flutter pub get`,
  `dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`.
- Firma: se necesitan `android/localmaterialnotes_keystore.jks` y `android/key.properties`
  (no están en el repo; en CI se generan desde secretos). Sin ellos, `flutter build apk`
  produce una build sin firmar de release (útil solo para probar).
- Estilo: `dart format -l 120` y `dart analyze --fatal-infos` deben pasar antes de commitear.

### 6.2 CI de verificación — `.github/workflows/dart.yaml`
Se ejecuta en cada push: instala dependencias, genera código, `dart analyze --fatal-infos` y
verificación de formato. **Es el verificador de tipos del proyecto**: si un cambio de Dart no
compila, este workflow falla y lo dice (archivo, línea, causa). Los cambios de Dart siempre
deben superar este workflow antes de dar por bueno un release.

### 6.3 Build y release — `.github/workflows/build-release.yaml`
Disparo **manual** (`workflow_dispatch`). Pasos:
1. Checkout, Flutter 3.44.0, decodifica secretos `ANDROID_KEYSTORE` (base64) y
   `ANDROID_KEY_PROPERTIES` a los archivos de firma.
2. `flutter pub get` + `build_runner` + `gen-l10n`.
3. `flutter build apk --release --split-per-abi --dart-define=PERSONAL_VERSION=${PERSONAL_VERSION}`
   → un APK por ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`), firmados, con el sufijo personal
   **incrustado en la app** (lo muestra Acerca de).
4. Publicación: `VERSION="${BASE}-personal_v${PERSONAL_VERSION}"` (BASE = versión de
   `pubspec.yaml`, hoy `2.2.2+38`). Crea el Release `v$VERSION` (si ya existe, no falla),
   sube los APKs (`--clobber`) y pega como notas el bloque del CHANGELOG de la versión base +
   enlace al changelog completo.

`permissions: contents: write` permite al workflow crear Releases con el token automático;
no hay secretos extra para publicar.

### 6.4 Versionado y números de compilación
- `pubspec.yaml` `version: 2.2.2+38` → `versionName 2.2.2`, `versionCode 38`.
- `android/app/build.gradle` aplica splits por ABI con
  `versionCodeOverride = versionCode * 10 + índiceABI`.
- **El workflow build-release calcula el versionCode** con
  `--build-number = BASE_CODE + MAJOR*10 + MINOR` (hoy base 38): `1.4` → 52 → APKs 521/522/523.
  Así cada release personal tiene número interno propio y distinto del original (382).
- **Cada release personal** se distingue por: título/tag (`-personal_vX`), número interno del
  APK, sufijo en Acerca de y changelog.
- **Para cada actualización personal:** subir `PERSONAL_VERSION` en
  `build-release.yaml` (`'1.4'` → `'1.5'`; `'2.0'` para cambios grandes). No hay que tocar
  `pubspec.yaml`: el número interno se deriva solo. Formato obligatorio `X.Y`.

### 6.5 Secretos del repositorio (Settings → Secrets and variables → Actions)
| Secreto | Contenido |
|---|---|
| `ANDROID_KEYSTORE` | Keystore `.jks` codificado en **base64** (una línea) |
| `ANDROID_KEY_PROPERTIES` | Contenido íntegro del archivo `key.properties` |

Nunca commitear keystore, `key.properties` ni sus valores (ya están en `.gitignore`). El token
clásico usado para `git push` necesita los scopes **`repo` y `workflow`**.

---

## 7. Decisiones de diseño vinculantes (no revertir sin motivo)

1. **`plainText` se filtra, no se elimina del enum.** Isar persiste enums por índice; eliminar
   o reordenar `NoteType` corrompería las notas existentes. La exclusión se hace en
   `available`, `share`, `defaultShare`, la página de ajustes y el botón `+`.
2. **Sin parches sobre parches.** Cada arreglo va a la causa raíz; no se acumulan refrescos,
   reintentos o código defensivo redundante. Ejemplo: el bug de etiquetas se arregló en el
   ciclo de vida del provider, no añadiendo un `ref.refresh` extra.
3. **`flex_color_picker` está fijado en 3.8.0** (`pubspec.lock`). Esta versión **no tiene**
   parámetro `pickerType` (usarlo rompe `dart analyze` en CI). La paleta inicial no es
   configurable por API: se controla con el color inicial (`Colors.blue` = abre en Primary).
   No subir a 4.x: exige Flutter ≥ 3.47 y el proyecto está fijado en 3.44.
4. **El `+` del menú lateral es discreto a propósito** (gris, sin círculo/fondo) y crea notas
   de texto enriquecido. El menú se abre en cada arranque. Son decisiones de producto del dueño.
5. **Las opciones del selector de color no se ocultan**: Primary y Wheel visibles; solo cambia
   con cuál abre.
6. **Releases = uno por actualización personal** vía sufijo `PERSONAL_VERSION`; el título, el
   tag y la versión visible en la app deben coincidir.
7. **Los `*.g.dart` no se commitean**; los genera `build_runner` en CI. `android/local.properties`
   tampoco se commitea (es local de cada máquina).

---

## 8. Cómo hacer un cambio nuevo (flujo estándar)

1. **Localizar** el archivo (mapa en §4–§5). Buscar por widget/texto, no por suposición.
2. **Modificar** siguiendo el estilo: ancho de línea 120, doc-comments en miembros públicos,
   inferencia estricta, código limpio y mínimo.
3. **Formatear y verificar**: `dart format -l 120 <archivos>` y, idealmente, `dart analyze`.
   Si no hay entorno local, el CI (`dart.yaml`) verifica tras el push.
4. **Documentar**: añadir la línea correspondiente en la sección del fork de `CHANGELOG.md`
   (Added / Fixed / Changed / Removed) y en `README.md` si es visible para el usuario.
5. **Subir `PERSONAL_VERSION`** en `build-release.yaml` (p. ej. `'1.3'` → `'1.4'`).
6. **Commit + push** (el token necesita `repo` + `workflow` por tocar `.github/workflows/`).
7. Esperar a que **`dart.yaml` pase en verde**.
8. **Actions → build-release → Run workflow**. Al terminar: instalar el APK
   (`app-arm64-v8a-release.apk` para la mayoría de teléfonos) desde el Release
   `v2.2.2+38-personal_vX` y comprobar en Acerca de que aparece el sufijo nuevo.

---

## 9. Reglas para agentes de IA que trabajen aquí

- Responder y documentar en **español**.
- Verificar los hechos contra el repositorio (grep/lectura), nunca de memoria: las rutas y
  versiones de este documento pueden haberse actualizado.
- Prohibido: eliminar valores de enums persistidos, añadir `pickerType:` a `ColorPicker` en
  3.8.0, ocultar opciones del selector de color, subir `flex_color_picker` a 4.x, commitear
  `*.g.dart`/`local.properties`/secretos, y añadir código defensivo redundante.
- No "rediseñar" UI por iniciativa propia; el dueño aprueba los cambios visuales (mockups).
- Los warnings de Gradle/Kotlin/NDK del build son estado heredado del upstream: no se arreglan
  salvo que bloqueen.
- El repositorio es **público**: nada de secretos, tokens ni datos personales en código,
  commits, issues o documentación.

---

## 10. Solución de problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `dart analyze` falla con `undefined_named_parameter 'pickerType'` | Se usó un parámetro que `flex_color_picker` 3.8.0 no tiene. Eliminarlo (§7.3). |
| `git push` rechaza con error de permisos sobre `.github/workflows` | El token no tiene scope `workflow`. Recrear el PAT con `repo` + `workflow`. |
| `git push` falla con HTTP 408 / error de red | Red inestable (típico en móvil). Reintentar; el commit local no se pierde. Si dice "Everything up-to-to date", el push anterior sí llegó. |
| El workflow build-release falla decodificando el keystore | `ANDROID_KEYSTORE` debe ser base64 de una sola línea (`base64 -w 0 archivo.jks`). |
| La etiqueta nueva no aparece en el menú | Regresión del provider de etiquetas: revisar `side_navigation.dart` (debe usar `watch`) y el ciclo de vida del provider `Labels` (§2, ronda 1.1). |
| Acerca de no muestra el sufijo personal | El build no recibió `--dart-define=PERSONAL_VERSION=…` (p. ej. build local sin el flag). En CI lo añade el workflow. |

---

*Documento generado el 2026-10-09 para la versión personal 1.4 (base 2.2.2+38).*
