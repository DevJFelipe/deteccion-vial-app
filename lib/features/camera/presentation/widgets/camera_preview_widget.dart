/// Widget para mostrar preview de cámara en tiempo real
/// 
/// Usa el widget nativo CameraPreview del plugin camera para
/// visualización optimizada. El stream de frames se mantiene
/// solo para procesamiento ML y estadísticas, no para visualización.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera_package;
import '../../domain/entities/camera_frame.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el preview de la cámara en tiempo real
/// 
/// Este widget usa el widget nativo [CameraPreview] para visualización
/// optimizada sin conversión de frames. El stream de frames se usa
/// solo para contabilizar y mostrar información, no para renderizar.
class CameraPreviewWidget extends StatefulWidget {
  /// Controlador de cámara para preview nativo
  /// 
  /// Se usa con el widget [CameraPreview] nativo para visualización
  /// optimizada sin conversión de frames en el hilo principal.
  final camera_package.CameraController controller;

  /// Stream de frames de la cámara para estadísticas
  /// 
  /// Este stream se usa para contabilizar frames y calcular FPS,
  /// NO para visualización (que usa CameraPreview nativo).
  final Stream<CameraFrame>? frameStream;

  /// Constructor del CameraPreviewWidget
  /// 
  /// [controller] - Controlador de cámara para preview nativo (requerido)
  /// [frameStream] - Stream de frames para estadísticas (opcional)
  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.frameStream,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  /// Contador de frames recibidos
  int _frameCount = 0;

  /// Frame actual para mostrar información
  CameraFrame? _currentFrame;

  /// Suscripción al stream de frames para estadísticas
  StreamSubscription<CameraFrame>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    // Escuchar stream en background solo para estadísticas
    if (widget.frameStream != null) {
      _frameSubscription = widget.frameStream!.listen(
        (frame) {
          if (mounted) {
            setState(() {
              _currentFrame = frame;
              _frameCount++;
            });
          }
        },
        onError: (error) {
          // Ignorar errores del stream, no afectan el preview
        },
      );
    }
  }

  @override
  void dispose() {
    // Cancelar suscripción al stream
    _frameSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview nativo optimizado - no requiere conversión de frames
            _buildCameraPreview(),
            // Overlay de información
            if (_currentFrame != null) _buildInfoOverlay(),
          ],
        ),
      ),
    );
  }

  /// Construye el preview nativo de la cámara
  /// 
  /// Usa CameraPreview del plugin camera que renderiza nativamente
  /// sin conversión de frames, logrando 30+ FPS.
  Widget _buildCameraPreview() {
    // Verificar que el controller esté inicializado
    if (!widget.controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Usar CameraPreview nativo para renderizado optimizado
    return camera_package.CameraPreview(widget.controller);
  }

  /// Construye el overlay de información
  /// 
  /// Muestra contador de frames, timestamp y resolución
  /// en la esquina inferior izquierda.
  Widget _buildInfoOverlay() {
    if (_currentFrame == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm:ss.SSS');

    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Frames: $_frameCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${dateFormat.format(_currentFrame!.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resolución: ${_currentFrame!.width}×${_currentFrame!.height}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
