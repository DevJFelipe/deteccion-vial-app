/// Utilidad para aplicar throttling a streams
/// 
/// Proporciona extensiones para limitar la frecuencia de emisión
/// de elementos en streams, útil para controlar FPS en captura de video
/// y evitar procesamiento excesivo de frames.
library;

import 'dart:async';

/// Extensión para aplicar throttling a streams
/// 
/// Permite limitar la frecuencia de emisión de elementos en un stream,
/// emitiendo solo elementos que cumplan con el intervalo de tiempo especificado.
/// 
/// Útil para:
/// - Controlar FPS en streams de video
/// - Reducir carga de procesamiento
/// - Mantener performance objetivo
extension StreamThrottle<T> on Stream<T> {
  /// Aplica throttling al stream con la duración especificada
  /// 
  /// Emite elementos solo si ha pasado la [duration] especificada desde
  /// la última emisión. Esto evita procesamiento excesivo manteniendo
  /// el orden de los elementos sin generar buffering innecesario.
  /// 
  /// **Funcionamiento:**
  /// - Rastrea el tiempo de la última emisión usando [DateTime.now()]
  /// - Filtra elementos que lleguen antes del intervalo especificado
  /// - Preserva el orden original de los elementos
  /// - No genera buffering: descarta elementos que lleguen muy rápido
  /// 
  /// [duration] - Intervalo mínimo entre emisiones
  /// 
  /// Retorna un nuevo [Stream<T>] con throttling aplicado
  /// 
  /// Ejemplo:
  /// ```dart
  /// final throttledStream = originalStream.throttle(Duration(milliseconds: 100));
  /// throttledStream.listen((data) {
  ///   // Procesar datos (máximo 10 veces por segundo)
  /// });
  /// ```
  Stream<T> throttle(Duration duration) {
    DateTime? lastEmissionTime;

    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) {
        final now = DateTime.now();

        // Si es el primer elemento o ha pasado el intervalo, emitir
        if (lastEmissionTime == null ||
            now.difference(lastEmissionTime!) >= duration) {
          lastEmissionTime = now;
          sink.add(data);
        }
        // Si no ha pasado el intervalo, descartar el elemento
        // (no hacer buffering para mantener latencia baja)
      },
    ));
  }

  /// Aplica throttling para mantener 15 FPS
  /// 
  /// Método de conveniencia que aplica throttling de 66 milisegundos
  /// (1000ms / 15 FPS = 66.67ms) para mantener una tasa de frames
  /// objetivo de 15 frames por segundo.
  /// 
  /// **Uso típico:**
  /// - Streams de video de cámara
  /// - Procesamiento de frames para inferencia ML
  /// - Visualización con FPS controlado
  /// 
  /// Retorna un nuevo [Stream<T>] limitado a ~15 FPS
  /// 
  /// Ejemplo:
  /// ```dart
  /// final frameStream = cameraStream.throttleTo15FPS();
  /// frameStream.listen((frame) {
  ///   // Procesar frame (máximo 15 por segundo)
  /// });
  /// ```
  Stream<T> throttleTo15FPS() {
    // 1000ms / 15 FPS = 66.67ms
    // Usar 66ms para mantener FPS objetivo
    return throttle(const Duration(milliseconds: 66));
  }
}

