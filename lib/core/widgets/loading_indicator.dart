/// Widget personalizado para mostrar indicadores de carga
/// 
/// Proporciona un widget reutilizable para mostrar estados de carga
/// con un mensaje opcional y usando los colores del tema de la aplicación.
library;

import 'package:flutter/material.dart';

/// Widget que muestra un indicador de carga circular con un mensaje opcional
/// 
/// Este widget utiliza el CircularProgressIndicator de Flutter y aplica
/// los colores del tema actual de la aplicación.
/// 
/// Ejemplo:
/// ```dart
/// LoadingIndicator(message: 'Cargando detecciones...')
/// ```
class LoadingIndicator extends StatelessWidget {
  /// Mensaje de carga a mostrar debajo del indicador
  final String? message;

  /// Tamaño del indicador de carga
  final double? size;

  /// Color del indicador (opcional, usa el color primario del tema por defecto)
  final Color? color;

  /// Constructor del LoadingIndicator
  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              strokeWidth: 3,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget que muestra un indicador de carga en un contenedor con fondo
/// 
/// Útil para mostrar estados de carga en pantallas completas o secciones
/// específicas de la UI.
class LoadingContainer extends StatelessWidget {
  /// Mensaje de carga a mostrar
  final String? message;

  /// Color de fondo del contenedor
  final Color? backgroundColor;

  /// Constructor del LoadingContainer
  const LoadingContainer({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      color: bgColor,
      child: LoadingIndicator(message: message),
    );
  }
}

