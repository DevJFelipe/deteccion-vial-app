/// Entidad que representa un marcador en el mapa
/// 
/// Contiene la información necesaria para mostrar un marcador
/// en Google Maps, incluyendo coordenadas, tipo de anomalía,
/// confianza y timestamp.
library;

import 'package:equatable/equatable.dart';

/// Representa un marcador en el mapa para visualizar hallazgos
/// 
/// Esta entidad es inmutable y contiene toda la información necesaria
/// para mostrar un marcador en Google Maps, incluyendo:
/// - Identificador único
/// - Coordenadas GPS (latitud, longitud)
/// - Tipo de anomalía ('hueco' o 'grieta')
/// - Nivel de confianza de la detección
/// - Timestamp de cuando se detectó
class MapMarker extends Equatable {
  /// Identificador único del marcador
  final String id;

  /// Latitud de la ubicación del marcador
  final double latitud;

  /// Longitud de la ubicación del marcador
  final double longitud;

  /// Tipo de anomalía: 'hueco' o 'grieta'
  final String tipo;

  /// Nivel de confianza de la detección (0.0 a 1.0)
  final double confianza;

  /// Timestamp de cuando se detectó la anomalía
  final DateTime timestamp;

  /// Constructor de MapMarker
  /// 
  /// [id] - Identificador único del marcador
  /// [latitud] - Latitud en grados decimales
  /// [longitud] - Longitud en grados decimales
  /// [tipo] - Tipo de anomalía ('hueco' o 'grieta')
  /// [confianza] - Nivel de confianza (0.0 a 1.0)
  /// [timestamp] - Timestamp de la detección
  /// 
  /// Lanza [ArgumentError] si los parámetros son inválidos
  MapMarker({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.tipo,
    required this.confianza,
    required this.timestamp,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('El ID no puede estar vacío');
    }
    if (latitud < -90.0 || latitud > 90.0) {
      throw ArgumentError('La latitud debe estar entre -90.0 y 90.0');
    }
    if (longitud < -180.0 || longitud > 180.0) {
      throw ArgumentError('La longitud debe estar entre -180.0 y 180.0');
    }
    if (tipo != 'hueco' && tipo != 'grieta') {
      throw ArgumentError('El tipo debe ser "hueco" o "grieta"');
    }
    if (confianza < 0.0 || confianza > 1.0) {
      throw ArgumentError('La confianza debe estar entre 0.0 y 1.0');
    }
  }

  /// Verifica si el marcador es de tipo 'hueco'
  bool get isHueco => tipo == 'hueco';

  /// Verifica si el marcador es de tipo 'grieta'
  bool get isGrieta => tipo == 'grieta';

  /// Obtiene el color del marcador según el tipo
  /// 
  /// Retorna un color en formato hexadecimal:
  /// - '#FF0000' para huecos (rojo)
  /// - '#FF8800' para grietas (naranja)
  String get color {
    switch (tipo) {
      case 'hueco':
        return '#FF0000';
      case 'grieta':
        return '#FF8800';
      default:
        return '#2196F3';
    }
  }

  /// Crea una copia de este MapMarker con valores modificados
  /// 
  /// Permite crear una nueva instancia con algunos valores cambiados
  /// manteniendo la inmutabilidad de la entidad.
  MapMarker copyWith({
    String? id,
    double? latitud,
    double? longitud,
    String? tipo,
    double? confianza,
    DateTime? timestamp,
  }) {
    return MapMarker(
      id: id ?? this.id,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      tipo: tipo ?? this.tipo,
      confianza: confianza ?? this.confianza,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object> get props => [id, latitud, longitud, tipo, confianza, timestamp];

  @override
  String toString() =>
      'MapMarker(id: $id, tipo: $tipo, lat: $latitud, lon: $longitud, confianza: $confianza, timestamp: $timestamp)';
}

