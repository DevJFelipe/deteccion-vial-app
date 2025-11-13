/// Pantalla principal para detección de anomalías viales en tiempo real
/// 
/// Integra el modelo TFLite con la cámara para mostrar detecciones
/// de huecos y grietas sobre el preview de la cámara con métricas
/// de rendimiento en tiempo real.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart' as camera_package;
import '../bloc/detection_bloc.dart';
import '../bloc/detection_event.dart';
import '../bloc/detection_state.dart';
import '../../../camera/presentation/bloc/camera_bloc.dart';
import '../../../camera/presentation/bloc/camera_event.dart';
import '../../../camera/presentation/bloc/camera_state.dart';
import '../../../camera/presentation/widgets/camera_preview_widget.dart';
import '../widgets/detection_overlay_widget.dart';
import '../widgets/detection_stats_widget.dart';
import '../widgets/model_loading_widget.dart';
import '../widgets/detection_error_widget.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection.dart';

/// Pantalla principal para detección de anomalías viales
/// 
/// Esta pantalla gestiona el ciclo de vida completo del sistema de detección:
/// - Carga el modelo TFLite al iniciar
/// - Inicia el stream de detecciones cuando el modelo está listo
/// - Muestra preview de cámara con bounding boxes superpuestos
/// - Muestra métricas de rendimiento (FPS, latencia)
/// - Maneja errores y estados de pausa
/// - Libera recursos al desmontarse
class DetectionScreen extends StatefulWidget {
  /// Constructor del DetectionScreen
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  /// BLoC de detección
  late final DetectionBloc _detectionBloc;

  /// BLoC de cámara (para obtener el controller)
  late final CameraBloc _cameraBloc;

  /// Bandera para controlar si ya se intentó iniciar las detecciones
  bool _hasTriedToStartDetection = false;

  @override
  void initState() {
    super.initState();
    // Obtener BLoCs desde GetIt
    _detectionBloc = getIt<DetectionBloc>();
    _cameraBloc = getIt<CameraBloc>();

    // Inicializar cámara y cargar modelo en paralelo
    _cameraBloc.add(const InitializeCameraEvent());
    _detectionBloc.add(
      LoadModelEvent(modelPath: modelPath),
    );
  }

  @override
  void dispose() {
    // Liberar recursos al desmontar
    _detectionBloc.add(const DisposeDetectionEvent());
    _cameraBloc.add(const DisposeCameraEvent());
    _detectionBloc.close();
    _cameraBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DetectionBloc>.value(value: _detectionBloc),
        BlocProvider<CameraBloc>.value(value: _cameraBloc),
      ],
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              // Escuchar estado de detección
              BlocListener<DetectionBloc, DetectionState>(
                listener: (context, detectionState) {
                  // Cuando el modelo se carga, verificar si la cámara también está lista
                  if (detectionState is ModelLoaded && !_hasTriedToStartDetection) {
                    _tryStartDetection();
                  }
                },
              ),
              // Escuchar estado de cámara
              BlocListener<CameraBloc, CameraState>(
                listener: (context, cameraState) {
                  // Cuando la cámara está streaming, verificar si el modelo también está listo
                  if (cameraState is CameraStreaming && !_hasTriedToStartDetection) {
                    _tryStartDetection();
                  }
                },
              ),
            ],
            child: BlocBuilder<DetectionBloc, DetectionState>(
              builder: (context, state) {
                // Manejar diferentes estados
                if (state is DetectionInitial || state is ModelLoading) {
                  return const ModelLoadingWidget();
                } else if (state is ModelLoaded) {
                  // Mostrar carga mientras se inicia la detección
                  return const ModelLoadingWidget();
                } else if (state is Detecting) {
                  return _buildDetectingState(state);
                } else if (state is DetectionError) {
                  return DetectionErrorWidget(errorMessage: state.message);
                } else if (state is DetectionPaused) {
                  return _buildPausedState();
                } else {
                  // Estado desconocido, mostrar carga
                  return const ModelLoadingWidget();
                }
              },
            ),
          ),
        ),
        floatingActionButton: BlocBuilder<DetectionBloc, DetectionState>(
          builder: (context, state) {
            if (state is Detecting) {
              // Botón para pausar
              return FloatingActionButton(
                onPressed: () {
                  _hasTriedToStartDetection = false;
                  _detectionBloc.add(const StopDetectionEvent());
                },
                tooltip: 'Pausar detección',
                child: const Icon(Icons.pause),
              );
            } else if (state is DetectionPaused) {
              // Botón para reanudar
              return FloatingActionButton(
                onPressed: () {
                  final cameraState = _cameraBloc.state;
                  if (cameraState is CameraStreaming) {
                    _detectionBloc.add(StartDetectionEvent(
                      frameStream: cameraState.frameStream,
                    ));
                  }
                },
                tooltip: 'Reanudar detección',
                child: const Icon(Icons.play_arrow),
              );
            } else {
              // No mostrar FAB en otros estados
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  /// Intenta iniciar las detecciones si tanto el modelo como la cámara están listos
  void _tryStartDetection() {
    final detectionState = _detectionBloc.state;
    final cameraState = _cameraBloc.state;

    // Solo iniciar si ambos están listos y no se ha intentado antes
    if (detectionState is ModelLoaded &&
        cameraState is CameraStreaming &&
        !_hasTriedToStartDetection) {
      _hasTriedToStartDetection = true;
      // Pasar el stream del CameraBloc al evento
      _detectionBloc.add(StartDetectionEvent(
        frameStream: cameraState.frameStream,
      ));
    }
  }

  /// Construye el AppBar con título e indicador de estado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detección Vial - IA'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Disparar DisposeDetectionEvent antes de volver
          _detectionBloc.add(const DisposeDetectionEvent());
          Navigator.of(context).pop();
        },
      ),
      actions: [
        // Indicador de estado
        BlocBuilder<DetectionBloc, DetectionState>(
          builder: (context, state) {
            if (state is Detecting) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.circle,
                  size: 12,
                  color: Colors.green,
                ),
              );
            } else if (state is DetectionPaused) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.circle,
                  size: 12,
                  color: Colors.orange,
                ),
              );
            } else if (state is DetectionError) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.circle,
                  size: 12,
                  color: Colors.red,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Construye el estado de detección activa
  Widget _buildDetectingState(Detecting state) {
    // Obtener el estado de la cámara para acceder al controller
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, cameraState) {
        if (cameraState is CameraStreaming) {
          // Obtener dimensiones del preview desde el controller
          final controller = cameraState.controller as camera_package.CameraController;
          final previewSize = controller.value.previewSize;
          final previewWidth = previewSize?.height.toInt() ?? 640;
          final previewHeight = previewSize?.width.toInt() ?? 480;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Preview de cámara
              CameraPreviewWidget(
                controller: controller,
                frameStream: cameraState.frameStream,
              ),
              // Overlay de detecciones
              DetectionOverlayWidget(
                detections: state.detections,
                previewWidth: previewWidth,
                previewHeight: previewHeight,
              ),
              // Estadísticas de rendimiento
              DetectionStatsWidget(
                fps: state.fps,
                lastLatency: state.lastLatency,
                detections: state.detections,
              ),
            ],
          );
        } else {
          // Si la cámara no está streaming, mostrar mensaje
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Inicializando cámara...'),
              ],
            ),
          );
        }
      },
    );
  }

  /// Construye el estado de detección pausada
  Widget _buildPausedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Detección Pausada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Presiona el botón de play para reanudar'),
        ],
      ),
    );
  }
}

