/// Configuración de inyección de dependencias
/// 
/// Este archivo configura GetIt para registrar todas las dependencias
/// de la aplicación usando el patrón de inyección de dependencias.
/// Las dependencias se registran como lazy singletons para eficiencia
/// de memoria.
library;

import 'package:get_it/get_it.dart';

// Feature Camera - Data Layer
import 'features/camera/data/datasources/camera_datasource.dart';
import 'features/camera/data/datasources/camera_datasource_impl.dart';

// Feature Camera - Domain Layer
import 'features/camera/domain/repositories/camera_repository.dart';
import 'features/camera/data/repositories/camera_repository_impl.dart';

// Feature Camera - Presentation Layer
import 'features/camera/presentation/bloc/camera_bloc.dart';

// Feature Detection - Data Layer
import 'features/detection/data/datasources/tflite_datasource.dart';
import 'features/detection/data/datasources/tflite_datasource_impl.dart';

// Feature Detection - Domain Layer
import 'features/detection/domain/repositories/detection_repository.dart';
import 'features/detection/data/repositories/detection_repository_impl.dart';
import 'features/detection/domain/usecases/load_detection_model_usecase.dart';
import 'features/detection/domain/usecases/run_inference_usecase.dart';

// Feature Detection - Presentation Layer
import 'features/detection/presentation/bloc/detection_bloc.dart';

/// Instancia global de GetIt para inyección de dependencias
final getIt = GetIt.instance;

/// Configura todas las dependencias de la aplicación
/// 
/// Registra todas las clases necesarias como lazy singletons,
/// lo que significa que se instancian solo cuando se solicitan
/// por primera vez, mejorando el rendimiento y uso de memoria.
/// 
/// Debe ser llamado antes de usar cualquier dependencia inyectada,
/// típicamente en el método main() de la aplicación.
/// 
/// Ejemplo:
/// ```dart
/// void main() {
///   configureDependencies();
///   runApp(MyApp());
/// }
/// ```
void configureDependencies() {
  // ============================================
  // Feature Camera - Data Layer
  // ============================================

  // Registrar CameraDataSource como lazy singleton
  // La implementación concreta es CameraDataSourceImpl
  getIt.registerLazySingleton<CameraDataSource>(
    () => CameraDataSourceImpl(),
  );

  // ============================================
  // Feature Camera - Domain Layer
  // ============================================

  // Registrar CameraRepository como lazy singleton
  // La implementación concreta es CameraRepositoryImpl
  // Inyecta CameraDataSource como dependencia
  getIt.registerLazySingleton<CameraRepository>(
    () => CameraRepositoryImpl(
      getIt<CameraDataSource>(),
    ),
  );

  // ============================================
  // Feature Camera - Presentation Layer
  // ============================================

  // Registrar CameraBloc como factory
  // Se crea una nueva instancia cada vez que se solicita
  // Esto permite que cada pantalla tenga su propio BLoC
  getIt.registerFactory<CameraBloc>(
    () => CameraBloc(
      repository: getIt<CameraRepository>(),
      dataSource: getIt<CameraDataSource>(),
    ),
  );

  // ============================================
  // Feature Detection - Data Layer
  // ============================================

  // Registrar TfliteDatasource como lazy singleton
  // La implementación concreta es TfliteDatasourceImpl
  getIt.registerLazySingleton<TfliteDatasource>(
    () => TfliteDatasourceImpl(),
  );

  // ============================================
  // Feature Detection - Domain Layer
  // ============================================

  // Registrar DetectionRepository como lazy singleton
  // La implementación concreta es DetectionRepositoryImpl
  // Inyecta TfliteDatasource como dependencia
  getIt.registerLazySingleton<DetectionRepository>(
    () => DetectionRepositoryImpl(
      getIt<TfliteDatasource>(),
    ),
  );

  // Registrar LoadDetectionModelUseCase como factory
  // Se crea una nueva instancia cada vez que se solicita
  getIt.registerFactory<LoadDetectionModelUseCase>(
    () => LoadDetectionModelUseCase(
      getIt<DetectionRepository>(),
    ),
  );

  // Registrar RunInferenceUseCase como factory
  // Se crea una nueva instancia cada vez que se solicita
  getIt.registerFactory<RunInferenceUseCase>(
    () => RunInferenceUseCase(
      getIt<DetectionRepository>(),
    ),
  );

  // ============================================
  // Feature Detection - Presentation Layer
  // ============================================

  // Registrar DetectionBloc como factory
  // Se crea una nueva instancia cada vez que se solicita
  // Esto permite que cada pantalla tenga su propio BLoC
  getIt.registerFactory<DetectionBloc>(
    () => DetectionBloc(
      loadModelUseCase: getIt<LoadDetectionModelUseCase>(),
      runInferenceUseCase: getIt<RunInferenceUseCase>(),
      cameraRepository: getIt<CameraRepository>(),
    ),
  );
}

