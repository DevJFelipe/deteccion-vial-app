/// Entidad que representa el resultado de una detección
/// 
/// Contiene la información de una detección realizada por el modelo,
/// incluyendo el tipo, confianza, bounding box y timestamp.
library;

import 'package:equatable/equatable.dart';
import 'bounding_box.dart';

/// Representa el resultado de una detección de anomalía vial
/// 
/// Esta entidad es inmutable y contiene toda la información necesaria
/// sobre una detección realizada por el modelo YOLOv8n, incluyendo:
/// - Tipo de anomalía detectada ('hueco' o 'grieta')
/// - Nivel de confianza de la detección
/// - Bounding box que delimita la anomalía
/// - Timestamp de cuando se realizó la detección
class DetectionResult extends Equatable {
  /// Tipo de detección: 'hueco' o 'grieta'
  final String type;

  /// Nivel de confianza de la detección (0.0 a 1.0)
  final double confidence;

  /// Bounding box que delimita la anomalía detectada
  final BoundingBox boundingBox;

  /// Timestamp de cuando se realizó la detección
  final DateTime timestamp;

  /// Constructor de DetectionResult
  /// 
  /// [type] - Tipo de detección ('hueco' o 'grieta')
  /// [confidence] - Nivel de confianza (debe estar entre 0.0 y 1.0)
  /// [boundingBox] - Bounding box de la detección
  /// [timestamp] - Timestamp de la detección
  /// 
  /// Lanza [ArgumentError] si los parámetros son inválidos
  const DetectionResult({
    required this.type,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
  })  : assert(
          type == 'hueco' || type == 'grieta',
          'El tipo debe ser "hueco" o "grieta"',
        ),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'La confianza debe estar entre 0.0 y 1.0',
        );

  /// Verifica si la detección es de tipo 'hueco'
  bool get isHueco => type == 'hueco';

  /// Verifica si la detección es de tipo 'grieta'
  bool get isGrieta => type == 'grieta';

  /// Crea una copia de este DetectionResult con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  DetectionResult copyWith({
    String? type,
    double? confidence,
    BoundingBox? boundingBox,
    DateTime? timestamp,
  }) {
    return DetectionResult(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object> get props => [type, confidence, boundingBox, timestamp];

  @override
  String toString() =>
      'DetectionResult(type: $type, confidence: $confidence, boundingBox: $boundingBox, timestamp: $timestamp)';
}

