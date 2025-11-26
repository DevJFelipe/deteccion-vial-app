/// Modelo de datos para DetectionResult
/// 
/// Extiende la entidad DetectionResult del domain layer y proporciona
/// métodos para convertir la salida del modelo TFLite a entidades del dominio.
/// 
/// IMPORTANTE: Este modelo está configurado para un YOLOv8 fine-tuned con 2 clases.
library;

import 'dart:math' as math;
import '../../domain/entities/detection_result.dart';
import '../../domain/entities/bounding_box.dart';
import 'bounding_box_model.dart';
import 'detection_constants.dart'
    show
        bboxXIndex,
        bboxYIndex,
        bboxWidthIndex,
        bboxHeightIndex,
        classScoresStartIndex,
        numClasses,
        modelOutputValuesPerDetection,
        modelOutputNumDetections,
        modelInputSize,
        classIndexToName,
        projectClasses,
        confidenceThreshold,
        minBboxArea,
        maxBboxArea,
        minBboxDimension,
        maxBboxDimension,
        minAspectRatio,
        maxAspectRatio;

/// Modelo de datos para DetectionResult
/// 
/// Extiende la entidad [DetectionResult] del domain layer y proporciona
/// métodos para procesar la salida del modelo TFLite y convertirla a
/// entidades del dominio.
/// 
/// Este modelo se usa en la capa de datos para convertir resultados
/// del modelo TFLite (tensor [1, 6, 8400]) a entidades [DetectionResult].
/// 
/// Formato de salida YOLOv8 (2 clases):
/// - Tensor shape: [1, 6, 8400]
/// - Cada detección: [x_center, y_center, width, height, class0_score, class1_score]
class DetectionResultModel extends DetectionResult {
  /// Constructor de DetectionResultModel
  const DetectionResultModel({
    required super.type,
    required super.confidence,
    required super.boundingBox,
    required super.timestamp,
  });

  /// Desenvuelve un tensor anidado hasta llegar a la forma [6, 8400]
  /// 
  /// El tensor puede venir en diferentes niveles de anidamiento:
  /// - [outputBuffer] donde outputBuffer = [1, 6, 8400]
  /// - [[batch]] donde batch = [6, 8400]
  /// 
  /// Esta función desenvuelve hasta encontrar la estructura [6, 8400]
  static List<dynamic> _unwrapTensor(List<dynamic> tensor) {
    List<dynamic> current = tensor;
    
    // Desenvolver mientras el primer elemento sea una lista y haya solo un elemento
    // o mientras la estructura no sea [6, 8400]
    while (current.isNotEmpty) {
      // Si el primer elemento no es lista, ya llegamos al nivel correcto
      if (current[0] is! List) {
        break;
      }
      
      final firstList = current[0] as List;
      
      // Verificar si esta es la forma [6, 8400]
      // La forma correcta es: current.length == 6 y firstList.length == 8400
      if (current.length == modelOutputValuesPerDetection && 
          firstList.length >= modelOutputNumDetections) {
        // Esta es la forma correcta [6, 8400]
        break;
      }
      
      // Si solo hay un elemento, desenvolver
      if (current.length == 1) {
        current = firstList;
        continue;
      }
      
      // Si hay más elementos, verificar si es [8400, 6]
      if (current.length >= modelOutputNumDetections &&
          firstList.length == modelOutputValuesPerDetection) {
        // Esta es la forma transpuesta [8400, 6], retornar como está
        break;
      }
      
      // Si no coincide con ningún formato esperado, intentar desenvolver
      if (current.length < modelOutputValuesPerDetection) {
        current = firstList;
        continue;
      }
      
      break;
    }
    
    return current;
  }

