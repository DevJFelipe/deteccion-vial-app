/// Modelo de datos para DetectionResult
/// 
/// Extiende la entidad DetectionResult del domain layer y proporciona
/// métodos para convertir la salida del modelo TFLite a entidades del dominio.
library;

import '../../domain/entities/detection_result.dart';
import 'bounding_box_model.dart';
import 'detection_constants.dart'
    show
        bboxXIndex,
        bboxYIndex,
        bboxWidthIndex,
        bboxHeightIndex,
        objectnessIndex,
        classScoresStartIndex,
        numCocoClasses,
        modelOutputBatchSize,
        modelOutputValuesPerDetection,
        modelOutputNumDetections,
        cocoClassToProjectClass,
        projectClasses,
        confidenceThreshold;

/// Modelo de datos para DetectionResult
/// 
/// Extiende la entidad [DetectionResult] del domain layer y proporciona
/// métodos para procesar la salida del modelo TFLite y convertirla a
/// entidades del dominio.
/// 
/// Este modelo se usa en la capa de datos para convertir resultados
/// del modelo TFLite (tensor [1, 84, 8400]) a entidades [DetectionResult].
class DetectionResultModel extends DetectionResult {
  /// Constructor de DetectionResultModel
  /// 
  /// [type] - Tipo de detección ('hueco' o 'grieta')
  /// [confidence] - Nivel de confianza (0.0 a 1.0)
  /// [boundingBox] - Bounding box de la detección
  /// [timestamp] - Timestamp de la detección
  const DetectionResultModel({
    required super.type,
    required super.confidence,
    required super.boundingBox,
    required super.timestamp,
  });

