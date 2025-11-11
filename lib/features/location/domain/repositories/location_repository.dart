/// Repositorio abstracto para el manejo de ubicación GPS
/// 
/// Define el contrato para obtener la ubicación actual y un stream
/// de actualizaciones de ubicación. La implementación concreta se
/// encuentra en la capa de datos.
library;

import '../entities/geoposition.dart';

/// Repositorio abstracto para operaciones de ubicación
/// 
/// Este repositorio define las operaciones necesarias para:
/// - Verificar permisos de ubicación
/// - Obtener la ubicación actual
/// - Obtener un stream de actualizaciones de ubicación
abstract class LocationRepository {
  /// Verifica si la aplicación tiene permiso para acceder a la ubicación
  /// 
  /// Retorna `true` si el permiso está concedido, `false` en caso contrario.
  /// 
  /// Ejemplo:
  /// ```dart
  /// if (await repository.hasPermission()) {
  ///   final position = await repository.getCurrentLocation();
  /// }
  /// ```
  Future<bool> hasPermission();

  /// Obtiene la ubicación actual del dispositivo
  /// 
  /// Retorna un [Geoposition] con la ubicación actual.
  /// 
  /// Lanza [LocationException] si:
  /// - No hay permisos de ubicación
  /// - El GPS no está disponible
  /// - No se puede obtener la ubicación
  /// 
  /// Ejemplo:
  /// ```dart
  /// final position = await repository.getCurrentLocation();
  /// print('Latitud: ${position.latitude}, Longitud: ${position.longitude}');
  /// ```
  Future<Geoposition> getCurrentLocation();

  /// Obtiene un stream de actualizaciones de ubicación
  /// 
  /// Retorna un stream que emite [Geoposition] cada vez que
  /// se actualiza la ubicación del dispositivo.
  /// 
  /// [distanceFilter] - Distancia mínima en metros para emitir una actualización (opcional)
  /// [timeInterval] - Intervalo mínimo en segundos entre actualizaciones (opcional)
  /// 
  /// Lanza [LocationException] si:
  /// - No hay permisos de ubicación
  /// - El GPS no está disponible
  /// 
  /// Ejemplo:
  /// ```dart
  /// final stream = repository.getLocationStream(
  ///   distanceFilter: 10.0, // Emitir cada 10 metros
  /// );
  /// stream.listen((position) {
  ///   print('Nueva ubicación: ${position.latitude}, ${position.longitude}');
  /// });
  /// ```
  Stream<Geoposition> getLocationStream({
    double? distanceFilter,
    int? timeInterval,
  });
}

