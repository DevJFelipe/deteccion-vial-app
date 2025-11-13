/// Estados del BLoC de detección
/// 
/// Define todos los estados posibles del sistema de detección durante
/// su ciclo de vida. Los estados son inmutables y se usan para actualizar
/// la UI reactivamente.
library;

import 'package:equatable/equatable.dart';
import '../../domain/entities/detection_result.dart';

/// Clase abstracta base para todos los estados de detección
/// 
/// Todos los estados deben extender esta clase e implementar
/// la propiedad [props] para comparaciones con Equatable.
abstract class DetectionState extends Equatable {
  /// Constructor de DetectionState
  const DetectionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial del sistema de detección
/// 
/// Este es el estado inicial cuando el BLoC se crea y el modelo
/// aún no ha sido cargado. La UI debe mostrar un indicador de carga
/// o un botón para iniciar la detección.
class DetectionInitial extends DetectionState {
  /// Constructor de DetectionInitial
  const DetectionInitial();

  @override
  String toString() => 'DetectionInitial';
}

/// Estado de carga durante la inicialización del modelo
/// 
/// Este estado se emite cuando el modelo TFLite está siendo cargado:
/// - Leyendo el archivo del modelo desde assets
/// - Inicializando el intérprete TFLite
/// - Validando la estructura del modelo
/// 
/// La UI debe mostrar un indicador de carga con mensaje informativo.
class ModelLoading extends DetectionState {
  /// Constructor de ModelLoading
  const ModelLoading();

  @override
  String toString() => 'ModelLoading';
}

/// Estado cuando el modelo está cargado exitosamente
/// 
/// Este estado se emite cuando el modelo TFLite se ha cargado
/// correctamente y está listo para ejecutar inferencias.
/// 
/// La UI puede iniciar automáticamente las detecciones o esperar
/// a que el usuario inicie manualmente.
class ModelLoaded extends DetectionState {
  /// Constructor de ModelLoaded
  const ModelLoaded();

  @override
  String toString() => 'ModelLoaded';
}

/// Estado de detección activa
/// 
/// Este estado se emite cuando el sistema está procesando frames
/// de la cámara en tiempo real y ejecutando inferencias.
/// 
/// Contiene las detecciones actuales, métricas de rendimiento
/// (FPS, latencia) y contador de frames procesados.
class Detecting extends DetectionState {
  /// Lista de detecciones actuales
  /// 
  /// Contiene todas las detecciones encontradas en el último frame
  /// procesado que superaron el umbral de confianza.
  final List<DetectionResult> detections;

  /// Frames por segundo actuales
  /// 
  /// Calculado como frames procesados / tiempo transcurrido.
  /// Se actualiza continuamente durante la detección.
  final double fps;

  /// Contador total de frames procesados
  /// 
  /// Incrementa cada vez que se procesa un frame exitosamente.
  final int frameCount;

  /// Latencia de la última inferencia en milisegundos
  /// 
  /// Tiempo transcurrido desde el inicio hasta el fin de la
  /// última inferencia ejecutada.
  final double lastLatency;

  /// Constructor de Detecting
  /// 
  /// [detections] - Lista de detecciones actuales
  /// [fps] - Frames por segundo actuales
  /// [frameCount] - Contador total de frames procesados
  /// [lastLatency] - Latencia de la última inferencia en ms
  const Detecting({
    required this.detections,
    required this.fps,
    required this.frameCount,
    required this.lastLatency,
  });

  /// Crea una copia de este estado con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad del estado.
  Detecting copyWith({
    List<DetectionResult>? detections,
    double? fps,
    int? frameCount,
    double? lastLatency,
  }) {
    return Detecting(
      detections: detections ?? this.detections,
      fps: fps ?? this.fps,
      frameCount: frameCount ?? this.frameCount,
      lastLatency: lastLatency ?? this.lastLatency,
    );
  }

  @override
  List<Object?> get props => [detections, fps, frameCount, lastLatency];

  @override
  String toString() =>
      'Detecting(detections: ${detections.length}, fps: ${fps.toStringAsFixed(1)}, '
      'frameCount: $frameCount, lastLatency: ${lastLatency.toStringAsFixed(1)}ms)';
}

/// Estado de error durante la detección
/// 
/// Este estado se emite cuando ocurre un error en cualquier
/// etapa del ciclo de vida del sistema de detección:
/// - Error al cargar el modelo
/// - Error durante la inferencia
/// - Error al procesar frames
/// 
/// Contiene un mensaje descriptivo del error para mostrar al usuario.
class DetectionError extends DetectionState {
  /// Mensaje descriptivo del error
  /// 
  /// Este mensaje debe ser amigable para el usuario y explicar
  /// qué salió mal y cómo puede solucionarlo.
  final String message;

  /// Constructor de DetectionError
  /// 
  /// [message] - Mensaje descriptivo del error
  const DetectionError({required this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'DetectionError(message: $message)';
}

/// Estado de detección pausada
/// 
/// Este estado se emite cuando las detecciones se han detenido
/// pero el modelo permanece cargado. Puede reanudarse con
/// StartDetectionEvent.
/// 
/// La UI debe mostrar una opción para reanudar las detecciones.
class DetectionPaused extends DetectionState {
  /// Constructor de DetectionPaused
  const DetectionPaused();

  @override
  String toString() => 'DetectionPaused';
}

