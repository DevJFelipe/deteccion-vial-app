/// Caso de uso para ejecutar inferencias de detección
/// 
/// Encapsula la lógica de negocio para ejecutar inferencias del modelo
/// YOLOv8n sobre imágenes. Este caso de uso utiliza el patrón Either
/// para manejar errores de manera funcional.
library;

import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/detection_result.dart';
import '../repositories/detection_repository.dart';

/// Caso de uso para ejecutar inferencias de detección
/// 
/// Este caso de uso maneja la lógica de negocio para:
/// - Validar los bytes de la imagen
/// - Ejecutar la inferencia del modelo
/// - Convertir errores a failures apropiadas
/// 
/// Utiliza el patrón Either para retornar un resultado exitoso
/// o un failure, facilitando el manejo de errores en la capa de presentación.
/// 
/// Ejemplo:
/// ```dart
/// final useCase = RunInferenceUseCase(detectionRepository);
/// final result = await useCase.call(imageBytes);
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (detections) => print('Detectadas ${detections.length} anomalías'),
/// );
/// ```
class RunInferenceUseCase {
  /// Repositorio de detección inyectado
  final DetectionRepository repository;

  /// Constructor del caso de uso
  /// 
  /// [repository] - Repositorio de detección a utilizar
  const RunInferenceUseCase(this.repository);

  /// Ejecuta el caso de uso y retorna un Either con el resultado
  /// 
  /// [imageBytes] - Bytes de la imagen a procesar
  /// 
  /// Retorna [Either] con [Failure] o [List] de [DetectionResult]:
  /// - Left con [Failure]: Si ocurre un error durante la inferencia
  /// - Right con [List] de [DetectionResult]: Si la inferencia es exitosa
  /// 
  /// Ejemplo:
  /// ```dart
  /// final result = await useCase.call(imageBytes);
  /// result.fold(
  ///   (failure) {
  ///     // Manejar error
  ///     if (failure is ModelFailure) {
  ///       print('Error del modelo: ${failure.message}');
  ///     }
  ///   },
  ///   (detections) {
  ///     // Procesar detecciones
  ///     for (final detection in detections) {
  ///       print('${detection.type}: ${detection.confidence}');
  ///     }
  ///   },
  /// );
  /// ```
  Future<Either<Failure, List<DetectionResult>>> call(
    Uint8List imageBytes,
  ) async {
    try {
      // Validar que los bytes de la imagen no estén vacíos
      if (imageBytes.isEmpty) {
        return Left(
          const ModelFailure('Los bytes de la imagen no pueden estar vacíos'),
        );
      }

      // Ejecutar la inferencia
      final results = await repository.runInference(imageBytes);

      // Retornar los resultados exitosos
      return Right(results);
    } on Exception catch (e) {
      // Convertir excepciones a failures
      return Left(ModelFailure('Error durante la inferencia: ${e.toString()}'));
    }
  }
}

