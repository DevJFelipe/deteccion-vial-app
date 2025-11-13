/// Implementación concreta del repositorio de detección
/// 
/// Implementa la interfaz [DetectionRepository] del domain layer usando
/// el datasource TFLite. Orquesta el pipeline completo:
/// preprocesamiento → inferencia → post-procesamiento NMS → conversión a entidades.
library;

import 'dart:typed_data';
import 'dart:math' as math;
import '../../domain/entities/detection_result.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/tflite_datasource.dart';
import '../models/detection_result_model.dart';
import '../models/detection_constants.dart'
    show confidenceThreshold, nmsThreshold;
import '../utils/nms_utils.dart' show applyNMS;

/// Implementación concreta de [DetectionRepository]
/// 
/// Este repositorio actúa como intermediario entre la capa de dominio
/// y la capa de datos, orquestando:
/// - Preprocesamiento de imágenes
/// - Inferencia del modelo TFLite
/// - Post-procesamiento (NMS, filtrado por confianza)
/// - Conversión a entidades del dominio
/// 
/// Mantiene la separación de responsabilidades:
/// - Domain layer: no conoce detalles de implementación (TFLite, NMS)
/// - Data layer: no expone modelos internos al domain
/// - Repository: orquesta el pipeline completo
class DetectionRepositoryImpl implements DetectionRepository {
  /// DataSource TFLite inyectado por dependencia
  final TfliteDatasource datasource;

  /// Constructor del repositorio
  /// 
  /// [datasource] - DataSource TFLite a utilizar (inyección de dependencias)
  /// 
  /// Ejemplo:
  /// ```dart
  /// final datasource = TfliteDatasourceImpl();
  /// final repository = DetectionRepositoryImpl(datasource);
  /// ```
  const DetectionRepositoryImpl(this.datasource);

  @override
  Future<void> loadModel(String modelPath) async {
    try {
      await datasource.loadModel(modelPath);
    } on ModelInferenceException {
      // Re-lanzar ModelInferenceException sin modificar
      rethrow;
    } on Exception catch (e) {
      // Transformar excepciones genéricas a ModelInferenceException
      throw ModelInferenceException(
        'Error al cargar el modelo: ${e.toString()}',
      );
    } catch (e) {
      // Capturar cualquier otro error
      throw ModelInferenceException(
        'Error inesperado al cargar el modelo: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<DetectionResult>> runInference(Uint8List imageBytes) async {
    // Validar que el modelo está cargado
    if (!datasource.isModelLoaded) {
      throw const ModelInferenceException('Modelo no cargado');
    }

    try {
      // 1. Preprocesamiento e inferencia
      // El datasource se encarga de preprocesar la imagen y ejecutar la inferencia
      // Necesitamos pasar las dimensiones de la imagen
      // Asumimos que imageBytes contiene una imagen de tamaño conocido
      // Para frames de cámara, típicamente son 640×480 o 1280×720
      
      // Obtener dimensiones de la imagen
      // Si imageBytes viene del CameraFrame, necesitamos las dimensiones
      // Por ahora, asumimos que es necesario pasar las dimensiones
      // Esto debería venir del CameraFrame entity
      
      // Ejecutar inferencia
      // Nota: El datasource espera (imageBytes, width, height)
      // Para frames de cámara, necesitamos las dimensiones reales
      // Por ahora, asumimos que imageBytes viene con dimensiones conocidas
      // o que necesitamos estimarlas desde el tamaño de los bytes
      
      // Estimación de dimensiones desde el tamaño de bytes
      // Si es YUV420 plano Y: size = width * height
      // Si es RGB: size = width * height * 3
      // Para simplificar, asumimos que es plano Y y estimamos dimensiones
      final estimatedSize = _estimateImageSize(imageBytes);
      final width = estimatedSize['width']!;
      final height = estimatedSize['height']!;
      
      // Ejecutar inferencia via datasource
      final tfliteOutput = await datasource.runInference(
        imageBytes,
        width,
        height,
      );

      // 2. Post-procesamiento: parsear tensor de salida
      final timestamp = DateTime.now();
      final allDetections = DetectionResultModel.fromTfliteOutputBatch(
        tfliteOutput: tfliteOutput,
        timestamp: timestamp,
        confidenceThresholdValue: confidenceThreshold,
      );

      // 3. Aplicar NMS para filtrar detecciones superpuestas
      final filteredDetections = applyNMS(
        allDetections,
        iouThreshold: nmsThreshold,
      );

      // 4. Convertir a entidades del dominio
      // DetectionResultModel extiende DetectionResult, así que ya son entidades
      // Solo necesitamos retornarlas directamente
      return filteredDetections;
    } on ModelInferenceException {
      // Re-lanzar ModelInferenceException sin modificar
      rethrow;
    } on ArgumentError catch (e) {
      // Transformar ArgumentError a ModelInferenceException
      throw ModelInferenceException(
        'Error en post-procesamiento: ${e.toString()}',
      );
    } on Exception catch (e) {
      // Transformar excepciones genéricas a ModelInferenceException
      throw ModelInferenceException(
        'Error durante la inferencia: ${e.toString()}',
      );
    } catch (e) {
      // Capturar cualquier otro error
      throw ModelInferenceException(
        'Error inesperado durante la inferencia: ${e.toString()}',
      );
    }
  }

  /// Estima las dimensiones de la imagen desde el tamaño de bytes
  /// 
  /// [imageBytes] - Bytes de la imagen
  /// 
  /// Retorna un mapa con 'width' y 'height' estimados.
  /// 
  /// Para frames de cámara YUV420 (plano Y), el tamaño es width * height.
  /// Asumimos dimensiones comunes de cámara (640×480, 1280×720, etc.).
  Map<String, int> _estimateImageSize(Uint8List imageBytes) {
    final size = imageBytes.length;
    
    // Dimensiones comunes de cámara
    final commonSizes = [
      {'width': 640, 'height': 480},   // 307,200 bytes (Y plane)
      {'width': 1280, 'height': 720},  // 921,600 bytes (Y plane)
      {'width': 1920, 'height': 1080}, // 2,073,600 bytes (Y plane)
    ];
    
    // Buscar el tamaño más cercano
    for (final dimensions in commonSizes) {
      final expectedSize = dimensions['width']! * dimensions['height']!;
      if (size == expectedSize) {
        return dimensions;
      }
    }
    
    // Si no coincide exactamente, asumir 640×480 por defecto
    // o calcular desde el tamaño de bytes (raíz cuadrada aproximada)
    if (size > 0) {
      final estimatedSize = (size * 0.75).round(); // Aproximación para Y plane
      final estimatedDimension = math.sqrt(estimatedSize).round();
      return {
        'width': estimatedDimension,
        'height': estimatedDimension,
      };
    }
    
    // Por defecto, usar tamaño del modelo
    final inputSize = datasource.getModelInputSize();
    return {
      'width': inputSize,
      'height': inputSize,
    };
  }
}

