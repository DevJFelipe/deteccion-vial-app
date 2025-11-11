/// Failures para el manejo de errores en la capa de dominio
/// 
/// Las failures son objetos inmutables que representan errores de negocio.
/// Heredan de Equatable para permitir comparaciones y facilitar testing.
/// Cada failure corresponde a una excepción específica de la capa de datos.
library;

import 'package:equatable/equatable.dart';

/// Clase abstracta base para todos los failures
/// 
/// Todas las failures deben heredar de esta clase e implementar
/// la propiedad [props] para comparaciones con Equatable.
abstract class Failure extends Equatable {
  /// Mensaje descriptivo del error
  final String message;

  /// Constructor de Failure
  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

/// Failure para errores del servidor o servicios externos
class ServerFailure extends Failure {
  /// Código de estado HTTP (opcional)
  final int? statusCode;

  /// Constructor de ServerFailure
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

/// Failure para errores de caché o almacenamiento local
class CacheFailure extends Failure {
  /// Constructor de CacheFailure
  const CacheFailure(super.message);
}

/// Failure para errores relacionados con la cámara
class CameraFailure extends Failure {
  /// Código de error específico de la cámara (opcional)
  final String? errorCode;

  /// Constructor de CameraFailure
  const CameraFailure(super.message, {this.errorCode});

  @override
  List<Object> get props => [message, errorCode ?? ''];
}

/// Failure para errores durante la inferencia del modelo
class ModelFailure extends Failure {
  /// Constructor de ModelFailure
  const ModelFailure(super.message);
}

/// Failure para errores relacionados con la ubicación GPS
class LocationFailure extends Failure {
  /// Código de error específico de ubicación (opcional)
  final String? errorCode;

  /// Constructor de LocationFailure
  const LocationFailure(super.message, {this.errorCode});

  @override
  List<Object> get props => [message, errorCode ?? ''];
}

/// Failure para cuando se deniega un permiso
class PermissionFailure extends Failure {
  /// Tipo de permiso denegado
  final String permissionType;

  /// Constructor de PermissionFailure
  const PermissionFailure(super.message, this.permissionType);

  @override
  List<Object> get props => [message, permissionType];
}

