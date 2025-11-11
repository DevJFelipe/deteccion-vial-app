/// Utilidades para el manejo de permisos de la aplicación
/// 
/// Proporciona funciones para solicitar y verificar permisos de cámara
/// y ubicación, esenciales para el funcionamiento de la aplicación.
library;

import 'package:permission_handler/permission_handler.dart';

/// Tipo de permiso soportado por la aplicación
enum AppPermissionType {
  /// Permiso de cámara
  camera,
  /// Permiso de ubicación
  location,
}

/// Solicita el permiso de cámara al usuario
/// 
/// Retorna `true` si el permiso fue concedido, `false` en caso contrario.
/// 
/// Ejemplo:
/// ```dart
/// final hasPermission = await requestCameraPermission();
/// if (hasPermission) {
///   // Inicializar cámara
/// }
/// ```
Future<bool> requestCameraPermission() async {
  try {
    final status = await Permission.camera.request();
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

/// Solicita el permiso de ubicación al usuario
/// 
/// Retorna `true` si el permiso fue concedido, `false` en caso contrario.
/// 
/// Ejemplo:
/// ```dart
/// final hasPermission = await requestLocationPermission();
/// if (hasPermission) {
///   // Obtener ubicación
/// }
/// ```
Future<bool> requestLocationPermission() async {
  try {
    final status = await Permission.location.request();
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

/// Verifica si el permiso de cámara está concedido
/// 
/// Retorna `true` si el permiso está concedido, `false` en caso contrario.
/// No solicita el permiso, solo verifica el estado actual.
Future<bool> hasCameraPermission() async {
  try {
    final status = await Permission.camera.status;
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

/// Verifica si el permiso de ubicación está concedido
/// 
/// Retorna `true` si el permiso está concedido, `false` en caso contrario.
/// No solicita el permiso, solo verifica el estado actual.
Future<bool> hasLocationPermission() async {
  try {
    final status = await Permission.location.status;
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

/// Verifica el estado de un permiso específico
/// 
/// [permissionType] - Tipo de permiso a verificar
/// 
/// Retorna `true` si el permiso está concedido, `false` en caso contrario.
Future<bool> checkPermissionStatus(AppPermissionType permissionType) async {
  try {
    Permission permission;
    switch (permissionType) {
      case AppPermissionType.camera:
        permission = Permission.camera;
        break;
      case AppPermissionType.location:
        permission = Permission.location;
        break;
    }
    final status = await permission.status;
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

/// Solicita un permiso específico
/// 
/// [permissionType] - Tipo de permiso a solicitar
/// 
/// Retorna `true` si el permiso fue concedido, `false` en caso contrario.
Future<bool> requestPermission(AppPermissionType permissionType) async {
  try {
    Permission permission;
    switch (permissionType) {
      case AppPermissionType.camera:
        permission = Permission.camera;
        break;
      case AppPermissionType.location:
        permission = Permission.location;
        break;
    }
    final status = await permission.request();
    return status.isGranted;
  } catch (e) {
    return false;
  }
}

