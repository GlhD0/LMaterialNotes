# Local Material Notes (fork personal)

Fork personal de [Local Material Notes](https://github.com/maelchiotti/LocalMaterialNotes)
de maelchiotti (licencia MIT). Notas locales, simples y con material design:
sin nube, sin cuentas y sin rastreo.

## Diferencias con el original

- Botones `+` discretos en el menú lateral.
- El menú lateral se abre automáticamente en cada arranque.
- Mejoras de rendimiento en notas largas.
- Identificador de aplicación propio: `com.glhd0.localmaterialnotes`
  (se instala como app independiente de la oficial).
- Compilación por GitHub Actions con keystore propio; los APK se publican
  en [Releases](../../releases).

## Compilación

1. Configura los secretos del repositorio:
   - `ANDROID_KEYSTORE`: keystore de firma codificado en base64.
   - `ANDROID_KEY_PROPERTIES`: contenido del archivo `key.properties`.
2. Ejecuta **Actions → build-release → Run workflow**.
3. Los APK se adjuntan automáticamente a la release `v{versión}`
   (en la mayoría de teléfonos: `app-arm64-v8a-release.apk`).
