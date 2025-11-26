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
    show confidenceThreshold, nmsPerClassThreshold, maxDetectionsPerFrame;
import '../utils/nms_utils.dart' show applyNMSPerClass;

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
  const DetectionRepositoryImpl(this.datasource);

  @override
  Future<void> loadModel(String modelPath) async {
    try {
      await datasource.loadModel(modelPath);
    } on ModelInferenceException {
      rethrow;
    } on Exception catch (e) {
      throw ModelInferenceException(
        'Error al cargar el modelo: ${e.toString()}',
      );
    } catch (e) {
      throw ModelInferenceException(
        'Error inesperado al cargar el modelo: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<DetectionResult>> runInference(
    Uint8List imageBytes, {
    int? width,
    int? height,
  }) async {
    // Validar que el modelo está cargado
    if (!datasource.isModelLoaded) {
      throw const ModelInferenceException('Modelo no cargado');
    }

    try {
      // Obtener dimensiones de la imagen
      // Si no se proporcionan, estimarlas desde el tamaño de bytes
      int imageWidth;
      int imageHeight;
      
      if (width != null && height != null) {
        imageWidth = width;
        imageHeight = height;
      } else {
        final estimatedSize = _estimateImageSize(imageBytes);
        imageWidth = estimatedSize['width']!;
        imageHeight = estimatedSize['height']!;
      }
      
      // Ejecutar inferencia via datasource
      final tfliteOutput = await datasource.runInference(
        imageBytes,
        imageWidth,
        imageHeight,
      );

      // Post-procesamiento: parsear tensor de salida
      final timestamp = DateTime.now();
      final allDetections = DetectionResultModel.fromTfliteOutputBatch(
        tfliteOutput: tfliteOutput,
        timestamp: timestamp,
        confidenceThresholdValue: confidenceThreshold,
      );

      // Aplicar NMS por clase para mejor filtrado
      // Esto agrupa por clase, aplica NMS más estricto, y limita detecciones
      final filteredDetections = applyNMSPerClass(
        allDetections,
        iouThreshold: nmsPerClassThreshold,
        maxDetections: maxDetectionsPerFrame,
      );

      return filteredDetections;
    } on ModelInferenceException {
      rethrow;
    } on ArgumentError catch (e) {
      throw ModelInferenceException(
        'Error en post-procesamiento: ${e.toString()}',
      );
    } on Exception catch (e) {
      throw ModelInferenceException(
        'Error durante la inferencia: ${e.toString()}',
      );
    } catch (e) {
      throw ModelInferenceException(
        'Error inesperado durante la inferencia: ${e.toString()}',
      );
    }
  }

  /// Estima las dimensiones de la imagen desde el tamaño de bytes
  /// 
  /// Para frames de cámara YUV420 (plano Y), el tamaño es width * height.
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
    
    // Calcular desde el tamaño de bytes
    if (size > 0) {
      final estimatedSize = (size * 0.75).round();
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
