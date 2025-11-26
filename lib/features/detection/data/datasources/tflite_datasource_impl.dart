/// Implementación concreta de TfliteDatasource usando tflite_flutter
/// 
/// Implementa la interfaz TfliteDatasource usando el plugin tflite_flutter
/// para cargar modelos TFLite y ejecutar inferencias sobre imágenes.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../../core/error/exceptions.dart';
import 'tflite_datasource.dart';
import '../models/detection_constants.dart'
    show modelInputSize, pixelNormalizationDivisor;

/// Implementación concreta de TfliteDatasource
/// 
/// Usa el plugin tflite_flutter para:
/// - Cargar modelos TFLite desde assets
/// - Preprocesar imágenes RGB (redimensionar, normalizar)
/// - Ejecutar inferencias
/// - Retornar salida raw del modelo
class TfliteDatasourceImpl implements TfliteDatasource {
  /// Intérprete TFLite para ejecutar el modelo
  Interpreter? _interpreter;

  /// Indica si el modelo está cargado
  bool _isModelLoaded = false;

  /// Tamaño de entrada del modelo (640×640 para YOLOv8)
  static const int _modelInputSize = modelInputSize;
  
  /// Forma del tensor de salida (se determina al cargar el modelo)
  List<int>? _outputShape;
  
  /// Buffer de entrada reutilizable para evitar allocaciones
  List<List<List<List<double>>>>? _inputBuffer;

