/// Excepciones personalizadas de la aplicación
/// 
/// Define excepciones estructuradas para diferentes capas y operaciones
/// del sistema. Cada excepción incluye un mensaje descriptivo para facilitar
/// el debugging y el manejo de errores.
library;

/// Excepción base para errores del servidor o servicios externos
class ServerException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Código de estado HTTP (opcional)
  final int? statusCode;

  /// Constructor de ServerException
  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Excepción para errores de caché o almacenamiento local
class CacheException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Constructor de CacheException
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción para errores relacionados con la cámara
class CameraException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Código de error específico de la cámara (opcional)
  final String? errorCode;

  /// Constructor de CameraException
  const CameraException(this.message, {this.errorCode});

  @override
  String toString() => 'CameraException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}

/// Excepción para errores durante la inferencia del modelo
class ModelInferenceException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Constructor de ModelInferenceException
  const ModelInferenceException(this.message);

  @override
  String toString() => 'ModelInferenceException: $message';
}

/// Excepción para errores relacionados con la ubicación GPS
class LocationException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Código de error específico de ubicación (opcional)
  final String? errorCode;

  /// Constructor de LocationException
  const LocationException(this.message, {this.errorCode});

  @override
  String toString() => 'LocationException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}

/// Excepción para cuando se deniega un permiso
class PermissionDeniedException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Tipo de permiso denegado
  final String permissionType;

  /// Constructor de PermissionDeniedException
  const PermissionDeniedException(this.message, this.permissionType);

  @override
  String toString() => 'PermissionDeniedException: $message (Permission: $permissionType)';
}

