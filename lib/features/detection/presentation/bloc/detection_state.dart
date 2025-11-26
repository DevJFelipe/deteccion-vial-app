/// Estados del BLoC de detección
/// 
/// Define los posibles estados del DetectionBloc, representando
/// el ciclo de vida completo del sistema de detección.
library;

import 'package:equatable/equatable.dart';
import '../../domain/entities/detection_result.dart';

/// Clase base abstracta para todos los estados de detección
abstract class DetectionState extends Equatable {
  const DetectionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar el modelo
class DetectionInitial extends DetectionState {
  const DetectionInitial();
}

/// Estado mientras se carga el modelo TFLite
class DetectionModelLoading extends DetectionState {
  const DetectionModelLoading();
}

/// Estado cuando el modelo está cargado y listo para procesar frames
/// 
/// [detections] - Lista de detecciones actuales (puede estar vacía)
/// [inferenceTimeMs] - Tiempo de la última inferencia en milisegundos
/// [isProcessing] - Indica si hay una inferencia en progreso
class DetectionReady extends DetectionState {
  /// Lista de detecciones actuales
  final List<DetectionResult> detections;
  
  /// Tiempo de la última inferencia en milisegundos
  final int inferenceTimeMs;
  
  /// Indica si hay una inferencia en progreso
  final bool isProcessing;

  const DetectionReady({
    this.detections = const [],
    this.inferenceTimeMs = 0,
    this.isProcessing = false,
  });

  /// Crea una copia con valores modificados
  DetectionReady copyWith({
    List<DetectionResult>? detections,
    int? inferenceTimeMs,
    bool? isProcessing,
  }) {
    return DetectionReady(
      detections: detections ?? this.detections,
      inferenceTimeMs: inferenceTimeMs ?? this.inferenceTimeMs,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [detections, inferenceTimeMs, isProcessing];
}

/// Estado de error al cargar el modelo o durante la inferencia
/// 
/// [message] - Mensaje descriptivo del error
/// [canRetry] - Indica si se puede reintentar la operación
class DetectionError extends DetectionState {
  /// Mensaje descriptivo del error
  final String message;
  
  /// Indica si se puede reintentar la operación
  final bool canRetry;

  const DetectionError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

/// Estado cuando el modelo ha sido liberado
class DetectionDisposed extends DetectionState {
  const DetectionDisposed();
}

