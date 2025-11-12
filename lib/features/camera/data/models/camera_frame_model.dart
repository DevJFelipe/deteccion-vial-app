/// Modelo de datos para frames de cámara
/// 
/// Convierte frames nativos de CameraImage (plugin camera) a entidades
/// del domain layer. Implementa conversión optimizada de YUV420 a Uint8List
/// extrayendo solo el plano Y (luminancia) para inferencia con YOLOv8.
library;

import 'dart:typed_data';
import 'package:camera/camera.dart' as camera_package;
import '../../domain/entities/camera_frame.dart';

/// Modelo de datos que representa un frame de cámara en la capa de datos
/// 
/// Este modelo extiende la entidad CameraFrame del domain layer y proporciona
/// métodos de conversión desde objetos nativos del plugin camera.
/// 
/// La conversión YUV420 está optimizada para YOLOv8:
/// - YUV420 es formato planar: Y plane (luminancia) separado de U,V planes
/// - Para inferencia ML: solo necesitamos el plano Y (grayscale)
/// - Evita conversión completa a RGB (más lento y no necesario)
class CameraFrameModel extends CameraFrame {
  /// Constructor privado para el modelo
  /// 
  /// Usar factory constructor [fromCameraImage] para crear instancias
  /// desde objetos CameraImage del plugin camera.
  CameraFrameModel({
    required super.image,
    required super.timestamp,
    required super.width,
    required super.height,
  });

  /// Factory constructor que convierte CameraImage a CameraFrameModel
  /// 
  /// Convierte un frame nativo de la cámara (CameraImage) a nuestro modelo
  /// de datos, extrayendo solo el plano Y del formato YUV420 para optimización.
  /// 
  /// **Proceso de conversión YUV420:**
  /// 1. YUV420 es formato planar con subsampling 2x2:
  ///    - Y plane: width × height bytes (luminancia completa)
  ///    - U plane: (width/2) × (height/2) bytes (crominancia)
  ///    - V plane: (width/2) × (height/2) bytes (crominancia)
  /// 2. Para YOLOv8: solo necesitamos Y plane (grayscale)
  /// 3. Extraemos Y plane directamente sin conversión RGB
  /// 
  /// [cameraImage] - Frame nativo del plugin camera
  /// 
  /// Retorna [CameraFrameModel] con datos convertidos y optimizados
  /// 
  /// Lanza [ArgumentError] si:
  /// - El formato no es YUV420
  /// - Las dimensiones son inválidas
  /// - Los datos del plano Y no están disponibles
  /// 
  /// Ejemplo:
  /// ```dart
  /// final model = CameraFrameModel.fromCameraImage(cameraImage);
  /// final entity = model.toEntity();
  /// ```
  factory CameraFrameModel.fromCameraImage(
      camera_package.CameraImage cameraImage) {
    // Validar formato YUV420
    if (cameraImage.format.group != camera_package.ImageFormatGroup.yuv420) {
      throw ArgumentError(
        'Formato de imagen no soportado. Se requiere YUV420, '
        'pero se recibió: ${cameraImage.format.group}',
      );
    }

    // Extraer dimensiones
    final width = cameraImage.width;
    final height = cameraImage.height;

    if (width <= 0 || height <= 0) {
      throw ArgumentError(
        'Dimensiones inválidas: ${width}x$height',
      );
    }

    // Extraer plano Y (luminancia) del formato YUV420
    // El plano Y es el primer plano y contiene width × height bytes
    final yPlane = cameraImage.planes[0];
    final yBytes = yPlane.bytes;

    // Validar que el tamaño del plano Y sea correcto
    final expectedSize = width * height;
    if (yBytes.length < expectedSize) {
      throw ArgumentError(
        'Tamaño del plano Y inválido. Esperado: $expectedSize bytes, '
        'obtenido: ${yBytes.length} bytes',
      );
    }

    // Crear Uint8List con solo los bytes necesarios del plano Y
    // Usar setRange para evitar copias innecesarias si el tamaño coincide
    final imageData = Uint8List(expectedSize);
    if (yBytes.length == expectedSize) {
      // Copia directa si el tamaño coincide exactamente
      imageData.setRange(0, expectedSize, yBytes);
    } else {
      // Copiar solo los bytes necesarios si hay padding adicional
      imageData.setRange(0, expectedSize, yBytes, 0);
    }

    // Timestamp UTC para sincronización con GPS y ML
    final timestamp = DateTime.now().toUtc();

    return CameraFrameModel(
      image: imageData,
      timestamp: timestamp,
      width: width,
      height: height,
    );
  }

  /// Convierte el modelo a la entidad del domain layer
  /// 
  /// Retorna una instancia de [CameraFrame] que puede ser usada
  /// en la capa de dominio sin exponer detalles de implementación.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final model = CameraFrameModel.fromCameraImage(cameraImage);
  /// final entity = model.toEntity();
  /// // entity es de tipo CameraFrame (domain layer)
  /// ```
  CameraFrame toEntity() {
    return CameraFrame(
      image: image,
      timestamp: timestamp,
      width: width,
      height: height,
    );
  }
}

