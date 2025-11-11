/// Entidad que representa un bounding box (caja delimitadora)
/// 
/// Contiene las coordenadas normalizadas (0-1) de un bounding box
/// y proporciona métodos para convertir a coordenadas en píxeles.
library;

import 'package:equatable/equatable.dart';

/// Representa un bounding box con coordenadas normalizadas
/// 
/// Las coordenadas están normalizadas entre 0.0 y 1.0, donde:
/// - (0, 0) es la esquina superior izquierda
/// - (1, 1) es la esquina inferior derecha
/// 
/// Esta entidad es inmutable y proporciona métodos para convertir
/// las coordenadas normalizadas a píxeles.
class BoundingBox extends Equatable {
  /// Coordenada X del centro del bounding box (normalizada 0-1)
  final double x;

  /// Coordenada Y del centro del bounding box (normalizada 0-1)
  final double y;

  /// Ancho del bounding box (normalizado 0-1)
  final double width;

  /// Alto del bounding box (normalizado 0-1)
  final double height;

  /// Constructor de BoundingBox
  /// 
  /// [x] - Coordenada X del centro (debe estar entre 0.0 y 1.0)
  /// [y] - Coordenada Y del centro (debe estar entre 0.0 y 1.0)
  /// [width] - Ancho (debe estar entre 0.0 y 1.0)
  /// [height] - Alto (debe estar entre 0.0 y 1.0)
  /// 
  /// Lanza [ArgumentError] si los parámetros están fuera del rango válido
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  })  : assert(x >= 0.0 && x <= 1.0, 'x debe estar entre 0.0 y 1.0'),
        assert(y >= 0.0 && y <= 1.0, 'y debe estar entre 0.0 y 1.0'),
        assert(width >= 0.0 && width <= 1.0, 'width debe estar entre 0.0 y 1.0'),
        assert(height >= 0.0 && height <= 1.0, 'height debe estar entre 0.0 y 1.0');

  /// Convierte las coordenadas normalizadas a píxeles
  /// 
  /// [imageWidth] - Ancho de la imagen en píxeles
  /// [imageHeight] - Alto de la imagen en píxeles
  /// 
  /// Retorna un mapa con las coordenadas en píxeles:
  /// - 'x': coordenada X del centro en píxeles
  /// - 'y': coordenada Y del centro en píxeles
  /// - 'width': ancho en píxeles
  /// - 'height': alto en píxeles
  /// - 'left': coordenada X de la esquina superior izquierda
  /// - 'top': coordenada Y de la esquina superior izquierda
  /// - 'right': coordenada X de la esquina inferior derecha
  /// - 'bottom': coordenada Y de la esquina inferior derecha
  /// 
  /// Ejemplo:
  /// ```dart
  /// final pixels = boundingBox.toPixels(640, 480);
  /// final left = pixels['left'] as int;
  /// ```
  Map<String, int> toPixels(int imageWidth, int imageHeight) {
    final centerX = (x * imageWidth).round();
    final centerY = (y * imageHeight).round();
    final boxWidth = (width * imageWidth).round();
    final boxHeight = (height * imageHeight).round();

    final left = (centerX - boxWidth / 2).round();
    final top = (centerY - boxHeight / 2).round();
    final right = (centerX + boxWidth / 2).round();
    final bottom = (centerY + boxHeight / 2).round();

    return {
      'x': centerX,
      'y': centerY,
      'width': boxWidth,
      'height': boxHeight,
      'left': left.clamp(0, imageWidth),
      'top': top.clamp(0, imageHeight),
      'right': right.clamp(0, imageWidth),
      'bottom': bottom.clamp(0, imageHeight),
    };
  }

  /// Crea una copia de este BoundingBox con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  BoundingBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BoundingBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object> get props => [x, y, width, height];

  @override
  String toString() =>
      'BoundingBox(x: $x, y: $y, width: $width, height: $height)';
}

