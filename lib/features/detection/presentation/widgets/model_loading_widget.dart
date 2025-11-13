/// Widget para mostrar el estado de carga del modelo TFLite
/// 
/// Muestra un indicador visual durante la carga del modelo con
/// mensajes informativos para el usuario.
library;

import 'package:flutter/material.dart';

/// Widget que muestra el estado de carga del modelo
/// 
/// Muestra un indicador de progreso circular, texto informativo
/// y un ícono de modelo durante la carga del modelo TFLite.
/// La pantalla está bloqueada para evitar interacciones durante la carga.
class ModelLoadingWidget extends StatelessWidget {
  /// Constructor del ModelLoadingWidget
  const ModelLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de modelo (red neuronal o ML)
            Icon(
              Icons.psychology,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            // Indicador de progreso circular
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            // Texto principal
            Text(
              'Cargando modelo TFLite...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Sub-texto informativo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Por favor espere (primera vez puede tardar 10-15 segundos)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

