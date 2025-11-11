/// Repositorio abstracto para el manejo de la cámara
/// 
/// Define el contrato para la inicialización, captura y gestión
/// del stream de video de la cámara. La implementación concreta
/// se encuentra en la capa de datos.
library;

import '../entities/camera_frame.dart';

/// Repositorio abstracto para operaciones de cámara
/// 
/// Este repositorio define las operaciones necesarias para:
/// - Inicializar y cerrar la cámara
/// - Obtener un stream de frames
/// - Verificar permisos de cámara
abstract class CameraRepository {
  /// Inicializa la cámara y prepara el stream de video
  /// 
  /// Debe ser llamado antes de usar cualquier otro método.
  /// 
  /// Lanza [CameraException] si la inicialización falla.
  /// 
  /// Ejemplo:
  /// ```dart
  /// await repository.initializeCamera();
  /// ```
  Future<void> initializeCamera();

  /// Libera los recursos de la cámara
  /// 
  /// Debe ser llamado cuando la cámara ya no se necesite
  /// para liberar recursos del sistema.
  /// 
  /// Ejemplo:
  /// ```dart
  /// await repository.disposeCamera();
  /// ```
  Future<void> disposeCamera();

  /// Obtiene un stream de frames de la cámara
  /// 
  /// Retorna un stream que emite [CameraFrame] a medida que
  /// se capturan frames del video.
  /// 
  /// El stream se detiene cuando se llama a [disposeCamera].
  /// 
  /// Lanza [CameraException] si la cámara no está inicializada.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final stream = repository.getFrameStream();
  /// stream.listen((frame) {
  ///   // Procesar frame
  /// });
  /// ```
  Stream<CameraFrame> getFrameStream();

  /// Verifica si la aplicación tiene permiso para usar la cámara
  /// 
  /// Retorna `true` si el permiso está concedido, `false` en caso contrario.
  /// 
  /// Ejemplo:
  /// ```dart
  /// if (await repository.hasPermission()) {
  ///   await repository.initializeCamera();
  /// }
  /// ```
  Future<bool> hasPermission();
}

