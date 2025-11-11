/// Caso de uso para capturar frames de la cámara
/// 
/// Encapsula la lógica de negocio para obtener un stream de frames
/// de la cámara. Este caso de uso se encarga de inicializar la cámara
/// y proporcionar el stream de frames.
library;

import '../entities/camera_frame.dart';
import '../repositories/camera_repository.dart';

/// Caso de uso para capturar frames de la cámara
/// 
/// Este caso de uso maneja la lógica de negocio para:
/// - Verificar permisos antes de inicializar
/// - Inicializar la cámara
/// - Proporcionar un stream de frames
/// 
/// Ejemplo:
/// ```dart
/// final useCase = CaptureFrameUseCase(cameraRepository);
/// final stream = await useCase.call();
/// stream.listen((frame) {
///   // Procesar frame
/// });
/// ```
class CaptureFrameUseCase {
  /// Repositorio de cámara inyectado
  final CameraRepository repository;

  /// Constructor del caso de uso
  /// 
  /// [repository] - Repositorio de cámara a utilizar
  const CaptureFrameUseCase(this.repository);

  /// Ejecuta el caso de uso y retorna un stream de frames
  /// 
  /// Primero verifica los permisos y luego inicializa la cámara
  /// antes de retornar el stream.
  /// 
  /// Retorna un [Stream<CameraFrame>] que emite frames capturados.
  /// 
  /// Lanza [CameraException] si:
  /// - No hay permisos de cámara
  /// - La inicialización de la cámara falla
  /// 
  /// Ejemplo:
  /// ```dart
  /// final stream = await useCase.call();
  /// stream.listen((frame) {
  ///   print('Frame capturado: ${frame.width}x${frame.height}');
  /// });
  /// ```
  Future<Stream<CameraFrame>> call() async {
    // Verificar permisos antes de inicializar
    final hasPermission = await repository.hasPermission();
    if (!hasPermission) {
      throw Exception('Permiso de cámara denegado');
    }

    // Inicializar la cámara
    await repository.initializeCamera();

    // Retornar el stream de frames
    return repository.getFrameStream();
  }
}

