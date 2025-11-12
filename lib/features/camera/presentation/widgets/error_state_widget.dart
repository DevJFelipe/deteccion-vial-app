/// Widget para mostrar estado de error de la cámara
/// 
/// Muestra un widget visual que indica que hubo un error
/// con la cámara, incluyendo un mensaje descriptivo y
/// opciones para reintentar o volver atrás.
library;

import 'package:flutter/material.dart';

/// Widget que muestra un estado de error de cámara
/// 
/// Este widget se muestra cuando ocurre un error durante
/// el ciclo de vida de la cámara. Proporciona opciones
/// para reintentar la operación o volver atrás.
class ErrorStateWidget extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String errorMessage;

  /// Callback opcional para reintentar la operación
  /// 
  /// Si se proporciona, se llamará cuando el usuario
  /// presione el botón "Reintentar".
  final VoidCallback? onRetry;

  /// Callback opcional para volver atrás
  /// 
  /// Si se proporciona, se llamará cuando el usuario
  /// presione el botón "Volver atrás".
  final VoidCallback? onBack;

  /// Constructor del ErrorStateWidget
  /// 
  /// [errorMessage] - Mensaje descriptivo del error
  /// [onRetry] - Callback para reintentar (opcional)
  /// [onBack] - Callback para volver atrás (opcional)
  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de error
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                'Error de Cámara',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
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
                  // Botón Volver atrás
                  if (onBack != null)
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver atrás'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                    ),
                  if (onBack != null && onRetry != null)
                    const SizedBox(width: 16),
                  // Botón Reintentar
                  if (onRetry != null)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

