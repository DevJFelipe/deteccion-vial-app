/// Eventos del BLoC de cámara
/// 
/// Define todos los eventos que pueden ser disparados por el usuario
/// o el sistema para interactuar con la cámara.
library;

import 'package:equatable/equatable.dart';

/// Clase abstracta base para todos los eventos de cámara
/// 
/// Todos los eventos deben extender esta clase e implementar
/// la propiedad [props] para comparaciones con Equatable.
abstract class CameraEvent extends Equatable {
  /// Constructor de CameraEvent
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar la cámara
/// 
/// Este evento dispara el proceso de inicialización de la cámara:
/// 1. Verifica permisos de cámara
/// 2. Solicita permisos si no están concedidos
/// 3. Inicializa el hardware de cámara
/// 4. Obtiene el stream de frames
/// 
/// Debe ser el primer evento disparado antes de usar la cámara.
class InitializeCameraEvent extends CameraEvent {
  /// Constructor de InitializeCameraEvent
  const InitializeCameraEvent();

  @override
  String toString() => 'InitializeCameraEvent';
}

/// Evento para iniciar explícitamente el stream de frames
/// 
/// Este evento inicia el stream de frames de la cámara.
/// Es útil para control explícito del streaming, aunque
/// normalmente el stream se inicia automáticamente al inicializar.
class StartStreamingEvent extends CameraEvent {
  /// Constructor de StartStreamingEvent
  const StartStreamingEvent();

  @override
  String toString() => 'StartStreamingEvent';
}

/// Evento para detener el stream de frames
/// 
/// Este evento detiene el consumo del stream de frames pero
/// no libera los recursos de la cámara. La cámara permanece
/// inicializada y puede reanudar el streaming.
class StopStreamingEvent extends CameraEvent {
  /// Constructor de StopStreamingEvent
  const StopStreamingEvent();

  @override
  String toString() => 'StopStreamingEvent';
}

/// Evento para liberar todos los recursos de la cámara
/// 
/// Este evento libera completamente los recursos de la cámara:
/// - Detiene el stream de frames
/// - Libera el controlador de cámara
/// - Libera recursos del hardware
/// 
/// Debe ser llamado cuando la cámara ya no se necesite,
/// típicamente al cerrar la pantalla de cámara.
class DisposeCameraEvent extends CameraEvent {
  /// Constructor de DisposeCameraEvent
  const DisposeCameraEvent();

  @override
  String toString() => 'DisposeCameraEvent';
}

/// Evento para solicitar permiso de cámara
/// 
/// Este evento solicita explícitamente el permiso de cámara
/// al sistema operativo. Muestra el diálogo nativo del sistema
/// para que el usuario conceda o deniegue el permiso.
class RequestPermissionEvent extends CameraEvent {
  /// Constructor de RequestPermissionEvent
  const RequestPermissionEvent();

  @override
  String toString() => 'RequestPermissionEvent';
}

