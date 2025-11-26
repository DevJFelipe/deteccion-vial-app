/// Pantalla principal para mostrar preview de cámara con detección de IA
/// 
/// Gestiona el ciclo de vida completo de la cámara y el modelo de detección,
/// mostrando el preview en tiempo real con bounding boxes de detecciones.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera_bloc.dart';
import '../bloc/camera_event.dart';
import '../bloc/camera_state.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/fps_indicator_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/permission_dialog_widget.dart';
import '../../../detection/presentation/bloc/detection_bloc.dart';
import '../../../detection/presentation/bloc/detection_event.dart';
import '../../../detection/presentation/bloc/detection_state.dart';
import '../../../detection/presentation/widgets/detection_overlay_widget.dart';
import '../../domain/entities/camera_frame.dart';
import '../../../../injection.dart';

/// Pantalla principal para mostrar preview de cámara con detección de IA
/// 
/// Esta pantalla gestiona:
/// - Ciclo de vida de la cámara (inicialización, streaming, liberación)
/// - Carga y ejecución del modelo de detección
/// - Visualización de bounding boxes sobre el preview
/// - Manejo de errores y permisos
class CameraScreen extends StatefulWidget {
  /// Constructor del CameraScreen
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  /// BLoC de cámara para gestionar el hardware
  late final CameraBloc _cameraBloc;
  
  /// BLoC de detección para gestionar el modelo de IA
  late final DetectionBloc _detectionBloc;
  
  /// Suscripción al stream de frames para procesamiento
  StreamSubscription<CameraFrame>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    // Obtener BLoCs desde GetIt
    _cameraBloc = getIt<CameraBloc>();
    _detectionBloc = getIt<DetectionBloc>();
    
    // Cargar el modelo de detección primero
    _detectionBloc.add(const LoadModelEvent());
    
    // Inicializar cámara al montar la pantalla
    _cameraBloc.add(const InitializeCameraEvent());
  }

  @override
  void dispose() {
    // Cancelar suscripción al stream de frames
    _frameSubscription?.cancel();
    
    // Liberar recursos de detección
    _detectionBloc.add(const DisposeModelEvent());
    _detectionBloc.close();
    
    // Liberar recursos de cámara
    _cameraBloc.add(const DisposeCameraEvent());
    _cameraBloc.close();
    
    super.dispose();
  }

  /// Inicia el procesamiento de frames para detección
  void _startFrameProcessing(Stream<CameraFrame> frameStream) {
    // Cancelar suscripción anterior si existe
    _frameSubscription?.cancel();
    
    // Suscribirse al stream de frames
    _frameSubscription = frameStream.listen(
      (frame) {
        // Enviar frame al BLoC de detección
        // El throttling se maneja internamente en el BLoC
        _detectionBloc.add(ProcessFrameEvent(frame: frame));
      },
      onError: (error) {
        // Ignorar errores del stream
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CameraBloc>.value(value: _cameraBloc),
        BlocProvider<DetectionBloc>.value(value: _detectionBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detección Vial - IA'),
          actions: [
            // Indicador de FPS (solo cuando está streaming)
            BlocBuilder<CameraBloc, CameraState>(
              builder: (context, state) {
                if (state is CameraStreaming) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FpsIndicatorWidget(
                      frameStream: state.frameStream,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Indicador de detección
            BlocBuilder<DetectionBloc, DetectionState>(
              builder: (context, state) {
                if (state is DetectionReady) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: DetectionStatsWidget(
                      inferenceTimeMs: state.inferenceTimeMs,
                      detectionCount: state.detections.length,
                      isProcessing: state.isProcessing,
                    ),
                  );
                } else if (state is DetectionModelLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<CameraBloc, CameraState>(
            listener: (context, state) {
              // Cuando la cámara empieza a transmitir, iniciar procesamiento
              if (state is CameraStreaming) {
                _startFrameProcessing(state.frameStream);
              }
            },
            builder: (context, state) {
              // Manejar diferentes estados
              if (state is CameraInitial || state is CameraLoading) {
                return _buildLoadingState();
              } else if (state is CameraStreaming) {
                return _buildStreamingState(state);
              } else if (state is CameraError) {
                return _buildErrorState(state);
              } else if (state is PermissionDenied) {
                return _buildPermissionDeniedState();
              } else if (state is CameraDisposed) {
                return _buildDisposedState();
              } else {
                // Estado desconocido, mostrar carga
                return _buildLoadingState();
              }
            },
          ),
        ),
        floatingActionButton: BlocBuilder<CameraBloc, CameraState>(
          builder: (context, state) {
            // Mostrar FAB solo si no está en estado disposed
            if (state is CameraDisposed) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton(
              onPressed: () {
                // Cerrar cámara y volver atrás
                _cameraBloc.add(const DisposeCameraEvent());
                Navigator.of(context).pop();
              },
              tooltip: 'Cerrar cámara',
              child: const Icon(Icons.close),
            );
          },
        ),
      ),
    );
  }

  /// Construye el estado de carga
  Widget _buildLoadingState() {
    return BlocBuilder<DetectionBloc, DetectionState>(
      builder: (context, detectionState) {
        String message = 'Inicializando cámara...';
        if (detectionState is DetectionModelLoading) {
          message = 'Cargando modelo de IA...';
        } else if (detectionState is DetectionError) {
          message = 'Inicializando cámara...\n(${detectionState.message})';
        }
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye el estado de streaming con overlay de detecciones
  Widget _buildStreamingState(CameraStreaming state) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview de cámara
        CameraPreviewWidget(
          controller: state.controller,
          frameStream: state.frameStream,
        ),
        // Overlay de detecciones
        BlocBuilder<DetectionBloc, DetectionState>(
          builder: (context, detectionState) {
            if (detectionState is DetectionReady && 
                detectionState.detections.isNotEmpty) {
              return DetectionOverlayWidget(
                detections: detectionState.detections,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Estado del modelo (si hay error)
        BlocBuilder<DetectionBloc, DetectionState>(
          builder: (context, detectionState) {
            if (detectionState is DetectionError) {
              return Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detectionState.message,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      if (detectionState.canRetry)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            _detectionBloc.add(const LoadModelEvent());
                          },
                        ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Construye el estado de error
  Widget _buildErrorState(CameraError state) {
    return ErrorStateWidget(
      errorMessage: state.errorMessage,
      onRetry: () {
        // Reintentar inicialización
        _cameraBloc.add(const InitializeCameraEvent());
        _detectionBloc.add(const LoadModelEvent());
      },
      onBack: () {
        // Volver atrás
        Navigator.of(context).pop();
      },
    );
  }

  /// Construye el estado de permiso denegado
  Widget _buildPermissionDeniedState() {
    // Mostrar diálogo de permiso automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showPermissionDialog(context).then((granted) {
        if (!mounted) return;
        if (granted) {
          // Si se otorga permiso, inicializar cámara
          _cameraBloc.add(const InitializeCameraEvent());
        } else {
          // Si se deniega, mostrar mensaje
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se necesita permiso de cámara para usar esta funcionalidad.',
              ),
            ),
          );
        }
      });
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Permiso de cámara requerido',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Por favor, concede el permiso de cámara para continuar.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Solicitar permiso nuevamente
              _cameraBloc.add(const RequestPermissionEvent());
            },
            icon: const Icon(Icons.settings),
            label: const Text('Solicitar permiso'),
          ),
        ],
      ),
    );
  }

  /// Construye el estado de cámara liberada
  Widget _buildDisposedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Cámara cerrada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Los recursos de la cámara han sido liberados.'),
        ],
      ),
    );
  }
}
