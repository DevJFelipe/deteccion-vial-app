/// Entidad que representa una posición geográfica
/// 
/// Contiene las coordenadas GPS (latitud, longitud), precisión,
/// altitud opcional y timestamp de cuando se obtuvo la ubicación.
library;

import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Representa una posición geográfica obtenida del GPS
/// 
/// Esta entidad es inmutable y contiene toda la información necesaria
/// sobre una ubicación GPS, incluyendo coordenadas, precisión y timestamp.
class Geoposition extends Equatable {
  /// Latitud en grados decimales (-90.0 a 90.0)
  final double latitude;

  /// Longitud en grados decimales (-180.0 a 180.0)
  final double longitude;

  /// Precisión de la ubicación en metros
  /// Valores menores indican mayor precisión
  final double accuracy;

  /// Timestamp de cuando se obtuvo la ubicación
  final DateTime timestamp;

  /// Altitud sobre el nivel del mar en metros (opcional)
  final double? altitude;

  /// Constructor de Geoposition
  /// 
  /// [latitude] - Latitud en grados decimales (debe estar entre -90.0 y 90.0)
  /// [longitude] - Longitud en grados decimales (debe estar entre -180.0 y 180.0)
  /// [accuracy] - Precisión en metros (debe ser >= 0)
  /// [timestamp] - Timestamp de la ubicación
  /// [altitude] - Altitud en metros (opcional)
  /// 
  /// Lanza [ArgumentError] si los parámetros son inválidos
  const Geoposition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
  })  : assert(
          latitude >= -90.0 && latitude <= 90.0,
          'La latitud debe estar entre -90.0 y 90.0',
        ),
        assert(
          longitude >= -180.0 && longitude <= 180.0,
          'La longitud debe estar entre -180.0 y 180.0',
        ),
        assert(accuracy >= 0.0, 'La precisión debe ser mayor o igual a 0');

  /// Verifica si la precisión GPS es aceptable
  /// 
  /// [threshold] - Umbral de precisión máximo en metros (por defecto 10.0)
  /// 
  /// Retorna `true` si la precisión es menor o igual al umbral
  bool isAccuracyAcceptable([double threshold = 10.0]) {
    return accuracy <= threshold;
  }

  /// Calcula la distancia en metros hasta otra posición geográfica
  /// 
  /// Utiliza la fórmula de Haversine para calcular la distancia
  /// entre dos puntos en la superficie de la Tierra.
  /// 
  /// [other] - Otra posición geográfica
  /// 
  /// Retorna la distancia en metros
  double distanceTo(Geoposition other) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros

    final lat1Rad = latitude * (math.pi / 180.0);
    final lat2Rad = other.latitude * (math.pi / 180.0);
    final deltaLat = (other.latitude - latitude) * (math.pi / 180.0);
    final deltaLon = (other.longitude - longitude) * (math.pi / 180.0);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Crea una copia de este Geoposition con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  Geoposition copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    double? altitude,
  }) {
    return Geoposition(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      altitude: altitude ?? this.altitude,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, accuracy, timestamp, altitude];

  @override
  String toString() =>
      'Geoposition(lat: $latitude, lon: $longitude, accuracy: ${accuracy}m, timestamp: $timestamp${altitude != null ? ', altitude: ${altitude}m' : ''})';
}

