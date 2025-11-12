/// Interfaz abstracta para acceso al hardware de cámara
/// 
/// Define el contrato que deben implementar las fuentes de datos
/// para interactuar con el hardware de cámara del dispositivo.
/// La implementación concreta se encuentra en [CameraDataSourceImpl].
library;

import 'package:camera/camera.dart' as camera_package;

/// Interfaz abstracta para operaciones de acceso a la cámara
/// 
/// Esta interfaz define los métodos necesarios para:
/// - Inicializar y configurar la cámara
/// - Obtener un stream continuo de frames
/// - Gestionar permisos de cámara
/// - Liberar recursos del hardware
/// 
/// La implementación concreta debe usar el plugin camera de Flutter
/// para interactuar con el hardware nativo.
abstract class CameraDataSource {
  /// Inicializa la cámara y la configura para captura de video
  /// 
  /// Configura la cámara con los parámetros especificados:
  /// - Selecciona la cámara trasera por defecto
  /// - Establece resolución media (640×480 mínimo)
  /// - Configura formato YUV420 para streams de video
  /// 
  /// Debe ser llamado antes de usar cualquier otro método.
  /// 
  /// Lanza excepciones si:
  /// - No hay cámaras disponibles en el dispositivo
  /// - La inicialización falla
  /// - No hay permisos de cámara
  /// 
  /// Ejemplo:
  /// ```dart
  /// await dataSource.initialize();
  /// ```
  Future<void> initialize();

  /// Obtiene un stream continuo de frames de la cámara
  /// 
  /// Retorna un [Stream<CameraImage>] que emite frames a medida
  /// que se capturan del hardware. El stream se detiene cuando
  /// se llama a [dispose()].
  /// 
  /// La cámara debe estar inicializada antes de llamar este método.
  /// 
  /// Retorna un stream broadcast que permite múltiples listeners.
  /// 
  /// Lanza excepciones si:
  /// - La cámara no está inicializada
  /// - No se puede iniciar el stream de imágenes
  /// 
  /// Ejemplo:
  /// ```dart
  /// final stream = dataSource.getImageStream();
  /// stream.listen((image) {
  ///   // Procesar frame
  /// });
  /// ```
  Stream<camera_package.CameraImage> getImageStream();

  /// Verifica si la aplicación tiene permiso para usar la cámara
  /// 
  /// Retorna `true` si el permiso está concedido, `false` en caso contrario.
  /// 
  /// Este método no solicita el permiso, solo verifica el estado actual.
  /// 
  /// Ejemplo:
  /// ```dart
  /// if (await dataSource.hasPermission()) {
  ///   await dataSource.initialize();
  /// } else {
  ///   await dataSource.requestPermission();
  /// }
  /// ```
  Future<bool> hasPermission();

  /// Solicita permiso de cámara al sistema operativo
  /// 
  /// Muestra el diálogo del sistema para solicitar permiso de cámara
  /// al usuario. El usuario puede conceder o denegar el permiso.
  /// 
  /// Retorna `true` si el permiso fue concedido, `false` si fue denegado.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final granted = await dataSource.requestPermission();
  /// if (granted) {
  ///   await dataSource.initialize();
  /// }
  /// ```
  Future<bool> requestPermission();

  /// Libera todos los recursos de la cámara
  /// 
  /// Detiene el stream de imágenes si está activo y libera
  /// los recursos del hardware. Debe ser llamado cuando la cámara
  /// ya no se necesite.
  /// 
  /// **Orden crítico**: Debe detener el stream antes de liberar
  /// el controlador de cámara.
  /// 
  /// Ejemplo:
  /// ```dart
  /// await dataSource.dispose();
  /// ```
  Future<void> dispose();

  /// Indica si la cámara está inicializada y lista para usar
  /// 
  /// Retorna `true` si [initialize()] fue llamado exitosamente
  /// y la cámara está lista para capturar frames.
  /// 
  /// Ejemplo:
  /// ```dart
  /// if (dataSource.isInitialized) {
  ///   final stream = dataSource.getImageStream();
  /// }
  /// ```
  bool get isInitialized;

  /// Obtiene el controlador de cámara para preview nativo
  /// 
  /// Retorna el [CameraController] inicializado para usar con
  /// el widget [CameraPreview] nativo del plugin camera.
  /// Este método permite acceso directo al controller para
  /// visualización optimizada sin conversión de frames.
  /// 
  /// **Uso**: Solo para visualización con CameraPreview nativo.
  /// El stream de frames se usa para procesamiento ML.
  /// 
  /// Lanza excepciones si:
  /// - La cámara no está inicializada
  /// 
  /// Ejemplo:
  /// ```dart
  /// final controller = dataSource.controller;
  /// return CameraPreview(controller);
  /// ```
  camera_package.CameraController? get controller;
}

