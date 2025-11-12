/// BLoC para gestión de estados de cámara
/// 
/// Orquesta la lógica de negocio entre eventos y estados para
/// gestionar el ciclo de vida completo de la cámara, incluyendo
/// inicialización, streaming, permisos y liberación de recursos.
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../data/datasources/camera_datasource.dart';
import '../../../../core/error/failures.dart' show CameraFailure;
import 'camera_event.dart';
import 'camera_state.dart';

/// BLoC para gestión de estados de cámara
/// 
/// Este BLoC gestiona el ciclo de vida completo de la cámara:
/// - Inicialización y verificación de permisos
/// - Streaming de frames
/// - Manejo de errores
/// - Liberación de recursos
/// 
/// Usa el patrón BLoC para separar la lógica de negocio de la UI,
/// permitiendo que los widgets reaccionen a cambios de estado de
/// forma reactiva.
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  /// Repositorio de cámara inyectado
  /// 
  /// Usado para operaciones de alto nivel como inicializar,
  /// obtener stream y liberar recursos.
  final CameraRepository repository;

  /// DataSource de cámara inyectado
  /// 
  /// Usado para acceso directo a métodos de permisos que
  /// no están expuestos en el repository.
  final CameraDataSource dataSource;

  /// StreamSubscription para el stream de frames
  /// 
  /// Se mantiene una referencia para poder cancelarla
  /// cuando sea necesario.
  StreamSubscription? _frameStreamSubscription;

  /// Constructor del CameraBloc
  /// 
  /// [repository] - Repositorio de cámara para operaciones de negocio
  /// [dataSource] - DataSource de cámara para acceso a permisos
  /// 
  /// Ejemplo:
  /// ```dart
  /// final bloc = CameraBloc(
  ///   repository: getIt<CameraRepository>(),
  ///   dataSource: getIt<CameraDataSource>(),
  /// );
  /// ```
  CameraBloc({
    required this.repository,
    required this.dataSource,
  }) : super(const CameraInitial()) {
    // Registrar handlers para todos los eventos
    on<InitializeCameraEvent>(_onInitializeCamera);
    on<StartStreamingEvent>(_onStartStreaming);
    on<StopStreamingEvent>(_onStopStreaming);
    on<DisposeCameraEvent>(_onDisposeCamera);
    on<RequestPermissionEvent>(_onRequestPermission);
  }

  /// Handler para InitializeCameraEvent
  /// 
  /// Proceso de inicialización:
  /// 1. Cambiar a estado CameraLoading
  /// 2. Verificar permisos con dataSource.hasPermission()
  /// 3. Si no hay permisos, solicitar con dataSource.requestPermission()
  /// 4. Si se deniega, cambiar a PermissionDenied
  /// 5. Si se otorga, llamar a repository.initializeCamera()
  /// 6. Si inicialización exitosa, obtener stream y cambiar a CameraStreaming
  /// 7. Si falla, cambiar a CameraError con mensaje
  Future<void> _onInitializeCamera(
    InitializeCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      // Cambiar a estado de carga
      emit(const CameraLoading());

      // Verificar permisos
      final hasPermissionValue = await dataSource.hasPermission();
      if (!hasPermissionValue) {
        // Solicitar permiso si no está concedido
        final permissionGranted = await dataSource.requestPermission();
        if (!permissionGranted) {
          // Permiso denegado
          emit(const PermissionDenied(permissionType: 'camera'));
          return;
        }
      }

      // Inicializar la cámara
      await repository.initializeCamera();

      // Obtener el stream de frames
      final frameStream = repository.getFrameStream();

      // Cambiar a estado de streaming
      emit(CameraStreaming(frameStream: frameStream));
    } on CameraFailure catch (e) {
      // Convertir CameraFailure a mensaje de error amigable
      final errorMessage = _getErrorMessage(e);
      emit(CameraError(errorMessage: errorMessage));
    } catch (e) {
      // Capturar cualquier otro error
      emit(CameraError(
        errorMessage: 'Error inesperado al inicializar la cámara: ${e.toString()}',
      ));
    }
  }

  /// Handler para StartStreamingEvent
  /// 
  /// Este evento es principalmente para control explícito del streaming.
  /// Si la cámara ya está en estado CameraStreaming, no hace nada.
  /// Si está en otro estado, intenta inicializar.
  Future<void> _onStartStreaming(
    StartStreamingEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Si ya está en streaming, no hacer nada
    if (state is CameraStreaming) {
      return;
    }

    // Si no está inicializado, inicializar primero
    if (state is! CameraStreaming) {
      add(const InitializeCameraEvent());
    }
  }

  /// Handler para StopStreamingEvent
  /// 
  /// Detiene el consumo del stream pero no libera los recursos.
  /// La cámara permanece inicializada y puede reanudar el streaming.
  Future<void> _onStopStreaming(
    StopStreamingEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Cancelar la suscripción al stream si existe
    await _frameStreamSubscription?.cancel();
    _frameStreamSubscription = null;

    // No cambiar el estado, la cámara sigue inicializada
    // El stream simplemente deja de ser consumido
  }

  /// Handler para DisposeCameraEvent
  /// 
  /// Libera completamente todos los recursos de la cámara:
  /// - Cancela la suscripción al stream
  /// - Llama a repository.disposeCamera()
  /// - Cambia a estado CameraDisposed
  Future<void> _onDisposeCamera(
    DisposeCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      // Cancelar suscripción al stream si existe
      await _frameStreamSubscription?.cancel();
      _frameStreamSubscription = null;

      // Liberar recursos de la cámara
      await repository.disposeCamera();

      // Cambiar a estado disposed
      emit(const CameraDisposed());
    } on CameraFailure {
      // Aunque haya error, intentar cambiar a disposed
      // Es mejor limpiar lo que se pueda
      emit(const CameraDisposed());
    } catch (e) {
      // Asegurar que se cambie a disposed incluso si hay error
      emit(const CameraDisposed());
    }
  }

  /// Handler para RequestPermissionEvent
  /// 
  /// Solicita explícitamente el permiso de cámara al sistema.
  /// Después de solicitar, si se otorga, intenta inicializar la cámara.
  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      // Solicitar permiso
      final permissionGranted = await dataSource.requestPermission();

      if (permissionGranted) {
        // Si se otorga, inicializar la cámara
        add(const InitializeCameraEvent());
      } else {
        // Si se deniega, cambiar a PermissionDenied
        emit(const PermissionDenied(permissionType: 'camera'));
      }
    } catch (e) {
      // Capturar errores al solicitar permiso
      emit(CameraError(
        errorMessage: 'Error al solicitar permiso de cámara: ${e.toString()}',
      ));
    }
  }

  /// Convierte CameraFailure a mensaje de error amigable para el usuario
  /// 
  /// [failure] - CameraFailure a convertir
  /// 
  /// Retorna un mensaje en español que explica el error de forma
  /// comprensible para el usuario.
  String _getErrorMessage(CameraFailure failure) {
    // Mensajes amigables según el código de error
    switch (failure.errorCode) {
      case 'PERMISSION_DENIED':
        return 'Permiso de cámara denegado. Por favor, concede el permiso en la configuración de la aplicación.';
      case 'NO_CAMERAS_AVAILABLE':
        return 'No se encontraron cámaras disponibles en el dispositivo.';
      case 'INITIALIZATION_FAILED':
        return 'No se pudo inicializar la cámara. Por favor, intenta nuevamente.';
      case 'NOT_INITIALIZED':
        return 'La cámara no está inicializada. Por favor, intenta nuevamente.';
      case 'STREAM_ERROR':
        return 'Error al obtener el stream de video. Por favor, intenta nuevamente.';
      default:
        // Mensaje genérico si no hay código específico
        return failure.message;
    }
  }

  @override
  Future<void> close() {
    // Asegurar que se cancelen las suscripciones al cerrar el BLoC
    _frameStreamSubscription?.cancel();
    return super.close();
  }
}