  /// Crea un DetectionResultModel desde la salida del modelo TFLite
  /// 
  /// [tfliteOutput] - Tensor de salida del modelo TFLite con forma [1, 84, 8400]
  /// [detectionIndex] - Índice de la detección en el tensor (0-8399)
  /// [timestamp] - Timestamp de cuando se realizó la detección
  /// 
  /// Procesa un tensor de salida del modelo YOLOv8s y extrae:
  /// - Coordenadas del bounding box (x, y, width, height) normalizadas [0-1]
  /// - Confianza de la detección (objectness * max(class_score))
  /// - Clase detectada (argmax de class_scores)
  /// 
  /// La salida del modelo tiene la siguiente estructura:
  /// [batch_size=1, num_values_per_detection=84, num_detections=8400]
  /// 
  /// Cada detección tiene 84 valores:
  /// [x_center, y_center, width, height, objectness, class0_score, ..., class79_score]
  /// 
  /// Ejemplo:
  /// ```dart
  /// final model = DetectionResultModel.fromTfliteOutput(
  ///   tfliteOutput: outputTensor,
  ///   detectionIndex: 0,
  ///   timestamp: DateTime.now(),
  /// );
  /// ```
  factory DetectionResultModel.fromTfliteOutput({
    required List<dynamic> tfliteOutput,
    required int detectionIndex,
    required DateTime timestamp,
  }) {
    try {
      // El tensor de tflite_flutter puede venir en diferentes formatos:
      // 1. [1, 84, 8400]: tfliteOutput[0] contiene [84, 8400]
      // 2. [84, 8400]: tfliteOutput contiene directamente [84, 8400]
      // 3. [8400, 84]: tfliteOutput contiene [8400, 84] (transpuesta)
      
      List<dynamic> batch;
      
      if (tfliteOutput.length == modelOutputBatchSize) {
        // Forma [1, 84, 8400]: obtener el primer batch
        batch = tfliteOutput[0] as List<dynamic>;
      } else if (tfliteOutput.length == modelOutputValuesPerDetection ||
                 tfliteOutput.length == modelOutputNumDetections) {
        // Forma [84, 8400] o [8400, 84]: usar directamente
        batch = tfliteOutput;
      } else {
        throw ArgumentError(
          'Formato de tensor no reconocido. Longitud: ${tfliteOutput.length}, '
          'se esperaba: 1, $modelOutputValuesPerDetection, o $modelOutputNumDetections',
        );
      }

      // Validar que el batch no esté vacío
      if (batch.isEmpty) {
        throw ArgumentError('El tensor de salida está vacío');
      }

      // Validar el índice de detección
      // El rango válido depende del formato del tensor, pero validamos contra el máximo esperado
      if (detectionIndex < 0 || detectionIndex >= modelOutputNumDetections) {
        throw ArgumentError(
          'El índice de detección debe estar entre 0 y ${modelOutputNumDetections - 1}, '
          'pero se recibió: $detectionIndex',
        );
      }

      // Extraer valores del tensor
      // El tensor de tflite_flutter puede venir en diferentes formatos:
      // 1. [1, 84, 8400]: batch[0][value_index][detection_index]
      // 2. [84, 8400]: batch[value_index][detection_index] (más común)
      // 3. [8400, 84]: batch[detection_index][value_index] (transpuesta)
      
      List<double> detectionValues;
      
      // Verificar el primer elemento para determinar la estructura
      final firstElement = batch[0];
      
      if (firstElement is List) {
        // El tensor tiene forma [84, 8400] o similar
        final firstList = firstElement;
        
        if (firstList.length == modelOutputNumDetections) {
          // Forma [84, 8400]: cada fila (value_index) contiene 8400 valores (una por detección)
          // Acceder a batch[value_index][detection_index]
          detectionValues = List<double>.generate(
            modelOutputValuesPerDetection,
            (valueIndex) {
              if (valueIndex < batch.length) {
                final valueList = batch[valueIndex];
                if (valueList is List) {
                  if (detectionIndex < valueList.length) {
                    final value = valueList[detectionIndex];
                    if (value is num) {
                      return value.toDouble();
                    } else if (value is double) {
                      return value;
                    } else if (value is int) {
                      return value.toDouble();
                    }
                  }
                }
              }
              return 0.0;
            },
          );
        } else {
          // Podría ser forma [8400, 84]: cada fila (detection_index) contiene 84 valores
          // Intentar acceder a batch[detection_index][value_index]
          if (detectionIndex < batch.length) {
            final detectionRow = batch[detectionIndex];
            if (detectionRow is List &&
                detectionRow.length >= modelOutputValuesPerDetection) {
              detectionValues = List<double>.generate(
                modelOutputValuesPerDetection,
                (valueIndex) {
                  final value = detectionRow[valueIndex];
                  if (value is num) {
                    return value.toDouble();
                  } else if (value is double) {
                    return value;
                  } else if (value is int) {
                    return value.toDouble();
                  }
                  return 0.0;
                },
              );
            } else {
              throw ArgumentError(
                'Formato de tensor no soportado. Se espera [1, 84, 8400], '
                '[84, 8400] o [8400, 84], pero se encontró estructura diferente.',
              );
            }
          } else {
            throw ArgumentError(
              'Índice de detección fuera de rango: $detectionIndex (máximo: ${batch.length - 1})',
            );
          }
        }
      } else {
        // El tensor no tiene la estructura esperada
        throw ArgumentError(
          'Formato de tensor no soportado. Se espera List<List<dynamic>>, '
          'pero se recibió: ${firstElement.runtimeType}',
        );
      }

      // Extraer coordenadas del bounding box (normalizadas 0-1)
      final x = detectionValues[bboxXIndex].clamp(0.0, 1.0);
      final y = detectionValues[bboxYIndex].clamp(0.0, 1.0);
      final width = detectionValues[bboxWidthIndex].clamp(0.0, 1.0);
      final height = detectionValues[bboxHeightIndex].clamp(0.0, 1.0);

      // Extraer objectness (probabilidad de que haya un objeto)
      final objectness = detectionValues[objectnessIndex].clamp(0.0, 1.0);

      // Extraer scores de clases (80 clases COCO)
      final classScores = List<double>.generate(
        numCocoClasses,
        (classIndex) {
          final scoreIndex = classScoresStartIndex + classIndex;
          if (scoreIndex < detectionValues.length) {
            return detectionValues[scoreIndex].clamp(0.0, 1.0);
          }
          return 0.0;
        },
      );

      // Calcular confianza: objectness * max(class_scores)
      final maxClassScore = classScores.reduce((a, b) => a > b ? a : b);
      final confidence = (objectness * maxClassScore).clamp(0.0, 1.0);

      // Determinar clase detectada (argmax de class_scores)
      var maxScoreIndex = 0;
      var maxScore = classScores[0];
      for (var i = 1; i < classScores.length; i++) {
        if (classScores[i] > maxScore) {
          maxScore = classScores[i];
          maxScoreIndex = i;
        }
      }

      // Mapear clase COCO a clase del proyecto
      String detectionType;
      if (cocoClassToProjectClass.containsKey(maxScoreIndex)) {
        detectionType = cocoClassToProjectClass[maxScoreIndex]!;
      } else {
        // Si la clase no está mapeada, usar la primera clase del proyecto por defecto
        // Esto puede ocurrir si el modelo detecta una clase COCO no relevante
        detectionType = projectClasses[0];
      }

      // Crear bounding box
      final boundingBox = BoundingBoxModel.fromNormalized(
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // Crear y retornar el modelo
      // boundingBox ya es una entidad del domain (BoundingBox), no necesita conversión
      return DetectionResultModel(
        type: detectionType,
        confidence: confidence,
        boundingBox: boundingBox,
        timestamp: timestamp,
      );
    } catch (e) {
      throw ArgumentError(
        'Error al procesar salida del modelo TFLite: $e',
      );
    }
  }

  /// Crea una lista de DetectionResultModel desde la salida completa del modelo TFLite
  /// 
  /// [tfliteOutput] - Tensor de salida del modelo TFLite con forma [1, 84, 8400]
  /// [timestamp] - Timestamp de cuando se realizó la detección
  /// [confidenceThreshold] - Umbral mínimo de confianza para filtrar detecciones
  /// 
  /// Procesa todas las detecciones en el tensor y retorna solo aquellas
  /// que superan el umbral de confianza.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final detections = DetectionResultModel.fromTfliteOutputBatch(
  ///   tfliteOutput: outputTensor,
  ///   timestamp: DateTime.now(),
  ///   confidenceThreshold: 0.5,
  /// );
  /// ```
  static List<DetectionResultModel> fromTfliteOutputBatch({
    required List<dynamic> tfliteOutput,
    required DateTime timestamp,
    double confidenceThresholdValue = confidenceThreshold,
  }) {
    final detections = <DetectionResultModel>[];

    try {
      // Validar estructura del tensor
      if (tfliteOutput.isEmpty) {
        return detections;
      }

      // Obtener el primer batch
      final batch = tfliteOutput[0] as List<dynamic>;
      if (batch.isEmpty) {
        return detections;
      }

      // Procesar cada detección
      for (var detectionIndex = 0;
          detectionIndex < modelOutputNumDetections;
          detectionIndex++) {
        try {
          final detection = DetectionResultModel.fromTfliteOutput(
            tfliteOutput: tfliteOutput,
            detectionIndex: detectionIndex,
            timestamp: timestamp,
          );

          // Filtrar por umbral de confianza
          if (detection.confidence >= confidenceThresholdValue) {
            detections.add(detection);
          }
        } catch (e) {
          // Si hay error procesando una detección, continuar con la siguiente
          // Esto puede ocurrir si el formato del tensor no es exactamente el esperado
          continue;
        }
      }
    } catch (e) {
      // Si hay error general, retornar lista vacía
      // El error será manejado en el repositorio
      return detections;
    }

    return detections;
  }

  /// Convierte este modelo a la entidad del domain layer
  /// 
  /// Retorna una instancia de [DetectionResult] del domain layer.
  /// Como DetectionResultModel extiende DetectionResult, simplemente retorna this.
  DetectionResult toEntity() {
    return DetectionResult(
      type: type,
      confidence: confidence,
      boundingBox: boundingBox,
      timestamp: timestamp,
    );
  }
}

