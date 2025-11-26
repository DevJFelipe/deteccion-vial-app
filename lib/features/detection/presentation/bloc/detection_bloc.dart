/// BLoC para gestión del sistema de detección
/// 
/// Orquesta el ciclo de vida del modelo TFLite y el procesamiento
/// de frames de cámara para detectar huecos y grietas en tiempo real.
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../data/models/detection_constants.dart' show inferenceThrottleMs;
import '../../../../core/constants/app_constants.dart' show modelPath;
import '../../../../core/error/exceptions.dart';
import 'detection_event.dart';
import 'detection_state.dart';

/// BLoC para gestión del sistema de detección
/// 
/// Este BLoC maneja:
/// - Carga del modelo TFLite al iniciar
/// - Procesamiento de frames con throttling
/// - Emisión de resultados de detección
/// - Liberación de recursos al cerrar
/// 
/// Ejemplo de uso:
/// ```dart
/// final bloc = DetectionBloc(repository: detectionRepository);
/// bloc.add(const LoadModelEvent());
/// // Cuando hay un frame disponible:
/// bloc.add(ProcessFrameEvent(frame: cameraFrame));
/// ```
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  /// Repositorio de detección inyectado
  final DetectionRepository repository;

  /// Timestamp de la última inferencia para throttling
  DateTime? _lastInferenceTime;

  /// Flag para evitar inferencias concurrentes
  bool _isProcessing = false;

  /// Constructor del DetectionBloc
  /// 
  /// [repository] - Repositorio de detección a utilizar
  DetectionBloc({
    required this.repository,
  }) : super(const DetectionInitial()) {
    on<LoadModelEvent>(_onLoadModel);
    on<ProcessFrameEvent>(_onProcessFrame);
    on<DisposeModelEvent>(_onDisposeModel);
    on<ClearDetectionsEvent>(_onClearDetections);
  }

  /// Handler para LoadModelEvent
  /// 
  /// Carga el modelo TFLite desde assets.
  /// Si el modelo ya está cargado, no hace nada.
  Future<void> _onLoadModel(
    LoadModelEvent event,
    Emitter<DetectionState> emit,
  ) async {
    // Si ya está cargado o cargando, ignorar
    if (state is DetectionReady || state is DetectionModelLoading) {
      return;
    }

    emit(const DetectionModelLoading());

    try {
      // Cargar el modelo usando la ruta completa del asset
      await repository.loadModel(modelPath);

      emit(const DetectionReady());
    } on ModelInferenceException catch (e) {
      emit(DetectionError(
        message: 'Error al cargar el modelo: ${e.message}',
        canRetry: true,
      ));
    } catch (e) {
      emit(DetectionError(
        message: 'Error inesperado al cargar el modelo: $e',
        canRetry: true,
      ));
    }
  }

  /// Handler para ProcessFrameEvent
  /// 
  /// Procesa un frame de cámara si el modelo está cargado y
  /// ha pasado suficiente tiempo desde la última inferencia (throttling).
  Future<void> _onProcessFrame(
    ProcessFrameEvent event,
    Emitter<DetectionState> emit,
  ) async {
    // Solo procesar si el modelo está listo
    if (state is! DetectionReady) {
      return;
    }

    // Evitar inferencias concurrentes
    if (_isProcessing) {
      return;
    }

    // Aplicar throttling
    final now = DateTime.now();
    if (_lastInferenceTime != null) {
      final elapsed = now.difference(_lastInferenceTime!).inMilliseconds;
      if (elapsed < inferenceThrottleMs) {
        return;
      }
    }

    _isProcessing = true;
    _lastInferenceTime = now;

    // Emitir estado de procesamiento
    final currentState = state as DetectionReady;
    emit(currentState.copyWith(isProcessing: true));

    try {
      // Log para debug
      // ignore: avoid_print
      print('Procesando frame: ${event.frame.width}x${event.frame.height}, bytes: ${event.frame.image.length}');
      
      // Medir tiempo de inferencia
      final startTime = DateTime.now();

      // Ejecutar inferencia con dimensiones del frame
      final detections = await repository.runInference(
        event.frame.image,
        width: event.frame.width,
        height: event.frame.height,
      );

      final endTime = DateTime.now();
      final inferenceTime = endTime.difference(startTime).inMilliseconds;

      // Log de resultados
      // ignore: avoid_print
      print('Inferencia completada: ${inferenceTime}ms, detecciones: ${detections.length}');

      // Emitir resultados
      emit(DetectionReady(
        detections: detections,
        inferenceTimeMs: inferenceTime,
        isProcessing: false,
      ));
    } on ModelInferenceException catch (e) {
      // En caso de error, mantener el estado listo pero sin detecciones
      emit(DetectionReady(
        detections: const [],
        inferenceTimeMs: 0,
        isProcessing: false,
      ));
      // Log del error pero no cambiar a estado de error
      // para permitir continuar procesando frames
      // ignore: avoid_print
      print('Error en inferencia: ${e.message}');
    } catch (e, stackTrace) {
      // Mantener estado listo para seguir intentando
      emit(DetectionReady(
        detections: const [],
        inferenceTimeMs: 0,
        isProcessing: false,
      ));
      // ignore: avoid_print
      print('Error inesperado en inferencia: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  /// Handler para DisposeModelEvent
  /// 
  /// Libera los recursos del modelo TFLite.
  Future<void> _onDisposeModel(
    DisposeModelEvent event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      // Aquí se liberarían los recursos del modelo
      // El repositorio debería tener un método dispose()
      // Por ahora solo cambiamos el estado
      emit(const DetectionDisposed());
    } catch (e) {
      // Aún así cambiar a disposed
      emit(const DetectionDisposed());
    }
  }

  /// Handler para ClearDetectionsEvent
  /// 
  /// Limpia las detecciones actuales sin liberar el modelo.
  Future<void> _onClearDetections(
    ClearDetectionsEvent event,
    Emitter<DetectionState> emit,
  ) async {
    if (state is DetectionReady) {
      emit(const DetectionReady(
        detections: [],
        inferenceTimeMs: 0,
        isProcessing: false,
      ));
    }
  }

  @override
  Future<void> close() {
    // Limpiar recursos al cerrar el BLoC
    _isProcessing = false;
    return super.close();
  }
}

