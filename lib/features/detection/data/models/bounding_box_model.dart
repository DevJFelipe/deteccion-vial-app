/// Modelo de datos para BoundingBox
/// 
/// Extiende la entidad BoundingBox del domain layer y proporciona
/// métodos adicionales para conversión y manipulación en la capa de datos.
library;

import '../../domain/entities/bounding_box.dart';

/// Modelo de datos para BoundingBox
/// 
/// Extiende la entidad [BoundingBox] del domain layer y proporciona
/// métodos adicionales para conversión a píxeles y obtención de esquinas.
/// 
/// Este modelo se usa en la capa de datos para convertir resultados
/// del modelo TFLite a entidades del dominio.
class BoundingBoxModel extends BoundingBox {
  /// Constructor de BoundingBoxModel
  /// 
  /// [x] - Coordenada X del centro (normalizada 0-1)
  /// [y] - Coordenada Y del centro (normalizada 0-1)
  /// [width] - Ancho (normalizado 0-1)
  /// [height] - Alto (normalizado 0-1)
  /// 
  /// Lanza [ArgumentError] si los valores están fuera del rango válido
  const BoundingBoxModel({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  });

  /// Crea un BoundingBoxModel desde coordenadas normalizadas
  /// 
  /// [x] - Coordenada X del centro (normalizada 0-1)
  /// [y] - Coordenada Y del centro (normalizada 0-1)
  /// [width] - Ancho (normalizado 0-1)
  /// [height] - Alto (normalizado 0-1)
  /// 
  /// Valida que los valores estén en el rango [0-1] y lanza [ArgumentError]
  /// si están fuera de rango.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final bbox = BoundingBoxModel.fromNormalized(
  ///   x: 0.5,
  ///   y: 0.5,
  ///   width: 0.2,
  ///   height: 0.2,
  /// );
  /// ```
  factory BoundingBoxModel.fromNormalized({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    // Validar que los valores estén en el rango [0-1]
    if (x < 0.0 || x > 1.0) {
      throw ArgumentError(
        'x debe estar entre 0.0 y 1.0, pero se recibió: $x',
      );
    }
    if (y < 0.0 || y > 1.0) {
      throw ArgumentError(
        'y debe estar entre 0.0 y 1.0, pero se recibió: $y',
      );
    }
    if (width < 0.0 || width > 1.0) {
      throw ArgumentError(
        'width debe estar entre 0.0 y 1.0, pero se recibió: $width',
      );
    }
    if (height < 0.0 || height > 1.0) {
      throw ArgumentError(
        'height debe estar entre 0.0 y 1.0, pero se recibió: $height',
      );
    }

    return BoundingBoxModel(
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

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
  @override
  Map<String, int> toPixels(int imageWidth, int imageHeight) {
    return super.toPixels(imageWidth, imageHeight);
  }

  /// Obtiene la esquina superior izquierda del bounding box en píxeles
  /// 
  /// [imageWidth] - Ancho de la imagen en píxeles
  /// [imageHeight] - Alto de la imagen en píxeles
  /// 
  /// Retorna un mapa con las coordenadas 'x' e 'y' de la esquina superior izquierda.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final topLeft = boundingBox.topLeft(640, 480);
  /// final leftX = topLeft['x'] as int;
  /// final topY = topLeft['y'] as int;
  /// ```
  Map<String, int> topLeft(int imageWidth, int imageHeight) {
    final pixels = toPixels(imageWidth, imageHeight);
    return {
      'x': pixels['left']!,
      'y': pixels['top']!,
    };
  }

  /// Obtiene la esquina superior derecha del bounding box en píxeles
  /// 
  /// [imageWidth] - Ancho de la imagen en píxeles
  /// [imageHeight] - Alto de la imagen en píxeles
  /// 
  /// Retorna un mapa con las coordenadas 'x' e 'y' de la esquina superior derecha.
  Map<String, int> topRight(int imageWidth, int imageHeight) {
    final pixels = toPixels(imageWidth, imageHeight);
    return {
      'x': pixels['right']!,
      'y': pixels['top']!,
    };
  }

  /// Obtiene la esquina inferior izquierda del bounding box en píxeles
  /// 
  /// [imageWidth] - Ancho de la imagen en píxeles
  /// [imageHeight] - Alto de la imagen en píxeles
  /// 
  /// Retorna un mapa con las coordenadas 'x' e 'y' de la esquina inferior izquierda.
  Map<String, int> bottomLeft(int imageWidth, int imageHeight) {
    final pixels = toPixels(imageWidth, imageHeight);
    return {
      'x': pixels['left']!,
      'y': pixels['bottom']!,
    };
  }

  /// Obtiene la esquina inferior derecha del bounding box en píxeles
  /// 
  /// [imageWidth] - Ancho de la imagen en píxeles
  /// [imageHeight] - Alto de la imagen en píxeles
  /// 
  /// Retorna un mapa con las coordenadas 'x' e 'y' de la esquina inferior derecha.
  Map<String, int> bottomRight(int imageWidth, int imageHeight) {
    final pixels = toPixels(imageWidth, imageHeight);
    return {
      'x': pixels['right']!,
      'y': pixels['bottom']!,
    };
  }

  /// Convierte este modelo a la entidad del domain layer
  /// 
  /// Retorna una instancia de [BoundingBox] del domain layer.
  /// Como BoundingBoxModel extiende BoundingBox, simplemente retorna this.
  BoundingBox toEntity() {
    return BoundingBox(
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}

