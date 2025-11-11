/// Entidad que representa un hallazgo de anomalía vial
/// 
/// Contiene toda la información de una detección guardada, incluyendo
/// coordenadas GPS, tipo de anomalía, confianza, imagen y estado de sincronización.
library;

import 'package:equatable/equatable.dart';

/// Representa un hallazgo de anomalía vial almacenado localmente
/// 
/// Esta entidad es inmutable y contiene toda la información necesaria
/// sobre un hallazgo detectado, incluyendo:
/// - Identificador único (UUID)
/// - Tipo de anomalía ('hueco' o 'grieta')
/// - Coordenadas GPS
/// - Precisión GPS
/// - Nivel de confianza de la detección
/// - Ruta de la imagen guardada
/// - Estado de sincronización con servidor
class Hallazgo extends Equatable {
  /// Identificador único del hallazgo (UUID)
  final String id;

  /// Tipo de anomalía: 'hueco' o 'grieta'
  final String tipo;

  /// Latitud de la ubicación donde se detectó la anomalía
  final double latitud;

  /// Longitud de la ubicación donde se detectó la anomalía
  final double longitud;

  /// Precisión GPS en metros cuando se detectó la anomalía
  final double precisionGps;

  /// Nivel de confianza de la detección (0.0 a 1.0)
  final double confianza;

  /// Timestamp de cuando se detectó la anomalía
  final DateTime timestamp;

  /// Ruta local de la imagen guardada
  final String imagenPath;

  /// Indica si el hallazgo ha sido sincronizado con el servidor
  final bool sincronizado;

  /// Constructor de Hallazgo
  /// 
  /// [id] - Identificador único (UUID)
  /// [tipo] - Tipo de anomalía ('hueco' o 'grieta')
  /// [latitud] - Latitud en grados decimales
  /// [longitud] - Longitud en grados decimales
  /// [precisionGps] - Precisión GPS en metros
  /// [confianza] - Nivel de confianza (0.0 a 1.0)
  /// [timestamp] - Timestamp de la detección
  /// [imagenPath] - Ruta de la imagen
  /// [sincronizado] - Estado de sincronización (por defecto false)
  /// 
  /// Lanza [ArgumentError] si los parámetros son inválidos
  Hallazgo({
    required this.id,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.precisionGps,
    required this.confianza,
    required this.timestamp,
    required this.imagenPath,
    this.sincronizado = false,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('El ID no puede estar vacío');
    }
    if (tipo != 'hueco' && tipo != 'grieta') {
      throw ArgumentError('El tipo debe ser "hueco" o "grieta"');
    }
    if (latitud < -90.0 || latitud > 90.0) {
      throw ArgumentError('La latitud debe estar entre -90.0 y 90.0');
    }
    if (longitud < -180.0 || longitud > 180.0) {
      throw ArgumentError('La longitud debe estar entre -180.0 y 180.0');
    }
    if (precisionGps < 0.0) {
      throw ArgumentError('La precisión GPS debe ser mayor o igual a 0');
    }
    if (confianza < 0.0 || confianza > 1.0) {
      throw ArgumentError('La confianza debe estar entre 0.0 y 1.0');
    }
    if (imagenPath.isEmpty) {
      throw ArgumentError('La ruta de imagen no puede estar vacía');
    }
  }

  /// Verifica si el hallazgo es de tipo 'hueco'
  bool get isHueco => tipo == 'hueco';

  /// Verifica si el hallazgo es de tipo 'grieta'
  bool get isGrieta => tipo == 'grieta';

  /// Verifica si el hallazgo necesita ser sincronizado
  bool get necesitaSincronizacion => !sincronizado;

  /// Crea una copia de este Hallazgo con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  Hallazgo copyWith({
    String? id,
    String? tipo,
    double? latitud,
    double? longitud,
    double? precisionGps,
    double? confianza,
    DateTime? timestamp,
    String? imagenPath,
    bool? sincronizado,
  }) {
    return Hallazgo(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      precisionGps: precisionGps ?? this.precisionGps,
      confianza: confianza ?? this.confianza,
      timestamp: timestamp ?? this.timestamp,
      imagenPath: imagenPath ?? this.imagenPath,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Crea una copia marcando el hallazgo como sincronizado
  Hallazgo marcarComoSincronizado() {
    return copyWith(sincronizado: true);
  }

  @override
  List<Object> get props => [
        id,
        tipo,
        latitud,
        longitud,
        precisionGps,
        confianza,
        timestamp,
        imagenPath,
        sincronizado,
      ];

  @override
  String toString() =>
      'Hallazgo(id: $id, tipo: $tipo, lat: $latitud, lon: $longitud, confianza: $confianza, sincronizado: $sincronizado)';
}

