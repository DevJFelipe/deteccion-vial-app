/// Widget para renderizar bounding boxes sobre el preview de cámara
/// 
/// Usa CustomPainter para dibujar eficientemente los bounding boxes
/// de las detecciones sobre el preview de la cámara en tiempo real.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/detection_result.dart';

/// Colores para cada tipo de detección
/// 
/// Sistema de colores consistente para identificar visualmente
/// los diferentes tipos de anomalías viales detectadas.
class DetectionColors {
  /// Color para detecciones de tipo 'hueco' (rojo)
  static const Color hueco = Color(0xFFFF0000);

  /// Color para detecciones de tipo 'grieta' (naranja)
  static const Color grieta = Color(0xFFFF9800);

  /// Color por defecto para otras clases (azul)
  static const Color defaultColor = Color(0xFF2196F3);

  /// Obtiene el color según el tipo de detección
  /// 
  /// [type] - Tipo de detección ('hueco' o 'grieta')
  /// 
  /// Retorna el color correspondiente al tipo de detección.
  static Color getColorForType(String type) {
    switch (type) {
      case 'hueco':
        return hueco;
      case 'grieta':
        return grieta;
      default:
        return defaultColor;
    }
  }
}

/// CustomPainter para dibujar bounding boxes sobre el preview
/// 
/// Renderiza eficientemente los bounding boxes de las detecciones
/// usando Canvas, optimizado para actualizaciones en tiempo real.
class DetectionOverlayPainter extends CustomPainter {
  /// Lista de detecciones a dibujar
  final List<DetectionResult> detections;

  /// Ancho del preview en píxeles
  final int previewWidth;

  /// Alto del preview en píxeles
  final int previewHeight;

  /// Constructor del DetectionOverlayPainter
  /// 
  /// [detections] - Lista de detecciones a dibujar
  /// [previewWidth] - Ancho del preview en píxeles
  /// [previewHeight] - Alto del preview en píxeles
  DetectionOverlayPainter({
    required this.detections,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar cada detección
    for (final detection in detections) {
      _drawBoundingBox(canvas, size, detection);
    }
  }

  /// Dibuja un bounding box individual
  /// 
  /// [canvas] - Canvas para dibujar
  /// [size] - Tamaño del canvas
  /// [detection] - Detección a dibujar
  void _drawBoundingBox(Canvas canvas, Size size, DetectionResult detection) {
    // Obtener coordenadas en píxeles del bounding box
    final pixels = detection.boundingBox.toPixels(previewWidth, previewHeight);

    final left = pixels['left']!.toDouble();
    final top = pixels['top']!.toDouble();
    final right = pixels['right']!.toDouble();
    final bottom = pixels['bottom']!.toDouble();

    // Calcular escala para ajustar al tamaño del canvas
    final scaleX = size.width / previewWidth;
    final scaleY = size.height / previewHeight;

    // Aplicar escala a las coordenadas
    final scaledLeft = left * scaleX;
    final scaledTop = top * scaleY;
    final scaledRight = right * scaleX;
    final scaledBottom = bottom * scaleY;

    // Obtener color según el tipo de detección
    final color = DetectionColors.getColorForType(detection.type);

    // Dibujar rectángulo con borde
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTRB(
      scaledLeft,
      scaledTop,
      scaledRight,
      scaledBottom,
    );

    canvas.drawRect(rect, paint);

    // Dibujar etiqueta con texto
    _drawLabel(canvas, rect, detection, color);
  }

  /// Dibuja la etiqueta con el tipo y confianza de la detección
  /// 
  /// [canvas] - Canvas para dibujar
  /// [rect] - Rectángulo del bounding box
  /// [detection] - Detección a etiquetar
  /// [color] - Color de la detección
  void _drawLabel(
    Canvas canvas,
    Rect rect,
    DetectionResult detection,
    Color color,
  ) {
    // Formatear texto: "Hueco 95%" o "Grieta 87%"
    final confidencePercent = (detection.confidence * 100).round();
    final labelText = '${detection.type[0].toUpperCase()}${detection.type.substring(1)} $confidencePercent%';

    // Crear TextPainter para medir y dibujar el texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calcular posición de la etiqueta (arriba del bounding box)
    final labelX = rect.left;
    final labelY = rect.top - textPainter.height - 4;

    // Dibujar fondo semi-transparente para la etiqueta
    final labelRect = Rect.fromLTWH(
      labelX - 4,
      labelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.7);

    canvas.drawRect(labelRect, backgroundPaint);

    // Dibujar el texto
    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter oldDelegate) {
    // Repintar solo si las detecciones o dimensiones cambian
    return oldDelegate.detections != detections ||
        oldDelegate.previewWidth != previewWidth ||
        oldDelegate.previewHeight != previewHeight;
  }
}

/// Widget que muestra el overlay de detecciones sobre el preview
/// 
/// Usa CustomPaint para renderizar eficientemente los bounding boxes
/// sin bloquear el hilo principal.
class DetectionOverlayWidget extends StatelessWidget {
  /// Lista de detecciones a mostrar
  final List<DetectionResult> detections;

  /// Ancho del preview en píxeles
  final int previewWidth;

  /// Alto del preview en píxeles
  final int previewHeight;

  /// Constructor del DetectionOverlayWidget
  /// 
  /// [detections] - Lista de detecciones a mostrar
  /// [previewWidth] - Ancho del preview en píxeles
  /// [previewHeight] - Alto del preview en píxeles
  const DetectionOverlayWidget({
    super.key,
    required this.detections,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DetectionOverlayPainter(
        detections: detections,
        previewWidth: previewWidth,
        previewHeight: previewHeight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

