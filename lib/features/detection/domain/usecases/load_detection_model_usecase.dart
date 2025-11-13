/// Caso de uso para cargar el modelo de detección
/// 
/// Encapsula la lógica de negocio para cargar el modelo TensorFlow Lite
/// desde assets. Este caso de uso utiliza el patrón Either para manejar
/// errores de manera funcional.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/detection_repository.dart';

/// Caso de uso para cargar el modelo de detección
/// 
/// Este caso de uso maneja la lógica de negocio para:
/// - Validar la ruta del modelo
/// - Cargar el modelo TensorFlow Lite desde assets
/// - Convertir errores a failures apropiadas
/// 
/// Utiliza el patrón Either para retornar un resultado exitoso
/// o un failure, facilitando el manejo de errores en la capa de presentación.
/// 
/// Ejemplo:
/// ```dart
/// final useCase = LoadDetectionModelUseCase(detectionRepository);
/// final result = await useCase.call('assets/models/yolov8s_int8.tflite');
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (_) => print('Modelo cargado exitosamente'),
/// );
/// ```
class LoadDetectionModelUseCase {
  /// Repositorio de detección inyectado
  final DetectionRepository repository;

  /// Constructor del caso de uso
  /// 
  /// [repository] - Repositorio de detección a utilizar
  const LoadDetectionModelUseCase(this.repository);

  /// Ejecuta el caso de uso y retorna un Either con el resultado
  /// 
  /// [modelPath] - Ruta del archivo del modelo (.tflite) en assets
  /// 
  /// Retorna [Either] con [Failure] o [void]:
  /// - Left con [Failure]: Si ocurre un error durante la carga
  /// - Right con [void]: Si la carga es exitosa
  /// 
  /// Ejemplo:
  /// ```dart
  /// final result = await useCase.call('assets/models/yolov8s_int8.tflite');
  /// result.fold(
  ///   (failure) {
  ///     // Manejar error
  ///     if (failure is ModelFailure) {
  ///       print('Error del modelo: ${failure.message}');
  ///     }
  ///   },
  ///   (_) {
  ///     // Modelo cargado exitosamente
  ///     print('Modelo listo para usar');
  ///   },
  /// );
  /// ```
  Future<Either<Failure, void>> call(String modelPath) async {
    try {
      // Validar que la ruta del modelo no esté vacía
      if (modelPath.isEmpty) {
        return Left(
          const ModelFailure('La ruta del modelo no puede estar vacía'),
        );
      }

      // Cargar el modelo
      await repository.loadModel(modelPath);

      // Retornar éxito
      return const Right(null);
    } on Exception catch (e) {
      // Convertir excepciones a failures
      return Left(
        ModelFailure('Error al cargar el modelo: ${e.toString()}'),
      );
    } catch (e) {
      // Capturar cualquier otro error
      return Left(
        ModelFailure('Error inesperado al cargar el modelo: ${e.toString()}'),
      );
    }
  }
}

