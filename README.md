# 🌱 OFFLINE - Digital Wellbeing App

Una aplicación Flutter innovadora que usa una **mascota virtual evolutiva** como incentivo para reducir el tiempo en pantalla y promover el bienestar digital.

## 🎯 Concepto

**OFFLINE** es una mascota Tamagotchi moderna que:
- **Crece y prospera** cuando pasas tiempo sin usar el teléfono
- **Pierde energía** cuando usas apps distractoras (redes sociales, etc.)
- **Gana monedas virtuales** que pueden canjearse por beneficios en comercios locales
- **Evoluciona de nivel** a medida que demuestras compromiso con tu bienestar

## 🏗️ Arquitectura

```
lib/
├── main.dart                 # Punto de entrada
├── models/
│   ├── pet.dart             # Modelo de mascota
│   └── app_usage.dart       # Modelo de uso de apps
├── services/
│   ├── screen_time_monitor.dart    # Monitorea tiempo de pantalla
│   └── pet_storage_service.dart    # Persistencia de datos
├── providers/
│   └── pet_provider.dart    # Business logic con Provider
├── screens/
│   └── home_screen.dart     # Pantalla principal
└── widgets/
    ├── pet_visualizer.dart  # Visualización de mascota
    └── stats_widget.dart    # Widget de estadísticas
```

## 🔧 Características Técnicas

### Monitoreo de Tiempo de Pantalla
- Usa la API `UsageStats` de Android para acceder a estadísticas de uso de aplicaciones
- **Bajo consumo de batería**: Solo se revisa cada 5 minutos
- Compatible con Android 6.0+

### Optimización de Batería
- ✅ Monitoreo en background cada 5 minutos (no continuo)
- ✅ Almacenamiento local con Hive (sin conexión)
- ✅ Sin conexión continua a internet
- ✅ UI con animaciones eficientes

### Clasificación de Apps
Apps detectadas como "distractoras":
- Instagram, Facebook, Twitter, TikTok
- YouTube, Snapchat, Discord, Reddit
- WhatsApp, Telegram

## 🚀 Inicio Rápido

### Requisitos
- Flutter 3.0+
- Android SDK 21+
- Kotlin

### Instalación

```bash
# Clonar repositorio
git clone https://github.com/tu-repo/offline.git
cd offline

# Obtener dependencias
flutter pub get

# Generar archivos necesarios (Hive)
flutter pub run build_runner build

# Ejecutar en emulador/dispositivo
flutter run
```

## 📋 Permisos Necesarios

La app requiere los siguientes permisos en Android:

```xml
<!-- Monitoreo de uso de apps -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />

<!-- Red (futuro) -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Background (WorkManager) -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

**Nota**: El permiso `PACKAGE_USAGE_STATS` debe otorgarse manualmente en:
Settings → Apps → Special app access → Usage access → OFFLINE

## 📊 Modelo de Datos

### Pet (Mascota)
```dart
- id: String
- name: String
- energy: 0-100
- level: 1-10
- coins: int
- totalOfflineTime: Duration
- lastUpdated: DateTime
- isAlive: bool
```

## 💡 Mecánicas de Juego

### Ganar Energía
- 1 minuto OFFLINE = +1 energía
- Máximo: 100

### Perder Energía
- 1 minuto en apps distractoras = -2 energía
- Mínimo: 0 (mascota muere)

### Ganar Monedas
- 10 minutos OFFLINE = +1 moneda
- Las monedas se pueden canjear por:
  - Subida de nivel (100 monedas × nivel actual)
  - Futuros beneficios en comercios

### Subir de Nivel
- Costo: 100 × nivel_actual monedas
- Máximo: nivel 10
- Beneficio: Acceso a nuevas visualizaciones y features

### Revivir Mascota (si muere)
- Costo: 50% de monedas acumuladas
- Energía restaurada: 30

## 🎨 UI/UX

### Pantalla Principal
- Visualizador de mascota con emoji animado
- Estado emocional según energía:
  - 💀 Muerta (0 energía)
  - 😢 Triste (<20 energía)
  - 😐 Neutral (20-50 energía)
  - 😊 Feliz (50-80 energía)
  - 😄 Muy feliz (>80 energía)

### Barra de Energía
- Visual clara del estado
- Colores: Rojo (crítico) → Naranja (bajo) → Verde (bien)

### Indicador de Estado
- 🟢 OFFLINE ✨
- 🔴 Usando pantalla

### Estadísticas
- Tiempo OFFLINE hoy
- Tiempo en pantalla hoy
- Apps distractoras usadas
- Tiempo total OFFLINE acumulado

## 🔐 Privacidad y Seguridad

- ✅ Almacenamiento local solo
- ✅ Sin envío de datos a servidores (MVP)
- ✅ Sin tracking adicional
- ✅ Cumple GDPR (datos locales del usuario)

## 📈 Futuro (V2)

- [ ] Sincronización con backend
- [ ] Sistema de logros y badges
- [ ] Integración con comercios para canje real
- [ ] Social features (desafíos entre amigos)
- [ ] Estadísticas detalladas y análisis
- [ ] Customización de mascota
- [ ] Sonidos y notificaciones push inteligentes
- [ ] Darkmode mejorado

## 🛠️ Stack Técnico

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Local Storage**: Hive
- **Usage Stats**: usage_stats package
- **Logging**: logger

## 📱 Dispositivos Soportados

- Android 6.0+ (API 21+)
- Cualquier procesador ARM (ARMv7, ARMv8, x86)
- Dispositivos media-baja con +1GB RAM

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver `LICENSE` para más detalles.

## 👨‍💻 Autor

Desarrollado con ❤️ para la comunidad de bienestar digital.

---

**¿Preguntas?** Abre una issue o contáctame directamente.

¡Que disfrutes usando OFFLINE! 🌱✨
