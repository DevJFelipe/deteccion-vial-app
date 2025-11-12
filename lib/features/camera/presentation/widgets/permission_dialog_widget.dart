/// Widget para mostrar diálogo de solicitud de permisos de cámara
/// 
/// Proporciona un diálogo modal que solicita al usuario permiso
/// para acceder a la cámara, con diseño Material Design 3.
library;

import 'package:flutter/material.dart';

/// Muestra un diálogo modal para solicitar permiso de cámara
/// 
/// Este diálogo explica al usuario por qué la aplicación necesita
/// acceso a la cámara y le permite conceder o denegar el permiso.
/// 
/// [context] - Contexto de BuildContext para mostrar el diálogo
/// 
/// Retorna `true` si el usuario presiona "Permitir", `false` si presiona "Denegar"
/// 
/// Ejemplo:
/// ```dart
/// final granted = await showPermissionDialog(context);
/// if (granted) {
///   // Continuar con inicialización de cámara
/// }
/// ```
Future<bool> showPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // No se puede cerrar sin seleccionar botón
    builder: (BuildContext dialogContext) {
      return const PermissionDialogWidget();
    },
  ).then((value) => value ?? false); // Retornar false si se cierra sin seleccionar
}

/// Widget de diálogo para solicitar permiso de cámara
/// 
/// Muestra un diálogo con Material Design 3 que explica
/// por qué se necesita el permiso y permite al usuario
/// concederlo o denegarlo.
class PermissionDialogWidget extends StatelessWidget {
  /// Constructor del PermissionDialogWidget
  const PermissionDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.camera_alt,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: const Text(
        'Se necesita acceso a la cámara',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'La aplicación necesita acceso a la cámara para detectar '
        'anomalías viales (huecos y grietas) mediante visión artificial. '
        'El acceso a la cámara es esencial para el funcionamiento de la aplicación.',
      ),
      actions: [
        // Botón Denegar
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Denegar'),
        ),
        // Botón Permitir
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Permitir'),
        ),
      ],
    );
  }
}

