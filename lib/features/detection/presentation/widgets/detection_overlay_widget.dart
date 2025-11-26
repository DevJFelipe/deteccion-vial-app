/// Widget para dibujar bounding boxes de detecciones sobre el preview
/// 
/// Este widget dibuja rectángulos y etiquetas para cada detección
/// encontrada por el modelo de IA, escalando correctamente las
/// coordenadas normalizadas al tamaño del preview.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/detection_result.dart';
import '../../data/models/detection_constants.dart' show classColors;

/// Widget que dibuja el overlay de detecciones sobre la cámara
/// 
/// Recibe una lista de [DetectionResult] y dibuja un bounding box
/// con etiqueta para cada detección, escalando las coordenadas
/// normalizadas (0-1) al tamaño actual del widget.
/// 
/// IMPORTANTE: Las coordenadas del modelo están basadas en la imagen
/// de la cámara en su orientación original (landscape). El preview
/// de Flutter rota la imagen automáticamente a portrait, por lo que
/// las coordenadas deben ser transformadas para coincidir.
/// 
/// Ejemplo de uso:
/// ```dart
/// Stack(
///   children: [
///     CameraPreview(controller),
///     DetectionOverlayWidget(
///       detections: detections,
///       previewSize: Size(640, 480),
///     ),
///   ],
/// )
/// ```
class DetectionOverlayWidget extends StatelessWidget {
  /// Lista de detecciones a dibujar
  final List<DetectionResult> detections;
  
  /// Tamaño del preview de cámara (para escalar correctamente)
  /// Si es null, usa el tamaño del widget
  final Size? previewSize;
  
  /// Rotación de la cámara en grados (0, 90, 180, 270)
  /// Por defecto 0° (sin rotación adicional)
  final int cameraRotation;

  /// Constructor del DetectionOverlayWidget
  /// 
  /// [detections] - Lista de detecciones a dibujar
  /// [previewSize] - Tamaño del preview para escalar coordenadas
  /// [cameraRotation] - Rotación de la cámara (default 0° sin rotación)
  const DetectionOverlayWidget({
    super.key,
    required this.detections,
    this.previewSize,
    this.cameraRotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = previewSize ?? Size(constraints.maxWidth, constraints.maxHeight);
        
        return CustomPaint(
          painter: _DetectionPainter(
            detections: detections,
            previewSize: size,
            cameraRotation: cameraRotation,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

/// CustomPainter que dibuja los bounding boxes y etiquetas
class _DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size previewSize;
  final int cameraRotation;

  _DetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.cameraRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      _drawDetection(canvas, size, detection);
    }
  }

  /// Dibuja una detección individual
  void _drawDetection(Canvas canvas, Size size, DetectionResult detection) {
    // Obtener color según el tipo de detección
    final colorValue = classColors[detection.type] ?? 0xFFFF5722;
    final color = Color(colorValue);

    // Convertir coordenadas normalizadas a píxeles del canvas
    // Las coordenadas del modelo son (x_center, y_center, width, height)
    // IMPORTANTE: Transformar coordenadas según la rotación de la cámara
    final bbox = detection.boundingBox;
    
    // Transformar coordenadas según la rotación de la cámara
    // La imagen de la cámara está rotada respecto al display
    double x, y, bboxWidth, bboxHeight;
    
    switch (cameraRotation) {
      case 90:
        // Rotación 90° horario (típico en Android cámara trasera)
        // El eje X del modelo -> eje Y del display
        // El eje Y del modelo -> (1 - X) del display
        x = 1.0 - bbox.y;
        y = bbox.x;
        bboxWidth = bbox.height;
        bboxHeight = bbox.width;
        break;
      case 180:
        // Rotación 180°
        x = 1.0 - bbox.x;
        y = 1.0 - bbox.y;
        bboxWidth = bbox.width;
        bboxHeight = bbox.height;
        break;
      case 270:
        // Rotación 270° (o -90°)
        x = bbox.y;
        y = 1.0 - bbox.x;
        bboxWidth = bbox.height;
        bboxHeight = bbox.width;
        break;
      default:
        // Sin rotación (0°)
        x = bbox.x;
        y = bbox.y;
        bboxWidth = bbox.width;
        bboxHeight = bbox.height;
    }
    
    // Calcular el factor de escala entre el preview y el canvas
    final scaleX = size.width;
    final scaleY = size.height;

    // Convertir de centro a esquina superior izquierda
    final left = (x - bboxWidth / 2) * scaleX;
    final top = (y - bboxHeight / 2) * scaleY;
    final width = bboxWidth * scaleX;
    final height = bboxHeight * scaleY;

    // Crear rectángulo
    final rect = Rect.fromLTWH(
      left.clamp(0.0, size.width),
      top.clamp(0.0, size.height),
      width.clamp(0.0, size.width - left),
      height.clamp(0.0, size.height - top),
    );

    // Dibujar bounding box
    final boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(rect, boxPaint);

    // Dibujar fondo de la etiqueta
    final labelText = '${detection.type} ${(detection.confidence * 100).toStringAsFixed(0)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Fondo de la etiqueta
    final labelBgRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 4,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Ajustar posición si está fuera del canvas
    final adjustedLabelRect = labelBgRect.top < 0
        ? Rect.fromLTWH(
            rect.left,
            rect.top + 2,
            labelBgRect.width,
            labelBgRect.height,
          )
        : labelBgRect;

    canvas.drawRect(adjustedLabelRect, bgPaint);

    // Dibujar texto de la etiqueta
    textPainter.paint(
      canvas,
      Offset(adjustedLabelRect.left + 4, adjustedLabelRect.top + 2),
    );

    // Dibujar esquinas resaltadas para mejor visibilidad
    _drawCorners(canvas, rect, color);
  }

  /// Dibuja esquinas resaltadas en el bounding box
  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerLength = (rect.width.clamp(20.0, 40.0) * 0.3);
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections;
  }
}

/// Widget que muestra información de estadísticas de detección
/// 
/// Muestra el tiempo de inferencia y número de detecciones.
class DetectionStatsWidget extends StatelessWidget {
  /// Tiempo de la última inferencia en milisegundos
  final int inferenceTimeMs;
  
  /// Número de detecciones actuales
  final int detectionCount;
  
  /// Indica si hay una inferencia en progreso
  final bool isProcessing;

  const DetectionStatsWidget({
    super.key,
    required this.inferenceTimeMs,
    required this.detectionCount,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de procesamiento
          if (isProcessing)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          // Tiempo de inferencia
          Icon(
            Icons.timer_outlined,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${inferenceTimeMs}ms',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          // Número de detecciones
          Icon(
            Icons.radar,
            color: detectionCount > 0 ? Colors.orange : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$detectionCount',
            style: TextStyle(
              color: detectionCount > 0 ? Colors.orange : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