  /// Crea un DetectionResultModel desde la salida del modelo TFLite
  factory DetectionResultModel.fromTfliteOutput({
    required List<dynamic> tfliteOutput,
    required int detectionIndex,
    required DateTime timestamp,
  }) {
    try {
      // Desenvolver el tensor hasta llegar a [6, 8400]
      final batch = _unwrapTensor(tfliteOutput);

      // Validar que el batch no esté vacío
      if (batch.isEmpty) {
        throw ArgumentError('El tensor de salida está vacío');
      }

      // Validar el índice de detección
      if (detectionIndex < 0 || detectionIndex >= modelOutputNumDetections) {
        throw ArgumentError(
          'El índice de detección debe estar entre 0 y ${modelOutputNumDetections - 1}, '
          'pero se recibió: $detectionIndex',
        );
      }

      // Extraer valores del tensor
      List<double> detectionValues;
      
      final firstElement = batch[0];
      
      if (firstElement is List) {
        final firstList = firstElement;
        
        if (firstList.length >= modelOutputNumDetections) {
          // Forma [6, 8400]: cada fila (value_index) contiene 8400 valores
          // Acceder a batch[value_index][detection_index]
          detectionValues = List<double>.generate(
            modelOutputValuesPerDetection,
            (valueIndex) {
              if (valueIndex < batch.length) {
                final valueList = batch[valueIndex];
                if (valueList is List && detectionIndex < valueList.length) {
                  return _toDouble(valueList[detectionIndex]);
                }
              }
              return 0.0;
            },
          );
        } else if (batch.length >= modelOutputNumDetections) {
          // Forma [8400, 6]: cada fila (detection_index) contiene 6 valores
          final detectionRow = batch[detectionIndex];
          if (detectionRow is List &&
              detectionRow.length >= modelOutputValuesPerDetection) {
            detectionValues = List<double>.generate(
              modelOutputValuesPerDetection,
              (valueIndex) => _toDouble(detectionRow[valueIndex]),
            );
          } else {
            throw ArgumentError('Formato de tensor no soportado');
          }
        } else {
          throw ArgumentError(
            'Formato de tensor no soportado. batch.length=${batch.length}, '
            'firstList.length=${firstList.length}',
          );
        }
      } else {
        throw ArgumentError(
          'Formato de tensor no soportado. Tipo: ${firstElement.runtimeType}',
        );
      }

      // Extraer coordenadas raw del bounding box
      var xRaw = detectionValues[bboxXIndex];
      var yRaw = detectionValues[bboxYIndex];
      var widthRaw = detectionValues[bboxWidthIndex];
      var heightRaw = detectionValues[bboxHeightIndex];

      // Detectar si las coordenadas están en píxeles o normalizadas
      final maxCoord = [xRaw, yRaw, widthRaw, heightRaw].reduce(math.max);
      final isPixelCoords = maxCoord > 1.5;

      double x, y, width, height;
      if (isPixelCoords) {
        // Coordenadas en píxeles: normalizar dividiendo por modelInputSize
        x = (xRaw / modelInputSize).clamp(0.0, 1.0);
        y = (yRaw / modelInputSize).clamp(0.0, 1.0);
        width = (widthRaw / modelInputSize).clamp(0.0, 1.0);
        height = (heightRaw / modelInputSize).clamp(0.0, 1.0);
      } else {
        // Ya están normalizadas
        x = xRaw.clamp(0.0, 1.0);
        y = yRaw.clamp(0.0, 1.0);
        width = widthRaw.clamp(0.0, 1.0);
        height = heightRaw.clamp(0.0, 1.0);
      }

      // Extraer scores de clases (2 clases: hueco, grieta)
      final classScores = List<double>.generate(
        numClasses,
        (classIndex) {
          final scoreIndex = classScoresStartIndex + classIndex;
          if (scoreIndex < detectionValues.length) {
            return detectionValues[scoreIndex];
          }
          return 0.0;
        },
      );

      // Calcular confianza: max(class_scores)
      // IMPORTANTE: Aplicar sigmoid SIEMPRE porque el modelo puede producir logits
      double maxClassScore = 0.0;
      int maxScoreIndex = 0;
      for (var i = 0; i < classScores.length; i++) {
        // Aplicar sigmoid siempre para convertir logits a probabilidades
        final score = _sigmoid(classScores[i]);
        if (score > maxClassScore) {
          maxClassScore = score;
          maxScoreIndex = i;
        }
      }
      final confidence = maxClassScore.clamp(0.0, 1.0);

      // Mapear índice de clase a nombre
      final detectionType = classIndexToName[maxScoreIndex] ?? projectClasses[0];

      // Crear bounding box
      final boundingBox = BoundingBoxModel.fromNormalized(
        x: x,
        y: y,
        width: width,
        height: height,
      );

      return DetectionResultModel(
        type: detectionType,
        confidence: confidence,
        boundingBox: boundingBox,
        timestamp: timestamp,
      );
    } catch (e) {
      throw ArgumentError('Error al procesar salida del modelo TFLite: $e');
    }
  }

