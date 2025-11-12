/// Pantalla principal para mostrar preview de cámara
/// 
/// Gestiona el ciclo de vida completo de la cámara y muestra
/// el preview en tiempo real con información de FPS y estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera_bloc.dart';
import '../bloc/camera_event.dart';
import '../bloc/camera_state.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/fps_indicator_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/permission_dialog_widget.dart';
import '../../../../injection.dart';

/// Pantalla principal para mostrar preview de cámara
/// 
/// Esta pantalla gestiona el ciclo de vida completo de la cámara:
/// - Inicializa la cámara al montarse
/// - Muestra preview en tiempo real cuando está streaming
/// - Maneja errores y permisos
/// - Libera recursos al desmontarse
class CameraScreen extends StatefulWidget {
  /// Constructor del CameraScreen
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  /// BLoC de cámara
  /// 
  /// Se obtiene desde GetIt y se proporciona a los widgets hijos
  /// mediante BlocProvider.
  late final CameraBloc _cameraBloc;

  @override
  void initState() {
    super.initState();
    // Obtener BLoC desde GetIt
    _cameraBloc = getIt<CameraBloc>();
    // Inicializar cámara al montar la pantalla
    _cameraBloc.add(const InitializeCameraEvent());
  }

  @override
  void dispose() {
    // Liberar recursos de cámara al desmontar
    _cameraBloc.add(const DisposeCameraEvent());
    // Cerrar el BLoC
    _cameraBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CameraBloc>.value(
      value: _cameraBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detección Vial - IA'),
          actions: [
            // Indicador de FPS (solo cuando está streaming)
            BlocBuilder<CameraBloc, CameraState>(
              builder: (context, state) {
                if (state is CameraStreaming) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FpsIndicatorWidget(
                      frameStream: state.frameStream,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<CameraBloc, CameraState>(
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

  /// Construye el estado de streaming
  Widget _buildStreamingState(CameraStreaming state) {
    return CameraPreviewWidget(
      controller: state.controller,
      frameStream: state.frameStream,
    );
  }

  /// Construye el estado de error
  Widget _buildErrorState(CameraError state) {
    return ErrorStateWidget(
      errorMessage: state.errorMessage,
      onRetry: () {
        // Reintentar inicialización
        _cameraBloc.add(const InitializeCameraEvent());
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

