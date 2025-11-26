/// Eventos del BLoC de detección
/// 
/// Define los eventos que pueden ser disparados para el DetectionBloc,
/// incluyendo carga del modelo, procesamiento de frames y liberación de recursos.
library;

import 'package:equatable/equatable.dart';
import '../../../camera/domain/entities/camera_frame.dart';

/// Clase base abstracta para todos los eventos de detección
abstract class DetectionEvent extends Equatable {
  const DetectionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el modelo TFLite
/// 
/// Debe ser disparado antes de poder procesar frames.
/// Típicamente se dispara al inicializar la pantalla de cámara.
class LoadModelEvent extends DetectionEvent {
  const LoadModelEvent();
}

/// Evento para procesar un frame de la cámara
/// 
/// [frame] - El frame de cámara a procesar para detección
/// 
/// Este evento ejecuta la inferencia del modelo sobre el frame
/// y emite las detecciones encontradas.
class ProcessFrameEvent extends DetectionEvent {
  /// Frame de cámara a procesar
  final CameraFrame frame;

  const ProcessFrameEvent({required this.frame});

  @override
  List<Object?> get props => [frame];
}

/// Evento para liberar recursos del modelo
/// 
/// Debe ser disparado al cerrar la pantalla de cámara
/// para liberar memoria del intérprete TFLite.
class DisposeModelEvent extends DetectionEvent {
  const DisposeModelEvent();
}

/// Evento para limpiar las detecciones actuales
/// 
/// Útil para resetear el estado sin liberar el modelo.
class ClearDetectionsEvent extends DetectionEvent {
  const ClearDetectionsEvent();
}