  /// Función sigmoid para convertir logits a probabilidades
  static double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }

  /// Convierte un valor dinámico a double de forma segura
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return 0.0;
  }

  /// Valida que el tamaño del bounding box esté dentro de límites razonables
  /// 
  /// Filtra detecciones con:
  /// - Área muy pequeña (ruido) o muy grande (falsos positivos)
  /// - Dimensiones extremas (ancho/alto)
  /// - Aspect ratio inválido (proporciones no realistas)
  static bool _isValidBboxSize(BoundingBox bbox) {
    final width = bbox.width;
    final height = bbox.height;
    final area = width * height;

    // Filtrar por dimensiones mínimas
    if (width < minBboxDimension || height < minBboxDimension) {
      return false;
    }

    // Filtrar por dimensiones máximas
    if (width > maxBboxDimension || height > maxBboxDimension) {
      return false;
    }

    // Filtrar por área
    if (area < minBboxArea || area > maxBboxArea) {
      return false;
    }

    // Filtrar por aspect ratio (proporciones)
    // Los huecos y grietas tienen proporciones razonables
    final aspectRatio = width / height;
    if (aspectRatio < minAspectRatio || aspectRatio > maxAspectRatio) {
      return false;
    }

    return true;
  }

  /// Crea una lista de DetectionResultModel desde la salida completa del modelo TFLite
  static List<DetectionResultModel> fromTfliteOutputBatch({
    required List<dynamic> tfliteOutput,
    required DateTime timestamp,
    double confidenceThresholdValue = confidenceThreshold,
  }) {
    final detections = <DetectionResultModel>[];

    try {
      if (tfliteOutput.isEmpty) {
        return detections;
      }

      // Desenvolver el tensor hasta llegar a [6, 8400]
      final batch = _unwrapTensor(tfliteOutput);

      if (batch.isEmpty) {
        // ignore: avoid_print
        print('Error: batch vacío después de desenvolver tensor');
        return detections;
      }

      // Determinar número de detecciones según la estructura
      int numDetections = modelOutputNumDetections;
      final firstElement = batch[0];
      
      if (firstElement is List) {
        if (firstElement.length >= modelOutputNumDetections) {
          // Forma [6, 8400]
          numDetections = firstElement.length;
        } else if (batch.length >= modelOutputNumDetections) {
          // Forma [8400, 6]
          numDetections = batch.length;
        }
      }

      // Variables para debug
      double maxScoreFound = 0.0;
      int detectionsAboveThreshold = 0;
      int filteredBySize = 0;

      // Procesar cada detección
      for (var detectionIndex = 0; detectionIndex < numDetections; detectionIndex++) {
        try {
          final detection = DetectionResultModel.fromTfliteOutput(
            tfliteOutput: tfliteOutput,
            detectionIndex: detectionIndex,
            timestamp: timestamp,
          );

          if (detection.confidence > maxScoreFound) {
            maxScoreFound = detection.confidence;
          }

          // Filtrar por umbral de confianza
          if (detection.confidence >= confidenceThresholdValue) {
            detectionsAboveThreshold++;
            
            // Validar tamaño del bounding box
            if (_isValidBboxSize(detection.boundingBox)) {
              detections.add(detection);
            } else {
              filteredBySize++;
            }
          }
        } catch (e) {
          // Continuar con la siguiente detección
          continue;
        }
      }

      // Log de debug (solo cada 5 frames)
      if (detections.isNotEmpty || maxScoreFound > 0.3) {
        // ignore: avoid_print
        print('Parsing: max=${maxScoreFound.toStringAsFixed(3)}, '
            'above_thresh=$detectionsAboveThreshold, '
            'filtered_size=$filteredBySize, '
            'valid=${detections.length}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error procesando batch: $e');
      return detections;
    }

    return detections;
  }

  /// Convierte este modelo a la entidad del domain layer
  DetectionResult toEntity() {
    return DetectionResult(
      type: type,
      confidence: confidence,
      boundingBox: boundingBox,
      timestamp: timestamp,
    );
  }
}
