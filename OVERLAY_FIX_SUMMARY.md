# Resumen de Cambios - Arreglo del Overlay

## Problema Original
El overlay solo aparecía cuando el usuario estaba dentro de la app, pero debería aparecer en las aplicaciones de distracción incluso si el usuario no está en la app principal.

## Solución Implementada

### 1. **Nuevo: OverlayService.kt**
- Servicio en foreground que gestiona mostrar/ocultar el overlay
- Funciona incluso cuando la app principal no está en primer plano
- Incluye verificación de permisos de `SYSTEM_ALERT_WINDOW`
- Se dispara desde `MonitoringBroadcastReceiver` cuando se alcanza el límite

### 2. **Actualizado: MonitoringBroadcastReceiver.kt**
- Ahora dispara `OverlayService` cuando se detectan 5 minutos de distracción
- En lugar de solo marcar una bandera en SharedPreferences
- El overlay aparece incluso si el usuario está en otra app

### 3. **Actualizado: DistractionOverlay.kt**
- Mejorados los flags de WindowManager:
  - Removido `FLAG_NOT_TOUCHABLE` (ahora es interactivo)
  - Agregado `FLAG_KEEP_SCREEN_ON` (mantiene pantalla encendida)
  - Agregado `FLAG_FULLSCREEN` (ocupa toda la pantalla)
- Ahora funciona correctamente en background

### 4. **Actualizado: AndroidManifest.xml**
- Registrado el `OverlayService` con `foregroundServiceType="specialUse"`
- Permisos necesarios ya estaban presentes:
  - `SYSTEM_ALERT_WINDOW` ✓
  - `WAKE_LOCK` ✓
  - `RECEIVE_BOOT_COMPLETED` ✓

### 5. **Actualizado: MainActivity.kt**
- Inicia `MonitoringService` en `onCreate()` para configurar AlarmManager
- Simplificado `onResume()` para no resetear checkpoints
- Los checkpoints ahora se mantienen durante toda la sesión de monitoreo en background

## Flujo de Funcionamiento

```
1. App se inicia → MainActivity.onCreate()
   ↓
2. Inicia MonitoringService → Configura AlarmManager
   ↓
3. AlarmManager dispara cada 1 minuto → MonitoringBroadcastReceiver
   ↓
4. MonitoringBroadcastReceiver chequea uso de apps distractoras
   ↓
5. Si ≥ 5 minutos → Dispara OverlayService
   ↓
6. OverlayService.show() → Overlay aparece flotante sobre cualquier app
   ↓
7. Usuario hace clic "Volver a Liv" → Overlay se oculta
```

## Requisitos Previos

### Permisos Necesarios en Android
El usuario debe otorgar permisos de overlay:
- **Android 6.0+**: Settings → Apps → Special Access → Display Over Other Apps → tu app → Permitir
- **Android < 6.0**: Automático

### Verificación del Permiso
Si ves un log error como:
```
❌ Sin permisos de SYSTEM_ALERT_WINDOW
```

Debes ir a Configuración y otorgar el permiso manualmente.

## Cómo Probar

1. **Instalar la app actualizada**
   ```bash
   flutter clean
   flutter run
   ```

2. **Verificar permisos de overlay en Configuración**
   - Ir a Configuración → Apps → [Tu app] → Permisos → Display Over Other Apps → Permitir

3. **Configurar apps distractoras**
   - Abrir la app
   - Ir a Settings
   - Seleccionar YouTube y DeskClock como apps distractoras
   - Guardar

4. **Iniciar monitoreo**
   - Tocar el botón de inicio de monitoreo
   - Ver que dice "Monitoreo activo"

5. **Probar el overlay en background**
   - Salir de la app (presionar home)
   - Abrir YouTube o cualquier app distractora
   - Usar esa app durante 5 minutos
   - El overlay debe aparecer automáticamente incluso sin volver a la app principal

## Logs para Debugging

Busca estos logs en `adb logcat` para verificar que funciona:

```
✅ MonitoringService creado
✅ AlarmManager configurado
📡 Monitoreo en background ejecutado...
💾 Sesión: 0s + 60s = 60s (1m)
🚨 ¡5 MINUTOS DE DISTRACCIÓN DETECTADOS!
✅ OverlayService disparado
✅ OverlayService.onStartCommand()
📺 Intentando mostrar overlay...
✅ Overlay mostrado exitosamente
```

## Cambios en Archivos

| Archivo | Cambio |
|---------|--------|
| `OverlayService.kt` | 📄 Nuevo |
| `MonitoringBroadcastReceiver.kt` | 🔄 Actualizado |
| `DistractionOverlay.kt` | 🔄 Actualizado |
| `MainActivity.kt` | 🔄 Actualizado |
| `AndroidManifest.xml` | 🔄 Actualizado |

## Notas Importantes

⚠️ **El overlay aparecerá incluso si el usuario está usando otra app**
- Esto es intencional y es la solución al problema reportado

⚠️ **El servicio continúa en background**
- Se mantiene en background para permitir monitoreo incluso con la app cerrada

⚠️ **Permisos de overlay son requeridos**
- Sin estos permisos, el overlay no se mostrará
