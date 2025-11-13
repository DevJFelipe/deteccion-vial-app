/// BLoC para gestión de estados de detección
/// 
/// Orquesta la lógica de negocio entre eventos y estados para
/// gestionar el ciclo de vida completo del sistema de detección,
/// incluyendo carga del modelo, inferencia en tiempo real, métricas
/// de rendimiento y liberación de recursos.
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/load_detection_model_usecase.dart';
import '../../domain/usecases/run_inference_usecase.dart';
import '../../../camera/domain/repositories/camera_repository.dart';
import '../../../camera/domain/entities/camera_frame.dart';
import '../../../../core/error/failures.dart' show Failure, ModelFailure;
import 'detection_event.dart';
import 'detection_state.dart';

/// BLoC para gestión de estados de detección
/// 
/// Este BLoC gestiona el ciclo de vida completo del sistema de detección:
/// - Carga del modelo TFLite
/// - Procesamiento de frames en tiempo real
/// - Cálculo de métricas de rendimiento (FPS, latencia)
/// - Manejo de errores
/// - Liberación de recursos
/// 
/// Usa el patrón BLoC para separar la lógica de negocio de la UI,
/// permitiendo que los widgets reaccionen a cambios de estado de
/// forma reactiva.
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  /// Caso de uso para cargar el modelo
  final LoadDetectionModelUseCase loadModelUseCase;

  /// Caso de uso para ejecutar inferencias
  final RunInferenceUseCase runInferenceUseCase;

  /// Repositorio de cámara para obtener stream de frames
  final CameraRepository cameraRepository;

  /// Suscripción al stream de frames de la cámara
  StreamSubscription? _frameStreamSubscription;

  /// Tiempo de inicio para calcular FPS
  DateTime? _fpsStartTime;

  /// Contador de frames procesados para calcular FPS
  int _frameCount = 0;

  /// Constructor del DetectionBloc
  /// 
  /// [loadModelUseCase] - Caso de uso para cargar el modelo
  /// [runInferenceUseCase] - Caso de uso para ejecutar inferencias
  /// [cameraRepository] - Repositorio de cámara para obtener frames
  /// 
  /// Ejemplo:
  /// ```dart
  /// final bloc = DetectionBloc(
  ///   loadModelUseCase: getIt<LoadDetectionModelUseCase>(),
  ///   runInferenceUseCase: getIt<RunInferenceUseCase>(),
  ///   cameraRepository: getIt<CameraRepository>(),
  /// );
  /// ```
  DetectionBloc({
    required this.loadModelUseCase,
    required this.runInferenceUseCase,
    required this.cameraRepository,
  }) : super(const DetectionInitial()) {
    // Registrar handlers para todos los eventos
    on<LoadModelEvent>(_onLoadModel);
    on<StartDetectionEvent>(_onStartDetection);
    on<StopDetectionEvent>(_onStopDetection);
    on<ProcessFrameEvent>(_onProcessFrame);
    on<DisposeDetectionEvent>(_onDisposeDetection);
  }

  /// Handler para LoadModelEvent
  /// 
  /// Proceso de carga del modelo:
  /// 1. Cambiar a estado ModelLoading
  /// 2. Medir tiempo de inicio
  /// 3. Llamar a LoadDetectionModelUseCase
  /// 4. Si exitoso: cambiar a ModelLoaded
  /// 5. Si falla: cambiar a DetectionError con mensaje
  Future<void> _onLoadModel(
    LoadModelEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Cambiar a estado de carga
      emit(const ModelLoading());

      // Cargar el modelo
      final result = await loadModelUseCase.call(event.modelPath);

      // Procesar resultado
      result.fold(
        (failure) {
          // Error al cargar el modelo
          final errorMessage = _getErrorMessage(failure);
          emit(DetectionError(message: errorMessage));
        },
        (_) {
          // Modelo cargado exitosamente
          emit(const ModelLoaded());
        },
      );
    } catch (e) {
      // Capturar cualquier otro error
      emit(DetectionError(
        message: 'Error inesperado al cargar el modelo: ${e.toString()}',
      ));
    }
  }

  /// Handler para StartDetectionEvent
  /// 
  /// Proceso de inicio de detección:
  /// 1. Verificar que el estado sea ModelLoaded
  /// 2. Obtener stream de frames del CameraRepository
  /// 3. Inicializar contadores de FPS
  /// 4. Escuchar stream y disparar ProcessFrameEvent automáticamente
  /// 5. Cambiar a estado Detecting
  Future<void> _onStartDetection(
    StartDetectionEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Solo permitir si el modelo está cargado
      if (state is! ModelLoaded) {
        emit(const DetectionError(
          message: 'El modelo debe estar cargado antes de iniciar detecciones',
        ));
        return;
      }

      // Obtener stream de frames
      // Si se proporciona en el evento, usarlo; si no, obtener del repositorio
      final Stream<CameraFrame> frameStream;
      if (event.frameStream != null) {
        frameStream = event.frameStream! as Stream<CameraFrame>;
      } else {
        try {
          frameStream = cameraRepository.getFrameStream();
        } catch (e) {
          emit(DetectionError(
            message: 'Error al obtener stream de frames: ${e.toString()}',
          ));
          return;
        }
      }

      // Inicializar contadores de FPS
      _fpsStartTime = DateTime.now();
      _frameCount = 0;

      // Cancelar suscripción anterior si existe
      await _frameStreamSubscription?.cancel();

      // Escuchar stream y procesar cada frame
      _frameStreamSubscription = frameStream.listen(
        (frame) {
          // Disparar evento para procesar el frame
          add(ProcessFrameEvent(
            imageBytes: frame.image,
            width: frame.width,
            height: frame.height,
          ));
        },
        onError: (error) {
          // Manejar errores del stream
          emit(DetectionError(
            message: 'Error en el stream de frames: ${error.toString()}',
          ));
        },
      );

      // Cambiar a estado Detecting con valores iniciales
      emit(const Detecting(
        detections: [],
        fps: 0.0,
        frameCount: 0,
        lastLatency: 0.0,
      ));
    } catch (e) {
      // Capturar errores al iniciar detección
      emit(DetectionError(
        message: 'Error al iniciar detecciones: ${e.toString()}',
      ));
    }
  }

  /// Handler para ProcessFrameEvent
  /// 
  /// Proceso de inferencia sobre un frame:
  /// 1. Medir tiempo de inicio de inferencia
  /// 2. Llamar a RunInferenceUseCase
  /// 3. Medir latencia (tiempo inicio-fin)
  /// 4. Calcular FPS (frames procesados / tiempo transcurrido)
  /// 5. Actualizar estado Detecting con nuevas detecciones y métricas
  Future<void> _onProcessFrame(
    ProcessFrameEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Solo procesar si estamos en estado Detecting
      if (state is! Detecting) {
        return;
      }

      final currentState = state as Detecting;

      // Medir tiempo de inicio de inferencia
      final inferenceStartTime = DateTime.now();

      // Ejecutar inferencia
      final result = await runInferenceUseCase.call(event.imageBytes);

      // Medir latencia
      final latency = DateTime.now().difference(inferenceStartTime).inMilliseconds.toDouble();

      // Procesar resultado
      result.fold(
        (failure) {
          // Error durante la inferencia
          final errorMessage = _getErrorMessage(failure);
          emit(DetectionError(message: errorMessage));
        },
        (detections) {
          // Inferencia exitosa
          _frameCount++;

          // Calcular FPS
          double fps = 0.0;
          if (_fpsStartTime != null) {
            final elapsed = DateTime.now().difference(_fpsStartTime!);
            if (elapsed.inSeconds > 0) {
              fps = _frameCount / elapsed.inSeconds;
            } else {
              // Si aún no ha pasado un segundo, estimar FPS basado en latencia
              if (latency > 0) {
                fps = 1000.0 / latency;
              }
            }
          }

          // Actualizar estado con nuevas detecciones y métricas
          emit(currentState.copyWith(
            detections: detections,
            fps: fps,
            frameCount: _frameCount,
            lastLatency: latency,
          ));
        },
      );
    } catch (e) {
      // Capturar errores durante el procesamiento
      emit(DetectionError(
        message: 'Error al procesar frame: ${e.toString()}',
      ));
    }
  }

  /// Handler para StopDetectionEvent
  /// 
  /// Proceso de detención de detecciones:
  /// 1. Cancelar suscripción al stream de frames
  /// 2. Cambiar a estado DetectionPaused
  Future<void> _onStopDetection(
    StopDetectionEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Cancelar suscripción al stream
      await _frameStreamSubscription?.cancel();
      _frameStreamSubscription = null;

      // Resetear contadores
      _fpsStartTime = null;
      _frameCount = 0;

      // Cambiar a estado pausado
      emit(const DetectionPaused());
    } catch (e) {
      // Aunque haya error, intentar cambiar a pausado
      emit(const DetectionPaused());
    }
  }

  /// Handler para DisposeDetectionEvent
  /// 
  /// Proceso de liberación de recursos:
  /// 1. Cancelar suscripción al stream
  /// 2. Resetear contadores
  /// 3. Cambiar a estado DetectionInitial
  Future<void> _onDisposeDetection(
    DisposeDetectionEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Cancelar suscripción al stream
      await _frameStreamSubscription?.cancel();
      _frameStreamSubscription = null;

      // Resetear contadores
      _fpsStartTime = null;
      _frameCount = 0;

      // Cambiar a estado inicial
      emit(const DetectionInitial());
    } catch (e) {
      // Asegurar que se cambie a inicial incluso si hay error
      emit(const DetectionInitial());
    }
  }

  /// Convierte Failure a mensaje de error amigable para el usuario
  /// 
  /// [failure] - Failure a convertir
  /// 
  /// Retorna un mensaje en español que explica el error de forma
  /// comprensible para el usuario.
  String _getErrorMessage(Failure failure) {
    if (failure is ModelFailure) {
      // Mensajes específicos para errores del modelo
      final message = failure.message.toLowerCase();
      if (message.contains('no puede estar vacía') ||
          message.contains('no puede estar vacío')) {
        return 'La ruta del modelo no es válida. Por favor, verifica la configuración.';
      }
      if (message.contains('no se puede cargar') ||
          message.contains('no se encontró') ||
          message.contains('no existe')) {
        return 'No se pudo cargar el modelo. Por favor, verifica que el archivo del modelo existe.';
      }
      if (message.contains('intérprete') || message.contains('interpreter')) {
        return 'Error al inicializar el modelo. Por favor, intenta nuevamente.';
      }
      if (message.contains('no cargado') || message.contains('not loaded')) {
        return 'El modelo no está cargado. Por favor, carga el modelo primero.';
      }
    }

    // Mensaje genérico si no hay mensaje específico
    return failure.message;
  }

  @override
  Future<void> close() {
    // Asegurar que se cancelen las suscripciones al cerrar el BLoC
    _frameStreamSubscription?.cancel();
    return super.close();
  }
}

