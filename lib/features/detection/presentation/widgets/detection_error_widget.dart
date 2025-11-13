/// Widget para mostrar errores del sistema de detección
/// 
/// Muestra errores de forma amigable con opciones para reintentar
/// o volver atrás, sin mostrar stack traces técnicos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/detection_bloc.dart';
import '../bloc/detection_event.dart';

/// Widget que muestra errores de forma amigable
/// 
/// Muestra un ícono de error, título, mensaje descriptivo y botones
/// para reintentar o volver atrás. No muestra stack traces técnicos.
class DetectionErrorWidget extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String errorMessage;

  /// Constructor del DetectionErrorWidget
  /// 
  /// [errorMessage] - Mensaje descriptivo del error
  const DetectionErrorWidget({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de error
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              'Error en Detección',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Mensaje de error
            Text(
              errorMessage,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón Reintentar
                ElevatedButton.icon(
                  onPressed: () {
                    // Disparar LoadModelEvent para reintentar
                    context.read<DetectionBloc>().add(
                          const LoadModelEvent(
                            modelPath: 'assets/models/yolov8s_int8.tflite',
                          ),
                        );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Botón Volver
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