  @override
  Future<void> loadModel(String modelPath) async {
    try {
      // Copiar el modelo desde assets al sistema de archivos del dispositivo
      final modelFile = await _copyAssetToFile(modelPath);
      
      // Configurar opciones del intérprete para mejor rendimiento
      final options = InterpreterOptions()
        ..threads = 4;  // Usar 4 threads para paralelismo
      
      // Intentar usar NNAPI para Android (aceleración de hardware)
      try {
        options.useNnApiForAndroid = true;
        // ignore: avoid_print
        print('NNAPI habilitado para aceleración de hardware');
      } catch (e) {
        // NNAPI no disponible, continuar sin aceleración
        // ignore: avoid_print
        print('NNAPI no disponible: $e');
      }
      
      // Cargar el modelo desde el archivo con opciones optimizadas
      _interpreter = Interpreter.fromFile(modelFile, options: options);

      // Validar que el modelo se cargó exitosamente
      if (_interpreter == null) {
        throw const ModelInferenceException(
          'Error al cargar el modelo: el intérprete es null',
        );
      }

      // Verificar que el modelo tiene la estructura esperada
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty) {
        throw const ModelInferenceException(
          'Error al cargar el modelo: no se encontraron tensores de entrada',
        );
      }

      if (outputTensors.isEmpty) {
        throw const ModelInferenceException(
          'Error al cargar el modelo: no se encontraron tensores de salida',
        );
      }

      // Guardar la forma del tensor de salida
      _outputShape = outputTensors[0].shape;

      // Pre-allocar buffer de entrada [1, 640, 640, 3]
      _inputBuffer = List.generate(
        1,
        (_) => List.generate(
          _modelInputSize,
          (_) => List.generate(
            _modelInputSize,
            (_) => List<double>.filled(3, 0.0),
          ),
        ),
      );

      // Log de información del modelo para debug
      // ignore: avoid_print
      print('=== MODELO CARGADO ===');
      // ignore: avoid_print
      print('Input shape: ${inputTensors[0].shape}');
      // ignore: avoid_print
      print('Input type: ${inputTensors[0].type}');
      // ignore: avoid_print
      print('Output shape: $_outputShape');
      // ignore: avoid_print
      print('Output type: ${outputTensors[0].type}');
      // ignore: avoid_print
      print('======================');

      // Marcar el modelo como cargado
      _isModelLoaded = true;
    } catch (e) {
      // Limpiar el intérprete si hubo un error
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;

      // Lanzar excepción con mensaje descriptivo
      if (e is ModelInferenceException) {
        rethrow;
      } else {
        throw ModelInferenceException(
          'Error al cargar el modelo desde $modelPath: $e',
        );
      }
    }
  }

  /// Copia un asset al sistema de archivos del dispositivo
  Future<File> _copyAssetToFile(String assetPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = assetPath.split('/').last;
      final filePath = '${appDir.path}/$fileName';
      final file = File(filePath);

      // Si el archivo ya existe y no está vacío, reutilizarlo
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          // ignore: avoid_print
          print('Modelo ya existe en: $filePath (${fileSize ~/ 1024 ~/ 1024} MB)');
          return file;
        }
      }

      // Cargar el asset desde el bundle
      // ignore: avoid_print
      print('Copiando modelo desde assets: $assetPath');
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Escribir al archivo
      await file.writeAsBytes(bytes, flush: true);
      
      // ignore: avoid_print
      print('Modelo copiado a: $filePath (${bytes.length ~/ 1024 ~/ 1024} MB)');
      
      return file;
    } catch (e) {
      throw ModelInferenceException(
        'Error al copiar el modelo al sistema de archivos: $e',
      );
    }
  }

  @override
  Future<List<dynamic>> runInference(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    // Validar que el modelo está cargado
    if (!_isModelLoaded || _interpreter == null) {
      throw const ModelInferenceException(
        'El modelo no está cargado. Debe llamar a loadModel() primero.',
      );
    }

    // Validar parámetros de entrada
    if (imageBytes.isEmpty) {
      throw const ModelInferenceException(
        'Los bytes de la imagen no pueden estar vacíos',
      );
    }

    if (width <= 0 || height <= 0) {
      throw ModelInferenceException(
        'Dimensiones de imagen inválidas: ${width}x$height',
      );
    }

    try {
      // Preprocesar la imagen RGB directamente (optimizado)
      _preprocessImageRGB(imageBytes, width, height);

      // Ejecutar inferencia
      final output = _runInferenceInternal();

      return output;
    } catch (e) {
      if (e is ModelInferenceException) {
        rethrow;
      } else {
        throw ModelInferenceException(
          'Error durante la inferencia: $e',
        );
      }
    }
  }

  /// Preprocesa una imagen RGB directamente al buffer de entrada
  /// 
  /// Esta versión optimizada:
  /// - Trabaja directamente con bytes RGB sin decodificar
  /// - Pre-calcula índices para evitar cálculos repetidos
  /// - Usa acceso directo al buffer para mejor rendimiento
  /// - Reutiliza el buffer de entrada pre-allocado
  void _preprocessImageRGB(
    Uint8List rgbBytes,
    int srcWidth,
    int srcHeight,
  ) {
    if (_inputBuffer == null) {
      throw const ModelInferenceException(
        'Buffer de entrada no inicializado',
      );
    }

    // Verificar si los bytes son RGB (3 bytes por pixel)
    final expectedRGBSize = srcWidth * srcHeight * 3;
    final isRGB = rgbBytes.length == expectedRGBSize;
    final bytesLength = rgbBytes.length;

    // Pre-calcular factores de escala como enteros para mayor velocidad
    final scaleXFixed = (srcWidth << 16) ~/ _modelInputSize;
    final scaleYFixed = (srcHeight << 16) ~/ _modelInputSize;
    
    // Límites pre-calculados
    final srcWidthMax = srcWidth - 1;
    final srcHeightMax = srcHeight - 1;

    // Normalización: [0, 255] -> [0, 1]
    const normFactor = 1.0 / pixelNormalizationDivisor;

    // Obtener referencia directa al buffer para evitar lookups
    final buffer = _inputBuffer![0];

    // Procesar cada fila
    for (var dstY = 0; dstY < _modelInputSize; dstY++) {
      // Pre-calcular coordenada Y fuente para toda la fila
      var srcY = (dstY * scaleYFixed) >> 16;
      if (srcY > srcHeightMax) srcY = srcHeightMax;
      
      final rowBuffer = buffer[dstY];
      final srcRowOffset = srcY * srcWidth;

      for (var dstX = 0; dstX < _modelInputSize; dstX++) {
        // Coordenada X fuente (nearest neighbor)
        var srcX = (dstX * scaleXFixed) >> 16;
        if (srcX > srcWidthMax) srcX = srcWidthMax;

        final pixelBuffer = rowBuffer[dstX];
        
        if (isRGB) {
          // Imagen RGB (formato estándar de Ultralytics/YOLOv8)
          final srcIndex = (srcRowOffset + srcX) * 3;
          pixelBuffer[0] = rgbBytes[srcIndex] * normFactor;     // R
          pixelBuffer[1] = rgbBytes[srcIndex + 1] * normFactor; // G
          pixelBuffer[2] = rgbBytes[srcIndex + 2] * normFactor; // B
        } else {
          // Fallback: asumir grayscale (plano Y)
          final srcIndex = srcRowOffset + srcX;
          if (srcIndex < bytesLength) {
            final gray = rgbBytes[srcIndex] * normFactor;
            pixelBuffer[0] = gray;
            pixelBuffer[1] = gray;
            pixelBuffer[2] = gray;
          } else {
            pixelBuffer[0] = 0.0;
            pixelBuffer[1] = 0.0;
            pixelBuffer[2] = 0.0;
          }
        }
      }
    }
  }

  /// Ejecuta la inferencia usando el buffer de entrada pre-llenado
  List<dynamic> _runInferenceInternal() {
    try {
      if (_outputShape == null || _inputBuffer == null) {
        throw const ModelInferenceException(
          'Error: buffers no inicializados',
        );
      }

      // Crear buffer de salida con la forma correcta
      final outputBuffer = _createOutputBuffer(_outputShape!);

      // Ejecutar la inferencia
      _interpreter!.run(_inputBuffer!, outputBuffer);

      // Log detallado de salida para debug
      _logOutputDebug(outputBuffer);

      return [outputBuffer];
    } catch (e) {
      throw ModelInferenceException(
        'Error durante la ejecución de la inferencia: $e',
      );
    }
  }

  /// Log de debug para analizar la salida del modelo
  void _logOutputDebug(dynamic outputBuffer) {
    try {
      // Solo logear cada 5 inferencias para no saturar
      _inferenceCount++;
      if (_inferenceCount % 5 != 1) return;

      // ignore: avoid_print
      print('=== DEBUG OUTPUT (inferencia #$_inferenceCount) ===');
      // ignore: avoid_print
      print('Output shape: $_outputShape');

      if (outputBuffer is List && outputBuffer.isNotEmpty) {
        final batch = outputBuffer[0];
        if (batch is List && batch.isNotEmpty) {
          // Forma [6, 8400]: batch[i] = fila i, batch[i][j] = valor de detección j
          // Buscar la detección con mayor confianza
          double maxScore = 0.0;
          int maxIdx = 0;
          
          // Los class scores están en las filas 4 y 5 (índices classScoresStartIndex)
          if (batch.length >= 6) {
            final class0Scores = batch[4] as List;
            final class1Scores = batch[5] as List;
            
            for (var i = 0; i < class0Scores.length && i < 8400; i++) {
              final s0 = (class0Scores[i] as num).toDouble();
              final s1 = (class1Scores[i] as num).toDouble();
              final maxS = s0 > s1 ? s0 : s1;
              if (maxS > maxScore) {
                maxScore = maxS;
                maxIdx = i;
              }
            }
            
            // Imprimir info de la detección con mayor score
            if (maxScore > 0) {
              final x = (batch[0] as List)[maxIdx];
              final y = (batch[1] as List)[maxIdx];
              final w = (batch[2] as List)[maxIdx];
              final h = (batch[3] as List)[maxIdx];
              final c0 = class0Scores[maxIdx];
              final c1 = class1Scores[maxIdx];
              
              // ignore: avoid_print
              print('Best detection #$maxIdx: '
                  'bbox=($x, $y, $w, $h), '
                  'scores=(hueco: $c0, grieta: $c1), '
                  'max=$maxScore');
            }
          }
          
          // ignore: avoid_print
          print('Max confidence found: ${maxScore.toStringAsFixed(4)}');
        }
      }
      // ignore: avoid_print
      print('======================');
    } catch (e) {
      // ignore: avoid_print
      print('Error en debug log: $e');
    }
  }

  int _inferenceCount = 0;

  /// Crea un buffer de salida con la forma correcta
  dynamic _createOutputBuffer(List<int> shape) {
    if (shape.length == 3) {
      // Forma [batch, values, detections] ej: [1, 6, 8400]
      return List.generate(
        shape[0],
        (_) => List.generate(
          shape[1],
          (_) => List<double>.filled(shape[2], 0.0),
        ),
      );
    } else if (shape.length == 2) {
      // Forma [values, detections]
      return List.generate(
        shape[0],
        (_) => List<double>.filled(shape[1], 0.0),
      );
    } else if (shape.length == 4) {
      // Forma [batch, height, width, channels]
      return List.generate(
        shape[0],
        (_) => List.generate(
          shape[1],
          (_) => List.generate(
            shape[2],
            (_) => List<double>.filled(shape[3], 0.0),
          ),
        ),
      );
    } else {
      // Forma 1D
      return List<double>.filled(shape.reduce((a, b) => a * b), 0.0);
    }
  }

  @override
  int getModelInputSize() => _modelInputSize;

  @override
  bool get isModelLoaded => _isModelLoaded;

  @override
  Future<void> dispose() async {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
      _inputBuffer = null;
    } catch (e) {
      throw ModelInferenceException(
        'Error al liberar recursos del modelo: $e',
      );
    }
  }
}
