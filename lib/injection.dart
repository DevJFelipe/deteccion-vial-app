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
}

