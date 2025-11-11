/// Entidad que representa un frame capturado de la cámara
/// 
/// Contiene los datos de imagen, dimensiones y timestamp de un frame
/// capturado del stream de video de la cámara.
library;

import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Representa un frame individual capturado de la cámara
/// 
/// Esta entidad es inmutable y contiene toda la información necesaria
/// para procesar un frame de video, incluyendo los bytes de la imagen
/// y sus dimensiones.
class CameraFrame extends Equatable {
  /// Bytes de la imagen capturada
  final Uint8List image;

  /// Timestamp de cuando se capturó el frame
  final DateTime timestamp;

  /// Ancho de la imagen en píxeles
  final int width;

  /// Alto de la imagen en píxeles
  final int height;

  /// Constructor de CameraFrame
  /// 
  /// [image] - Bytes de la imagen (no puede estar vacío)
  /// [timestamp] - Timestamp de captura
  /// [width] - Ancho en píxeles (debe ser > 0)
  /// [height] - Alto en píxeles (debe ser > 0)
  /// 
  /// Lanza [ArgumentError] si los parámetros son inválidos
  CameraFrame({
    required this.image,
    required this.timestamp,
    required this.width,
    required this.height,
  }) {
    if (image.isEmpty) {
      throw ArgumentError('La imagen no puede estar vacía');
    }
    if (width <= 0) {
      throw ArgumentError('El ancho debe ser mayor a 0');
    }
    if (height <= 0) {
      throw ArgumentError('El alto debe ser mayor a 0');
    }
  }

  /// Crea una copia de este CameraFrame con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  CameraFrame copyWith({
    Uint8List? image,
    DateTime? timestamp,
    int? width,
    int? height,
  }) {
    return CameraFrame(
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object> get props => [image, timestamp, width, height];

  @override
  String toString() =>
      'CameraFrame(timestamp: $timestamp, width: $width, height: $height, imageSize: ${image.length} bytes)';
}

