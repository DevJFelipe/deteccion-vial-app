# Detección y Mapeo de Anomalías Viales mediante Visión Artificial

Sistema de detección en tiempo real de huecos y grietas en infraestructura vial utilizando Deep Learning con YOLOv8n.

## 📋 Descripción

Proyecto de investigación desarrollado en la Universidad Surcolombiana para la detección automática y georreferenciación de anomalías viales mediante visión artificial en dispositivos móviles.

## 🚀 Características

- Detección en tiempo real con YOLOv8n cuantizado (int8)
- Georreferenciación GPS con precisión ≤10 metros
- Almacenamiento local en SQLite
- Visualización en mapa interactivo con Google Maps
- Rendimiento: ≥15 FPS, latencia ≤200ms

## 🛠️ Tecnologías

- **Framework**: Flutter 3.32.2
- **Modelo**: YOLOv8n (TensorFlow Lite)
- **Base de datos**: SQLite
- **Mapas**: Google Maps API
- **Arquitectura**: Clean Architecture + BLoC

## 📦 Instalación

\`\`\`bash
# Clonar repositorio
git clone https://github.com/TU_USUARIO/deteccion-vial-app.git

# Instalar dependencias
flutter pub get

# Ejecutar app
flutter run
\`\`\`

## 📊 Métricas Objetivo

- mAP@0.5: ≥81.6%
- FPS en dispositivo: ≥15
- Latencia de inferencia: ≤200ms

## 👥 Autores

- Juan Felipe Andrade Vargas
- Linda Valentina López Rubiano

**Director**: Ing. Ferley Medina Rojas  
**Universidad**: Surcolombiana, Neiva, Colombia
