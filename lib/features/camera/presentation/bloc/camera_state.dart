/// Estados del BLoC de cámara
/// 
/// Define todos los estados posibles de la cámara durante su ciclo de vida.
/// Los estados son inmutables y se usan para actualizar la UI reactivamente.
library;

import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../domain/entities/camera_frame.dart';

/// Clase abstracta base para todos los estados de cámara
/// 
/// Todos los estados deben extender esta clase e implementar
/// la propiedad [props] para comparaciones con Equatable.
abstract class CameraState extends Equatable {
  /// Constructor de CameraState
  const CameraState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial de la cámara
/// 
/// Este es el estado inicial cuando el BLoC se crea y la cámara
/// aún no ha sido inicializada. La UI debe mostrar un indicador
/// de carga o un botón para iniciar la cámara.
class CameraInitial extends CameraState {
  /// Constructor de CameraInitial
  const CameraInitial();

  @override
  String toString() => 'CameraInitial';
}

/// Estado de carga durante la inicialización
/// 
/// Este estado se emite cuando la cámara está siendo inicializada:
/// - Verificando permisos
/// - Inicializando el hardware
/// - Configurando el stream
/// 
/// La UI debe mostrar un indicador de carga.
class CameraLoading extends CameraState {
  /// Constructor de CameraLoading
  const CameraLoading();

  @override
  String toString() => 'CameraLoading';
}

/// Estado de streaming activo
/// 
/// Este estado se emite cuando la cámara está inicializada y
/// emitiendo frames. Contiene el stream de frames para que
/// los widgets puedan consumirlo.
class CameraStreaming extends CameraState {
  /// Stream de frames de la cámara
  /// 
  /// Este stream emite [CameraFrame] a medida que se capturan
  /// frames del video. Los widgets pueden suscribirse a este
  /// stream para mostrar el preview en tiempo real.
  final Stream<CameraFrame> frameStream;

  /// Constructor de CameraStreaming
  /// 
  /// [frameStream] - Stream de frames de la cámara
  const CameraStreaming({
    required this.frameStream,
  });

  @override
  List<Object?> get props => [frameStream];

  @override
  String toString() => 'CameraStreaming';
}

/// Estado de error
/// 
/// Este estado se emite cuando ocurre un error en cualquier
/// etapa del ciclo de vida de la cámara. Contiene un mensaje
/// descriptivo del error para mostrar al usuario.
class CameraError extends CameraState {
  /// Mensaje descriptivo del error
  /// 
  /// Este mensaje debe ser amigable para el usuario y explicar
  /// qué salió mal y cómo puede solucionarlo.
  final String errorMessage;

  /// Constructor de CameraError
  /// 
  /// [errorMessage] - Mensaje descriptivo del error
  const CameraError({
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [errorMessage];

  @override
  String toString() => 'CameraError(errorMessage: $errorMessage)';
}

/// Estado de permiso denegado
/// 
/// Este estado se emite cuando el usuario deniega el permiso
/// de cámara. Contiene información sobre qué permiso fue denegado.
class PermissionDenied extends CameraState {
  /// Tipo de permiso que fue denegado
  /// 
  /// Normalmente será "camera" pero puede incluir otros permisos
  /// relacionados si se requieren en el futuro.
  final String? permissionType;

  /// Constructor de PermissionDenied
  /// 
  /// [permissionType] - Tipo de permiso denegado (opcional)
  const PermissionDenied({
    this.permissionType,
  });

  @override
  List<Object?> get props => [permissionType];

  @override
  String toString() => 'PermissionDenied(permissionType: $permissionType)';
}

/// Estado de cámara liberada
/// 
/// Este estado se emite cuando la cámara ha sido completamente
/// liberada y los recursos han sido limpiados. La UI puede
/// mostrar un mensaje indicando que la cámara fue cerrada.
class CameraDisposed extends CameraState {
  /// Constructor de CameraDisposed
  const CameraDisposed();

  @override
  String toString() => 'CameraDisposed';
}

