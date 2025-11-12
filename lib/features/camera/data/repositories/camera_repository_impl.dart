/// Implementación concreta del repositorio de cámara
/// 
/// Implementa la interfaz [CameraRepository] del domain layer usando
/// el datasource de cámara. Transforma excepciones de la capa de datos
/// en failures de negocio, manteniendo la separación de responsabilidades
/// de Clean Architecture.
library;

import 'dart:async';
import 'package:camera/camera.dart' as camera_package;
import '../../domain/entities/camera_frame.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../../../core/error/failures.dart' show CameraFailure;
import '../../../../core/error/exceptions.dart' show CameraException;
import '../datasources/camera_datasource.dart';
import '../models/camera_frame_model.dart';

/// Implementación concreta de [CameraRepository]
/// 
/// Este repositorio actúa como intermediario entre la capa de dominio
/// y la capa de datos, transformando:
/// - Excepciones nativas → Failures de negocio
/// - CameraImage (datasource) → CameraFrameModel → CameraFrame (domain)
/// 
/// Mantiene la separación de responsabilidades:
/// - Domain layer: no conoce detalles de implementación (CameraImage, CameraController)
/// - Data layer: no expone modelos internos al domain
/// - Repository: transforma entre capas
class CameraRepositoryImpl implements CameraRepository {
  /// DataSource de cámara inyectado por dependencia
  final CameraDataSource dataSource;

  /// Constructor del repositorio
  /// 
  /// [dataSource] - DataSource de cámara a utilizar (inyección de dependencias)
  /// 
  /// Ejemplo:
  /// ```dart
  /// final dataSource = CameraDataSourceImpl();
  /// final repository = CameraRepositoryImpl(dataSource);
  /// ```
  const CameraRepositoryImpl(this.dataSource);

  @override
  Future<void> initializeCamera() async {
    try {
      await dataSource.initialize();
    } on CameraException catch (e) {
      // Transformar CameraException a CameraFailure
      throw CameraFailure(
        'Error al inicializar la cámara: ${e.message}',
        errorCode: e.errorCode,
      );
    } on Exception catch (e) {
      // Transformar excepciones genéricas a CameraFailure
      throw CameraFailure(
        'Error inesperado al inicializar la cámara: ${e.toString()}',
      );
    } catch (e) {
      // Capturar cualquier otro error
      throw CameraFailure(
        'Error desconocido al inicializar la cámara: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> disposeCamera() async {
    try {
      await dataSource.dispose();
    } on CameraException catch (e) {
      // Transformar CameraException a CameraFailure
      throw CameraFailure(
        'Error al liberar recursos de la cámara: ${e.message}',
        errorCode: e.errorCode,
      );
    } on Exception catch (e) {
      // Transformar excepciones genéricas a CameraFailure
      throw CameraFailure(
        'Error inesperado al liberar recursos: ${e.toString()}',
      );
    } catch (e) {
      // Capturar cualquier otro error pero no lanzar excepción
      // Es mejor intentar limpiar recursos incluso si hay errores
      // El error ya fue logueado en el datasource
    }
  }

  @override
  Stream<CameraFrame> getFrameStream() {
    try {
      // Obtener stream raw del datasource (CameraImage)
      final imageStream = dataSource.getImageStream();

      // Transformar cada CameraImage a CameraFrame entity
      // Flujo: CameraImage → CameraFrameModel → CameraFrame
      return imageStream.map((camera_package.CameraImage cameraImage) {
        try {
          // Convertir CameraImage a CameraFrameModel
          final model = CameraFrameModel.fromCameraImage(cameraImage);

          // Convertir modelo a entidad del domain layer
          return model.toEntity();
        } catch (e) {
          // Si hay error en la conversión, emitir error al stream
          // Esto permite que el listener maneje el error apropiadamente
          throw CameraFailure(
            'Error al convertir frame de cámara: ${e.toString()}',
            errorCode: 'FRAME_CONVERSION_ERROR',
          );
        }
      }).handleError((error) {
        // Transformar errores del stream a CameraFailure si no lo son ya
        if (error is CameraFailure) {
          throw error;
        }
        throw CameraFailure(
          'Error en el stream de frames: ${error.toString()}',
          errorCode: 'STREAM_ERROR',
        );
      });
    } on CameraException catch (e) {
      // Si el datasource lanza excepción al obtener el stream
      throw CameraFailure(
        'Error al obtener stream de frames: ${e.message}',
        errorCode: e.errorCode,
      );
    } on Exception catch (e) {
      // Transformar excepciones genéricas
      throw CameraFailure(
        'Error inesperado al obtener stream: ${e.toString()}',
      );
    } catch (e) {
      // Capturar cualquier otro error
      throw CameraFailure(
        'Error desconocido al obtener stream: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await dataSource.hasPermission();
    } catch (e) {
      // En caso de error, retornar false
      // No lanzar excepción para permitir que el caller maneje el caso
      return false;
    }
  }
}

