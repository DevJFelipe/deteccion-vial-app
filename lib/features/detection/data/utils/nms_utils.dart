/// Utilidades para Non-Maximum Suppression (NMS)
/// 
/// Implementa algoritmos para filtrar detecciones superpuestas
/// usando Intersection over Union (IoU).
library;

import '../../domain/entities/detection_result.dart';
import '../models/detection_constants.dart' show nmsThreshold;

/// Representa una detección con su índice original para NMS
class _DetectionWithIndex {
  final DetectionResult detection;
  final int originalIndex;

  _DetectionWithIndex(this.detection, this.originalIndex);
}

/// Calcula el Intersection over Union (IoU) entre dos bounding boxes
/// 
/// [box1] - Primer bounding box
/// [box2] - Segundo bounding box
/// 
/// Retorna el IoU entre los dos boxes (0.0 a 1.0).
/// 
/// IoU se calcula como:
/// IoU = (área de intersección) / (área de unión)
/// 
/// Un IoU de 1.0 significa que los boxes son idénticos.
/// Un IoU de 0.0 significa que los boxes no se superponen.
double calculateIoU(DetectionResult box1, DetectionResult box2) {
  // Convertir coordenadas normalizadas a coordenadas de esquinas
  // Box1
  final box1X1 = box1.boundingBox.x - box1.boundingBox.width / 2;
  final box1Y1 = box1.boundingBox.y - box1.boundingBox.height / 2;
  final box1X2 = box1.boundingBox.x + box1.boundingBox.width / 2;
  final box1Y2 = box1.boundingBox.y + box1.boundingBox.height / 2;

  // Box2
  final box2X1 = box2.boundingBox.x - box2.boundingBox.width / 2;
  final box2Y1 = box2.boundingBox.y - box2.boundingBox.height / 2;
  final box2X2 = box2.boundingBox.x + box2.boundingBox.width / 2;
  final box2Y2 = box2.boundingBox.y + box2.boundingBox.height / 2;

  // Calcular área de intersección
  final intersectionX1 = box1X1 > box2X1 ? box1X1 : box2X1;
  final intersectionY1 = box1Y1 > box2Y1 ? box1Y1 : box2Y1;
  final intersectionX2 = box1X2 < box2X2 ? box1X2 : box2X2;
  final intersectionY2 = box1Y2 < box2Y2 ? box1Y2 : box2Y2;

  final intersectionWidth = intersectionX2 > intersectionX1
      ? intersectionX2 - intersectionX1
      : 0.0;
  final intersectionHeight = intersectionY2 > intersectionY1
      ? intersectionY2 - intersectionY1
      : 0.0;

  final intersectionArea = intersectionWidth * intersectionHeight;

  // Calcular área de cada box
  final box1Area = box1.boundingBox.width * box1.boundingBox.height;
  final box2Area = box2.boundingBox.width * box2.boundingBox.height;

  // Calcular área de unión
  final unionArea = box1Area + box2Area - intersectionArea;

  // Calcular IoU
  if (unionArea <= 0.0) {
    return 0.0;
  }

  return intersectionArea / unionArea;
}

/// Aplica Non-Maximum Suppression (NMS) a una lista de detecciones
/// 
/// [detections] - Lista de detecciones a filtrar
/// [iouThreshold] - Umbral de IoU para considerar detecciones como superpuestas
/// 
/// Retorna una lista filtrada de detecciones después de aplicar NMS.
/// 
/// Algoritmo NMS:
/// 1. Ordenar detecciones por confianza descendente
/// 2. Para cada detección:
///    - Si no está suprimida, mantenerla
///    - Suprimir todas las demás detecciones con IoU > threshold
/// 3. Retornar detecciones no suprimidas
/// 
/// Ejemplo:
/// ```dart
/// final filtered = applyNMS(detections, iouThreshold: 0.45);
/// ```
List<DetectionResult> applyNMS(
  List<DetectionResult> detections, {
  double iouThreshold = nmsThreshold,
}) {
  if (detections.isEmpty) {
    return detections;
  }

  // Crear lista de detecciones con índices originales
  final detectionsWithIndex = detections
      .asMap()
      .entries
      .map((e) => _DetectionWithIndex(e.value, e.key))
      .toList();

  // Ordenar por confianza descendente
  detectionsWithIndex.sort((a, b) =>
      b.detection.confidence.compareTo(a.detection.confidence));

  // Lista de detecciones a mantener
  final kept = <DetectionResult>[];
  final suppressed = List<bool>.filled(detectionsWithIndex.length, false);

  // Aplicar NMS
  for (var i = 0; i < detectionsWithIndex.length; i++) {
    if (suppressed[i]) {
      continue;
    }

    // Mantener esta detección
    kept.add(detectionsWithIndex[i].detection);

    // Suprimir todas las demás detecciones con IoU > threshold
    for (var j = i + 1; j < detectionsWithIndex.length; j++) {
      if (suppressed[j]) {
        continue;
      }

      final iou = calculateIoU(
        detectionsWithIndex[i].detection,
        detectionsWithIndex[j].detection,
      );

      if (iou > iouThreshold) {
        suppressed[j] = true;
      }
    }
  }

  return kept;
}

