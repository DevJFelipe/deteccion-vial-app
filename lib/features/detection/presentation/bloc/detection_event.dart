/// Eventos del BLoC de detección
/// 
/// Define todos los eventos que pueden ser disparados por el usuario
/// o el sistema para interactuar con el sistema de detección.
library;

import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Clase abstracta base para todos los eventos de detección
/// 
/// Todos los eventos deben extender esta clase e implementar
/// la propiedad [props] para comparaciones con Equatable.
abstract class DetectionEvent extends Equatable {
  /// Constructor de DetectionEvent
  const DetectionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el modelo TFLite
/// 
/// Este evento dispara el proceso de carga del modelo TensorFlow Lite
/// desde assets. Debe ser el primer evento disparado antes de iniciar
/// cualquier detección.
/// 
/// El modelo se carga de forma asíncrona y el estado cambia a
/// ModelLoading durante la carga y a ModelLoaded cuando termina.
class LoadModelEvent extends DetectionEvent {
  /// Ruta del modelo en assets
  final String modelPath;

  /// Constructor de LoadModelEvent
  /// 
  /// [modelPath] - Ruta del archivo del modelo (.tflite) en assets
  const LoadModelEvent({required this.modelPath});

  @override
  List<Object?> get props => [modelPath];

  @override
  String toString() => 'LoadModelEvent(modelPath: $modelPath)';
}

/// Evento para iniciar el stream de detecciones en tiempo real
/// 
/// Este evento inicia el procesamiento continuo de frames de la cámara
/// para detectar anomalías viales. Solo puede ejecutarse si el modelo
/// está cargado (estado ModelLoaded).
/// 
/// Al dispararse, el estado cambia a Detecting y comienza a procesar
/// frames automáticamente.
class StartDetectionEvent extends DetectionEvent {
  /// Stream de frames de la cámara (opcional)
  /// 
  /// Si se proporciona, se usará este stream directamente.
  /// Si es null, se intentará obtener del CameraRepository.
  final Stream? frameStream;

  /// Constructor de StartDetectionEvent
  /// 
  /// [frameStream] - Stream de frames de la cámara (opcional)
  StartDetectionEvent({this.frameStream});

  @override
  List<Object?> get props => [frameStream];

  @override
  String toString() => 'StartDetectionEvent(frameStream: ${frameStream != null})';
}

/// Evento para detener las detecciones
/// 
/// Este evento detiene el procesamiento de frames pero mantiene
/// el modelo cargado. El estado cambia a DetectionPaused.
/// 
/// Puede reanudarse con StartDetectionEvent.
class StopDetectionEvent extends DetectionEvent {
  /// Constructor de StopDetectionEvent
  const StopDetectionEvent();

  @override
  String toString() => 'StopDetectionEvent';
}

/// Evento para procesar un frame individual
/// 
/// Este evento procesa un frame de la cámara ejecutando la inferencia
/// del modelo. Normalmente se dispara automáticamente por cada frame
/// del stream cuando está en estado Detecting.
/// 
/// El resultado de la inferencia se actualiza en el estado Detecting
/// junto con métricas de rendimiento (FPS, latencia).
class ProcessFrameEvent extends DetectionEvent {
  /// Bytes de la imagen a procesar
  final Uint8List imageBytes;

  /// Ancho de la imagen en píxeles
  final int width;

  /// Alto de la imagen en píxeles
  final int height;

  /// Constructor de ProcessFrameEvent
  /// 
  /// [imageBytes] - Bytes de la imagen a procesar
  /// [width] - Ancho de la imagen en píxeles
  /// [height] - Alto de la imagen en píxeles
  const ProcessFrameEvent({
    required this.imageBytes,
    required this.width,
    required this.height,
  });

  @override
  List<Object?> get props => [imageBytes, width, height];

  @override
  String toString() =>
      'ProcessFrameEvent(width: $width, height: $height, imageSize: ${imageBytes.length})';
}

/// Evento para liberar todos los recursos
/// 
/// Este evento libera todos los recursos del sistema de detección:
/// - Detiene el stream de frames
/// - Libera recursos del modelo (si es necesario)
/// - Cambia el estado a DetectionInitial
/// 
/// Debe ser llamado cuando la pantalla se cierra o cuando ya no
/// se necesita el sistema de detección.
class DisposeDetectionEvent extends DetectionEvent {
  /// Constructor de DisposeDetectionEvent
  const DisposeDetectionEvent();

  @override
  String toString() => 'DisposeDetectionEvent';
}

