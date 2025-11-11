/// Widget para mostrar diálogos de error
/// 
/// Proporciona widgets y funciones para mostrar errores al usuario
/// de manera consistente en toda la aplicación.
library;

import 'package:flutter/material.dart';

/// Muestra un diálogo de error con un mensaje y opciones de acción
/// 
/// [context] - Contexto de BuildContext para mostrar el diálogo
/// [message] - Mensaje de error a mostrar
/// [title] - Título del diálogo (opcional, por defecto "Error")
/// [onRetry] - Callback opcional para reintentar la acción
/// 
/// Ejemplo:
/// ```dart
/// showErrorDialog(
///   context,
///   'No se pudo cargar el modelo',
///   onRetry: () => loadModel(),
/// );
/// ```
Future<void> showErrorDialog(
  BuildContext context,
  String message, {
  String? title,
  VoidCallback? onRetry,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return ErrorDialog(
        message: message,
        title: title,
        onRetry: onRetry,
      );
    },
  );
}

/// Widget de diálogo de error personalizado
/// 
/// Muestra un diálogo con un mensaje de error y botones para
/// cerrar o reintentar la acción.
class ErrorDialog extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String message;

  /// Título del diálogo
  final String? title;

  /// Callback opcional para reintentar la acción
  final VoidCallback? onRetry;

  /// Constructor del ErrorDialog
  const ErrorDialog({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? 'Error',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('Reintentar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

/// Muestra un diálogo de error simple sin opción de reintentar
/// 
/// [context] - Contexto de BuildContext para mostrar el diálogo
/// [message] - Mensaje de error a mostrar
/// [title] - Título del diálogo (opcional)
/// 
/// Ejemplo:
/// ```dart
/// showSimpleErrorDialog(context, 'Permiso denegado');
/// ```
Future<void> showSimpleErrorDialog(
  BuildContext context,
  String message, {
  String? title,
}) {
  return showErrorDialog(
    context,
    message,
    title: title,
  );
}

