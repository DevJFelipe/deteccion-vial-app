/// DataSource abstracto para acceso a inferencia con TFLite
/// 
/// Define la interfaz para cargar modelos TFLite y ejecutar inferencias
/// sobre imágenes. La implementación concreta se encuentra en TfliteDatasourceImpl.
library;

import 'dart:typed_data';

/// DataSource abstracto para operaciones con TensorFlow Lite
/// 
/// Este datasource define las operaciones necesarias para:
/// - Cargar modelos TFLite desde assets
/// - Ejecutar inferencias sobre frames de imagen
/// - Obtener información sobre el modelo (tamaño de entrada, estado)
/// - Liberar recursos del modelo
/// 
/// Responsabilidades del datasource:
/// - Preprocesamiento: redimensionar a tamaño esperado, normalizar valores
/// - Inferencia: ejecutar modelo TFLite sobre imagen preprocesada
/// 
/// NO es responsable de:
/// - Post-procesamiento (NMS, filtrado por confianza) - eso es responsabilidad del repository
/// - Conversión a entidades del dominio - eso es responsabilidad del repository
abstract class TfliteDatasource {
  /// Carga el modelo TensorFlow Lite desde la ruta especificada
  /// 
  /// [modelPath] - Ruta del archivo del modelo (.tflite) en assets
  /// 
  /// Ejemplo:
  /// ```dart
  /// await datasource.loadModel('assets/models/yolov8s_int8.tflite');
  /// ```
  /// 
  /// Lanza [ModelInferenceException] si:
  /// - El archivo del modelo no existe
  /// - El modelo no se puede cargar
  /// - Hay un error al inicializar el intérprete TFLite
  Future<void> loadModel(String modelPath);

  /// Ejecuta una inferencia sobre una imagen
  /// 
  /// [imageBytes] - Bytes de la imagen a procesar (formato YUV420 o RGB)
  /// [width] - Ancho de la imagen en píxeles
  /// [height] - Alto de la imagen en píxeles
  /// 
  /// Retorna la salida raw del modelo TFLite como List de dynamic.
  /// La salida típicamente tiene forma [1, 84, 8400] o [84, 8400]
  /// para modelos YOLOv8.
  /// 
  /// El datasource es responsable de:
  /// - Preprocesar la imagen (redimensionar a 640×640, normalizar)
  /// - Ejecutar la inferencia
  /// - Retornar el tensor de salida sin procesar
  /// 
  /// NO es responsable de:
  /// - Post-procesamiento (NMS, filtrado)
  /// - Conversión a entidades del dominio
  /// 
  /// Ejemplo:
  /// ```dart
  /// final output = await datasource.runInference(imageBytes, 640, 480);
  /// // output es List<dynamic> con forma [1, 84, 8400]
  /// ```
  /// 
  /// Lanza [ModelInferenceException] si:
  /// - El modelo no está cargado
  /// - Los bytes de la imagen son inválidos
  /// - La inferencia falla
  /// - Hay un error durante el preprocesamiento
  Future<List<dynamic>> runInference(
    Uint8List imageBytes,
    int width,
    int height,
  );

  /// Obtiene el tamaño de entrada esperado por el modelo
  /// 
  /// Retorna el tamaño de entrada en píxeles (típicamente 640 para YOLOv8).
  /// 
  /// Ejemplo:
  /// ```dart
  /// final inputSize = datasource.getModelInputSize(); // 640
  /// ```
  int getModelInputSize();

  /// Verifica si el modelo está cargado
  /// 
  /// Retorna `true` si el modelo está cargado y listo para inferencias,
  /// `false` en caso contrario.
  /// 
  /// Ejemplo:
  /// ```dart
  /// if (datasource.isModelLoaded) {
  ///   await datasource.runInference(imageBytes, width, height);
  /// }
  /// ```
  bool get isModelLoaded;

  /// Libera los recursos del modelo
  /// 
  /// Cierra el intérprete TFLite y libera la memoria asignada.
  /// Debe ser llamado cuando el modelo ya no se necesite.
  /// 
  /// Ejemplo:
  /// ```dart
  /// await datasource.dispose();
  /// ```
  /// 
  /// Lanza [ModelInferenceException] si hay un error al liberar recursos.
  Future<void> dispose();
}

