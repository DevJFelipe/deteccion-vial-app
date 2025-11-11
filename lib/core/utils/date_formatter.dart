/// Utilidades para formateo de fechas y timestamps
/// 
/// Proporciona funciones para convertir DateTime a diferentes formatos,
/// incluyendo ISO 8601, formato legible en español y cálculo de tiempo transcurrido.
library;

import 'package:intl/intl.dart';

/// Formatea un DateTime a formato ISO 8601
/// 
/// [dateTime] - Fecha y hora a formatear
/// 
/// Retorna una cadena en formato ISO 8601 (ej: "2024-01-15T10:30:00.000Z")
/// 
/// Ejemplo:
/// ```dart
/// final isoString = formatToISO8601(DateTime.now());
/// // "2024-01-15T10:30:00.000Z"
/// ```
String formatToISO8601(DateTime dateTime) {
  return dateTime.toIso8601String();
}

/// Convierte un DateTime a formato legible en español
/// 
/// [dateTime] - Fecha y hora a formatear
/// 
/// Retorna una cadena formateada en español (ej: "15 de enero de 2024, 10:30")
/// 
/// Ejemplo:
/// ```dart
/// final readable = formatToReadableSpanish(DateTime.now());
/// // "15 de enero de 2024, 10:30"
/// ```
String formatToReadableSpanish(DateTime dateTime) {
  final dateFormat = DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'es');
  return dateFormat.format(dateTime);
}

/// Calcula el tiempo transcurrido desde una fecha hasta ahora
/// 
/// [dateTime] - Fecha de referencia
/// 
/// Retorna una cadena descriptiva del tiempo transcurrido
/// (ej: "hace 5 minutos", "hace 2 horas", "hace 3 días")
/// 
/// Ejemplo:
/// ```dart
/// final elapsed = calculateElapsedTime(DateTime.now().subtract(Duration(hours: 2)));
/// // "hace 2 horas"
/// ```
String calculateElapsedTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return 'hace $years ${years == 1 ? 'año' : 'años'}';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return 'hace $months ${months == 1 ? 'mes' : 'meses'}';
  } else if (difference.inDays > 0) {
    return 'hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
  } else if (difference.inHours > 0) {
    return 'hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
  } else if (difference.inMinutes > 0) {
    return 'hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
  } else {
    return 'hace unos segundos';
  }
}

/// Formatea una fecha para mostrar solo la fecha (sin hora)
/// 
/// [dateTime] - Fecha a formatear
/// 
/// Retorna una cadena con formato de fecha (ej: "15/01/2024")
String formatDateOnly(DateTime dateTime) {
  final dateFormat = DateFormat('dd/MM/yyyy', 'es');
  return dateFormat.format(dateTime);
}

/// Formatea una fecha para mostrar solo la hora (sin fecha)
/// 
/// [dateTime] - Fecha a formatear
/// 
/// Retorna una cadena con formato de hora (ej: "10:30")
String formatTimeOnly(DateTime dateTime) {
  final timeFormat = DateFormat('HH:mm', 'es');
  return timeFormat.format(dateTime);
}

/// Formatea una fecha para mostrar fecha y hora en formato corto
/// 
/// [dateTime] - Fecha a formatear
/// 
/// Retorna una cadena con formato corto (ej: "15/01/2024 10:30")
String formatDateTimeShort(DateTime dateTime) {
  final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');
  return dateTimeFormat.format(dateTime);
}

