/// Repositorio abstracto para el almacenamiento de hallazgos
/// 
/// Define el contrato para guardar, recuperar y eliminar hallazgos
/// en la base de datos local. La implementación concreta se encuentra
/// en la capa de datos.
library;

import '../entities/hallazgo.dart';

/// Repositorio abstracto para operaciones de almacenamiento
/// 
/// Este repositorio define las operaciones necesarias para:
/// - Guardar hallazgos en la base de datos local
/// - Recuperar todos los hallazgos o filtrar por tipo
/// - Eliminar hallazgos
abstract class StorageRepository {
  /// Guarda un hallazgo en la base de datos local
  /// 
  /// [hallazgo] - Hallazgo a guardar
  /// 
  /// Lanza [CacheException] si:
  /// - La base de datos no está disponible
  /// - Hay un error al insertar el registro
  /// 
  /// Ejemplo:
  /// ```dart
  /// final hallazgo = Hallazgo(...);
  /// await repository.saveHallazgo(hallazgo);
  /// ```
  Future<void> saveHallazgo(Hallazgo hallazgo);

  /// Obtiene todos los hallazgos almacenados
  /// 
  /// Retorna una lista de [Hallazgo] ordenados por timestamp descendente
  /// (más recientes primero).
  /// 
  /// Lanza [CacheException] si hay un error al consultar la base de datos.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final hallazgos = await repository.getAllHallazgos();
  /// print('Total de hallazgos: ${hallazgos.length}');
  /// ```
  Future<List<Hallazgo>> getAllHallazgos();

  /// Obtiene todos los hallazgos de un tipo específico
  /// 
  /// [tipo] - Tipo de anomalía ('hueco' o 'grieta')
  /// 
  /// Retorna una lista de [Hallazgo] del tipo especificado,
  /// ordenados por timestamp descendente.
  /// 
  /// Lanza [CacheException] si hay un error al consultar la base de datos.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final huecos = await repository.getHallazgosByType('hueco');
  /// print('Total de huecos: ${huecos.length}');
  /// ```
  Future<List<Hallazgo>> getHallazgosByType(String tipo);

  /// Elimina un hallazgo de la base de datos
  /// 
  /// [id] - Identificador único del hallazgo a eliminar
  /// 
  /// Lanza [CacheException] si:
  /// - El hallazgo no existe
  /// - Hay un error al eliminar el registro
  /// 
  /// Ejemplo:
  /// ```dart
  /// await repository.deleteHallazgo('uuid-del-hallazgo');
  /// ```
  Future<void> deleteHallazgo(String id);

  /// Obtiene un hallazgo por su identificador
  /// 
  /// [id] - Identificador único del hallazgo
  /// 
  /// Retorna el [Hallazgo] si existe, `null` en caso contrario.
  /// 
  /// Lanza [CacheException] si hay un error al consultar la base de datos.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final hallazgo = await repository.getHallazgoById('uuid');
  /// if (hallazgo != null) {
  ///   print('Hallazgo encontrado: ${hallazgo.tipo}');
  /// }
  /// ```
  Future<Hallazgo?> getHallazgoById(String id);

  /// Obtiene todos los hallazgos que necesitan sincronización
  /// 
  /// Retorna una lista de [Hallazgo] donde [sincronizado] es `false`,
  /// ordenados por timestamp ascendente (más antiguos primero).
  /// 
  /// Lanza [CacheException] si hay un error al consultar la base de datos.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final pendientes = await repository.getHallazgosPendientes();
  /// print('Hallazgos pendientes de sincronizar: ${pendientes.length}');
  /// ```
  Future<List<Hallazgo>> getHallazgosPendientes();
}

