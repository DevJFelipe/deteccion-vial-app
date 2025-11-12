/// Implementación concreta del datasource de cámara
/// 
/// Usa el plugin camera oficial de Flutter para interactuar con
/// el hardware de cámara del dispositivo. Gestiona el ciclo de vida
/// completo de la cámara, incluyendo inicialización, captura de frames
/// y liberación de recursos.
library;

import 'dart:async';
import 'package:camera/camera.dart' as camera_package;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/error/exceptions.dart' show CameraException;
import 'camera_datasource.dart';

/// Implementación concreta de [CameraDataSource]
/// 
/// Esta clase gestiona el hardware de cámara usando [CameraController]
/// del plugin camera. Proporciona:
/// - Inicialización con configuración optimizada para YOLOv8
/// - Stream continuo de frames en formato YUV420
/// - Gestión de permisos usando permission_handler
/// - Manejo robusto de errores y excepciones
class CameraDataSourceImpl implements CameraDataSource {
  /// Controlador de cámara del plugin camera
  camera_package.CameraController? _controller;

  /// StreamController para emitir frames a múltiples listeners
  StreamController<camera_package.CameraImage>? _imageStreamController;

  /// Flag para rastrear si el stream está activo
  bool _isStreamActive = false;

  @override
  bool get isInitialized =>
      _controller?.value.isInitialized ?? false;


  @override
  Future<void> initialize() async {
    try {
      // Verificar permisos antes de inicializar
      final hasPermissionValue = await hasPermission();
      if (!hasPermissionValue) {
        throw CameraException(
          'Permiso de cámara no concedido. '
          'Debe solicitar permiso antes de inicializar.',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      // Obtener lista de cámaras disponibles
      final cameras = await camera_package.availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'No hay cámaras disponibles en el dispositivo',
          errorCode: 'NO_CAMERAS_AVAILABLE',
        );
      }

      // Seleccionar cámara trasera por defecto
      // Buscar cámara trasera, si no existe usar la primera disponible
      final backCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection == camera_package.CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Crear controlador de cámara con configuración optimizada
      // ResolutionPreset.medium = 640×480 (mínimo requerido)
      // ImageFormatGroup.yuv420 = formato nativo para streams (crítico)
      _controller = camera_package.CameraController(
        backCamera,
        camera_package.ResolutionPreset.medium,
        imageFormatGroup: camera_package.ImageFormatGroup.yuv420,
        enableAudio: false, // No necesitamos audio para detección vial
      );

      // Inicializar el controlador
      await _controller!.initialize();

      // Verificar que la inicialización fue exitosa
      if (!_controller!.value.isInitialized) {
        throw CameraException(
          'La cámara no se pudo inicializar correctamente',
          errorCode: 'INITIALIZATION_FAILED',
        );
      }

      // Crear StreamController de tipo broadcast para múltiples listeners
      _imageStreamController =
          StreamController<camera_package.CameraImage>.broadcast();
    } on CameraException {
      // Re-lanzar CameraException sin modificar
      rethrow;
    } on Exception catch (e) {
      // Transformar excepciones genéricas a CameraException
      throw CameraException(
        'Error al inicializar la cámara: ${e.toString()}',
        errorCode: 'INITIALIZATION_ERROR',
      );
    } catch (e) {
      // Capturar cualquier otro error
      throw CameraException(
        'Error inesperado al inicializar la cámara: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Stream<camera_package.CameraImage> getImageStream() {
    if (!isInitialized) {
      throw CameraException(
        'La cámara no está inicializada. '
        'Debe llamar a initialize() primero.',
        errorCode: 'NOT_INITIALIZED',
      );
    }

    if (_imageStreamController == null || _imageStreamController!.isClosed) {
      throw CameraException(
        'El stream controller no está disponible',
        errorCode: 'STREAM_CONTROLLER_CLOSED',
      );
    }

    // Iniciar el stream de imágenes si no está activo
    if (!_isStreamActive) {
      _startImageStream();
    }

    return _imageStreamController!.stream;
  }

  /// Inicia el stream de imágenes desde el controlador de cámara
  /// 
  /// Configura el callback del controlador para emitir cada frame
  /// al StreamController, permitiendo múltiples listeners.
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException(
        'No se puede iniciar el stream: cámara no inicializada',
        errorCode: 'STREAM_START_FAILED',
      );
    }

    _controller!.startImageStream((camera_package.CameraImage image) {
      // Emitir frame al StreamController si está abierto
      if (_imageStreamController != null &&
          !_imageStreamController!.isClosed) {
        _imageStreamController!.add(image);
      }
    });

    _isStreamActive = true;
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      // En caso de error, asumir que no hay permiso
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      // En caso de error, retornar false
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      // Orden crítico: detener stream antes de dispose
      if (_isStreamActive && _controller != null) {
        try {
          await _controller!.stopImageStream();
          _isStreamActive = false;
        } catch (e) {
          // Log error pero continuar con dispose
          // No lanzar excepción para asegurar limpieza de recursos
        }
      }

      // Cerrar StreamController
      if (_imageStreamController != null && !_imageStreamController!.isClosed) {
        await _imageStreamController!.close();
      }
      _imageStreamController = null;

      // Liberar controlador de cámara
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      // Asegurar que los recursos se limpien incluso si hay errores
      _controller = null;
      _imageStreamController = null;
      _isStreamActive = false;
      
      // Re-lanzar excepción para que el caller sepa que hubo un problema
      throw CameraException(
        'Error al liberar recursos de la cámara: ${e.toString()}',
        errorCode: 'DISPOSE_ERROR',
      );
    }
  }
}

