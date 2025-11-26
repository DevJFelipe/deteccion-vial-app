/// Repositorio abstracto para el manejo de detecciones
/// 
/// Define el contrato para cargar el modelo de detección y ejecutar
/// inferencias sobre imágenes. La implementación concreta se encuentra
/// en la capa de datos.
library;

import 'dart:typed_data';
import '../entities/detection_result.dart';

/// Repositorio abstracto para operaciones de detección
/// 
/// Este repositorio define las operaciones necesarias para:
/// - Cargar el modelo TensorFlow Lite
/// - Ejecutar inferencias sobre imágenes
abstract class DetectionRepository {
  /// Carga el modelo TensorFlow Lite desde la ruta especificada
  /// 
  /// [modelPath] - Ruta del archivo del modelo (.tflite)
  /// 
  /// Lanza [ModelInferenceException] si:
  /// - El archivo del modelo no existe
  /// - El modelo no se puede cargar
  /// - Hay un error al inicializar el intérprete
  /// 
  /// Ejemplo:
  /// ```dart
  /// await repository.loadModel('models/yolov8s_int8.tflite');
  /// ```
  Future<void> loadModel(String modelPath);

  /// Ejecuta una inferencia sobre una imagen
  /// 
  /// [imageBytes] - Bytes de la imagen a procesar (formato YUV420 plano Y o RGB)
  /// [width] - Ancho de la imagen en píxeles (opcional, se estima si no se proporciona)
  /// [height] - Alto de la imagen en píxeles (opcional, se estima si no se proporciona)
  /// 
  /// Retorna una lista de [DetectionResult] con todas las detecciones
  /// encontradas en la imagen que superen el umbral de confianza.
  /// 
  /// Lanza [ModelInferenceException] si:
  /// - El modelo no está cargado
  /// - Los bytes de la imagen son inválidos
  /// - La inferencia falla
  /// 
  /// Ejemplo:
  /// ```dart
  /// final results = await repository.runInference(imageBytes, 640, 480);
  /// for (final result in results) {
  ///   print('Detectado: ${result.type} con confianza ${result.confidence}');
  /// }
  /// ```
  Future<List<DetectionResult>> runInference(
    Uint8List imageBytes, {
    int? width,
    int? height,
  });
}
