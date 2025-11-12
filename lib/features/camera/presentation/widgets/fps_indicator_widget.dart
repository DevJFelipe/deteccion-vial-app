/// Widget que muestra un indicador visual del FPS (Frames Per Second)
/// 
/// Calcula y muestra el FPS actual basado en el stream de frames,
/// con colores que indican el rendimiento (verde/amarillo/rojo).
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/camera_frame.dart';

/// Widget que muestra un indicador de FPS en tiempo real
/// 
/// Este widget escucha el stream de frames y calcula el FPS
/// contando los frames recibidos en una ventana de 1 segundo.
/// Muestra el FPS con un color que indica el rendimiento:
/// - Verde: ≥15 FPS (aceptable)
/// - Amarillo: 10-14 FPS (bajo)
/// - Rojo: <10 FPS (crítico)
class FpsIndicatorWidget extends StatefulWidget {
  /// Stream de frames de la cámara
  /// 
  /// Este stream emite [CameraFrame] a medida que se capturan.
  /// El widget cuenta los frames para calcular el FPS.
  final Stream<CameraFrame> frameStream;

  /// Constructor del FpsIndicatorWidget
  /// 
  /// [frameStream] - Stream de frames para calcular FPS
  const FpsIndicatorWidget({
    super.key,
    required this.frameStream,
  });

  @override
  State<FpsIndicatorWidget> createState() => _FpsIndicatorWidgetState();
}

class _FpsIndicatorWidgetState extends State<FpsIndicatorWidget> {
  /// Contador de frames recibidos en el último segundo
  int _frameCount = 0;

  /// FPS actual calculado
  int _currentFps = 0;

  /// Suscripción al stream de frames
  StreamSubscription<CameraFrame>? _subscription;

  /// Timer para calcular FPS cada segundo
  Timer? _fpsTimer;

  @override
  void initState() {
    super.initState();
    _startFpsCalculation();
  }

  /// Inicia el cálculo de FPS
  /// 
  /// Configura un timer que cada segundo calcula el FPS
  /// basado en el número de frames recibidos.
  void _startFpsCalculation() {
    // Suscribirse al stream de frames
    _subscription = widget.frameStream.listen(
      (_) {
        // Incrementar contador cada vez que se recibe un frame
        setState(() {
          _frameCount++;
        });
      },
      onError: (error) {
        // En caso de error, mostrar 0 FPS
        setState(() {
          _currentFps = 0;
        });
      },
    );

    // Timer que calcula FPS cada segundo
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentFps = _frameCount;
          _frameCount = 0; // Resetear contador para el próximo segundo
        });
      }
    });
  }

  /// Obtiene el color según el FPS
  /// 
  /// - Verde: ≥15 FPS (aceptable)
  /// - Amarillo: 10-14 FPS (bajo)
  /// - Rojo: <10 FPS (crítico)
  Color _getFpsColor() {
    if (_currentFps >= 15) {
      return Colors.green;
    } else if (_currentFps >= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    // Cancelar suscripción y timer al destruir el widget
    _subscription?.cancel();
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6), // Fondo semi-transparente
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de color
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getFpsColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Texto de FPS
          Text(
            '$_currentFps FPS',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

