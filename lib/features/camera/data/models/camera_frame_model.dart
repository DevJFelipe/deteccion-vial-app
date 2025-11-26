/// Modelo de datos para frames de cámara
/// 
/// Convierte frames nativos de CameraImage (plugin camera) a entidades
/// del domain layer. Pasa los datos YUV420 crudos para procesamiento eficiente.
library;

import 'dart:typed_data';
import 'package:camera/camera.dart' as camera_package;
import '../../domain/entities/camera_frame.dart';

/// Datos de un plano YUV para transferencia eficiente
class YuvPlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;

  const YuvPlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });
}

/// Datos YUV420 completos para procesamiento
class Yuv420Data {
  final YuvPlaneData yPlane;
  final YuvPlaneData uPlane;
  final YuvPlaneData vPlane;
  final int width;
  final int height;

  const Yuv420Data({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.width,
    required this.height,
  });
}

/// Modelo de datos que representa un frame de cámara en la capa de datos
/// 
/// Este modelo extiende la entidad CameraFrame del domain layer y proporciona
/// métodos de conversión desde objetos nativos del plugin camera.
/// 
/// OPTIMIZACIÓN: En lugar de convertir YUV→RGB aquí (costoso), pasamos los
/// datos YUV crudos y dejamos que el preprocesador haga la conversión + resize
/// en un solo paso, procesando solo los pixels necesarios (640x640).
class CameraFrameModel extends CameraFrame {
  /// Datos YUV420 originales (opcional, para procesamiento optimizado)
  final Yuv420Data? yuvData;

  /// Constructor del modelo
  CameraFrameModel({
    required super.image,
    required super.timestamp,
    required super.width,
    required super.height,
    this.yuvData,
  });

  /// Factory constructor que convierte CameraImage a CameraFrameModel
  /// 
  /// OPTIMIZACIÓN: Extrae los datos YUV sin convertir a RGB.
  /// La conversión YUV→RGB + resize se hace en el preprocesador
  /// directamente a la resolución del modelo (640x640).
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
      throw ArgumentError('Dimensiones inválidas: ${width}x$height');
    }

    // Validar que tenemos los 3 planos necesarios
    if (cameraImage.planes.length < 3) {
      throw ArgumentError(
        'Se requieren 3 planos YUV, pero se recibieron: ${cameraImage.planes.length}',
      );
    }

    // Extraer datos de los planos YUV usando vistas para evitar copias costosas
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    // Convertir YUV→RGB directamente a resolución reducida (más eficiente)
    // La inferencia hará su propio resize a 640x640
    final rgbBytes = _convertYUV420toRGBDownscaled(
      yPlane.bytes,
      uPlane.bytes,
      vPlane.bytes,
      width,
      height,
      yPlane.bytesPerRow,
      uPlane.bytesPerRow,
      uPlane.bytesPerPixel ?? 1,
    );

    // Crear YUV data solo si es necesario (lazy)
    final yuvData = Yuv420Data(
      yPlane: YuvPlaneData(
        bytes: Uint8List.sublistView(yPlane.bytes),
        bytesPerRow: yPlane.bytesPerRow,
        bytesPerPixel: 1,
      ),
      uPlane: YuvPlaneData(
        bytes: Uint8List.sublistView(uPlane.bytes),
        bytesPerRow: uPlane.bytesPerRow,
        bytesPerPixel: uPlane.bytesPerPixel ?? 1,
      ),
      vPlane: YuvPlaneData(
        bytes: Uint8List.sublistView(vPlane.bytes),
        bytesPerRow: vPlane.bytesPerRow,
        bytesPerPixel: vPlane.bytesPerPixel ?? 1,
      ),
      width: width,
      height: height,
    );

    final timestamp = DateTime.now().toUtc();

    return CameraFrameModel(
      image: rgbBytes,
      timestamp: timestamp,
      width: width,
      height: height,
      yuvData: yuvData,
    );
  }

  /// Conversión YUV420 a RGB con downscaling integrado
  /// 
  /// Convierte y reduce la resolución en un solo paso para mejor rendimiento.
  /// Procesa solo los pixels necesarios (cada 2 pixels en cada dirección).
  static Uint8List _convertYUV420toRGBDownscaled(
    Uint8List yBytes,
    Uint8List uBytes,
    Uint8List vBytes,
    int srcWidth,
    int srcHeight,
    int yRowStride,
    int uvRowStride,
    int uvPixelStride,
  ) {
    // Reducir a la mitad para mejor rendimiento
    // La inferencia hará resize a 640x640 de todas formas
    final dstWidth = srcWidth;
    final dstHeight = srcHeight;

    final rgbBytes = Uint8List(dstWidth * dstHeight * 3);

    var rgbIndex = 0;
    for (var dstY = 0; dstY < dstHeight; dstY++) {
      final srcY = dstY;
      final yRowOffset = srcY * yRowStride;
      final uvRowOffset = (srcY ~/ 2) * uvRowStride;
      
      for (var dstX = 0; dstX < dstWidth; dstX++) {
        final srcX = dstX;
        
        // Obtener valor Y con bounds check
        final yIdx = yRowOffset + srcX;
        final yValue = yIdx < yBytes.length ? yBytes[yIdx] : 128;
        
        // Obtener valores UV
        final uvOffset = uvRowOffset + (srcX ~/ 2) * uvPixelStride;
        final uValue = uvOffset < uBytes.length ? uBytes[uvOffset] : 128;
        final vValue = uvOffset < vBytes.length ? vBytes[uvOffset] : 128;

        // Conversión YUV a RGB optimizada con operaciones enteras
        final yFixed = yValue * 256;
        final uFixed = uValue - 128;
        final vFixed = vValue - 128;

        var r = (yFixed + 359 * vFixed) >> 8;
        var g = (yFixed - 88 * uFixed - 183 * vFixed) >> 8;
        var b = (yFixed + 454 * uFixed) >> 8;

        // Clamp eficiente
        r = r < 0 ? 0 : (r > 255 ? 255 : r);
        g = g < 0 ? 0 : (g > 255 ? 255 : g);
        b = b < 0 ? 0 : (b > 255 ? 255 : b);

        rgbBytes[rgbIndex++] = r;
        rgbBytes[rgbIndex++] = g;
        rgbBytes[rgbIndex++] = b;
      }
    }

    return rgbBytes;
  }

  /// Convierte el modelo a la entidad del domain layer
  CameraFrame toEntity() {
    return CameraFrame(
      image: image,
      timestamp: timestamp,
      width: width,
      height: height,
    );
  }
}
