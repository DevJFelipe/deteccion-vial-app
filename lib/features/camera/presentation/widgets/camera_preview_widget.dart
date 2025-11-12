/// Widget para mostrar preview de cámara en tiempo real
/// 
/// Consume el stream de frames y los muestra visualmente,
/// incluyendo overlay con información del frame actual.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/camera_frame.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el preview de la cámara en tiempo real
/// 
/// Este widget consume el stream de frames y los convierte
/// a imágenes visuales. Muestra cada frame con un overlay
/// que incluye información como contador de frames, timestamp
/// y resolución.
class CameraPreviewWidget extends StatefulWidget {
  /// Stream de frames de la cámara
  /// 
  /// Este stream emite [CameraFrame] a medida que se capturan.
  final Stream<CameraFrame> frameStream;

  /// Constructor del CameraPreviewWidget
  /// 
  /// [frameStream] - Stream de frames para mostrar
  const CameraPreviewWidget({
    super.key,
    required this.frameStream,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  /// Contador de frames recibidos
  int _frameCount = 0;

  /// Frame actual para mostrar
  CameraFrame? _currentFrame;

  /// Error del stream si ocurre
  String? _streamError;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // StreamBuilder para consumir frames
          StreamBuilder<CameraFrame>(
            stream: widget.frameStream,
            builder: (context, snapshot) {
              // Manejar errores del stream
              if (snapshot.hasError) {
                _streamError = snapshot.error.toString();
                return _buildErrorWidget();
              }

              // Mostrar indicador de carga mientras no hay datos
              if (!snapshot.hasData) {
                return _buildLoadingWidget();
              }

              // Actualizar frame actual y contador
              final frame = snapshot.data!;
              _currentFrame = frame;
              _frameCount++;

              // Construir widget de imagen
              return _buildImageWidget(frame);
            },
          ),
          // Overlay de información
          if (_currentFrame != null) _buildInfoOverlay(),
        ],
      ),
    );
  }

  /// Construye el widget de imagen desde el frame
  /// 
  /// Convierte el Uint8List grayscale a una imagen RGB
  /// y la muestra usando Image.memory().
  Widget _buildImageWidget(CameraFrame frame) {
    try {
      // Convertir grayscale a RGB
      final rgbImage = _convertGrayscaleToRgb(frame);

      // Codificar a PNG para Image.memory
      final pngBytes = Uint8List.fromList(
        img.encodePng(rgbImage),
      );

      // Mostrar imagen
      return Image.memory(
        pngBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true, // Evitar parpadeo entre frames
      );
    } catch (e) {
      // Si hay error en la conversión, mostrar error
      return _buildErrorWidget(
        errorMessage: 'Error al procesar frame: ${e.toString()}',
      );
    }
  }

  /// Convierte datos grayscale a imagen RGB
  /// 
  /// Toma el Uint8List grayscale (plano Y de YUV420) y lo convierte
  /// a una imagen RGB usando el paquete `image`.
  img.Image _convertGrayscaleToRgb(CameraFrame frame) {
    // Crear imagen RGB directamente desde los bytes grayscale
    final rgbImage = img.Image(width: frame.width, height: frame.height);
    
    // Los bytes grayscale están en frame.image
    // Cada byte representa un píxel en escala de grises
    for (var i = 0; i < frame.image.length && i < frame.width * frame.height; i++) {
      final grayValue = frame.image[i];
      final x = i % frame.width;
      final y = i ~/ frame.width;
      
      // Crear color RGB con el mismo valor en los 3 canales (escala de grises)
      // Usar setPixelRgba que acepta valores individuales de R, G, B, A
      rgbImage.setPixelRgba(x, y, grayValue, grayValue, grayValue, 255);
    }

    return rgbImage;
  }

  /// Construye el overlay de información
  /// 
  /// Muestra contador de frames, timestamp y resolución
  /// en la esquina inferior izquierda.
  Widget _buildInfoOverlay() {
    if (_currentFrame == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm:ss.SSS');

    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Frames: $_frameCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${dateFormat.format(_currentFrame!.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resolución: ${_currentFrame!.width}×${_currentFrame!.height}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye widget de carga
  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Construye widget de error
  Widget _buildErrorWidget({String? errorMessage}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? _streamError ?? 'Error en el stream de frames',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

