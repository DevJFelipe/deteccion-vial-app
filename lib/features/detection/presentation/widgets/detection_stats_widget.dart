/// Widget para mostrar métricas de rendimiento del sistema de detección
/// 
/// Muestra FPS, latencia, contador de detecciones y detecciones por clase
/// en tiempo real durante la detección activa.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/detection_result.dart';

/// Widget que muestra las estadísticas de detección
/// 
/// Muestra métricas de rendimiento en la esquina superior derecha
/// con fondo semi-transparente para legibilidad.
class DetectionStatsWidget extends StatelessWidget {
  /// FPS actuales
  final double fps;

  /// Latencia de la última inferencia en milisegundos
  final double lastLatency;

  /// Lista de detecciones actuales
  final List<DetectionResult> detections;

  /// Constructor del DetectionStatsWidget
  /// 
  /// [fps] - Frames por segundo actuales
  /// [lastLatency] - Latencia de la última inferencia en ms
  /// [detections] - Lista de detecciones actuales
  const DetectionStatsWidget({
    super.key,
    required this.fps,
    required this.lastLatency,
    required this.detections,
  });

  /// Obtiene el color del FPS según su valor
  /// 
  /// Verde: ≥15 FPS (bueno)
  /// Amarillo: 10-14 FPS (aceptable)
  /// Rojo: <10 FPS (lento)
  Color _getFpsColor(double fps) {
    if (fps >= 15) {
      return Colors.green;
    } else if (fps >= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Cuenta las detecciones por tipo
  /// 
  /// Retorna un mapa con el conteo de cada tipo de detección.
  Map<String, int> _countDetectionsByType() {
    final counts = <String, int>{'hueco': 0, 'grieta': 0};

    for (final detection in detections) {
      counts[detection.type] = (counts[detection.type] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countDetectionsByType();
    final fpsColor = _getFpsColor(fps);

    return Positioned(
      top: 8,
      right: 8,
      child: Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // FPS
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                  ),
                  Text(
                    fps.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: fpsColor,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Latencia
              Text(
                'Latencia: ${lastLatency.toStringAsFixed(0)}ms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 4),
              // Contador total
              Text(
                'Detecciones: ${detections.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
              ),
              // Detecciones por clase
              if (detections.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Huecos: ${counts['hueco']}, Grietas: ${counts['grieta']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

