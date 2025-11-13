/// Implementación concreta de TfliteDatasource usando tflite_flutter
/// 
/// Implementa la interfaz TfliteDatasource usando el plugin tflite_flutter
/// para cargar modelos TFLite y ejecutar inferencias sobre imágenes.
library;

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../../../core/error/exceptions.dart';
import 'tflite_datasource.dart';
import '../models/detection_constants.dart'
    show modelInputSize, pixelNormalizationDivisor;

/// Implementación concreta de TfliteDatasource
/// 
/// Usa el plugin tflite_flutter para:
/// - Cargar modelos TFLite desde assets
/// - Preprocesar imágenes (YUV420 → RGB, redimensionar, normalizar)
/// - Ejecutar inferencias
/// - Retornar salida raw del modelo
class TfliteDatasourceImpl implements TfliteDatasource {
  /// Intérprete TFLite para ejecutar el modelo
  Interpreter? _interpreter;

  /// Indica si el modelo está cargado
  bool _isModelLoaded = false;

  /// Tamaño de entrada del modelo (640×640 para YOLOv8)
  static const int _modelInputSize = modelInputSize;

  /// Número de canales de entrada (RGB = 3)
  static const int _inputChannels = 3;

  @override
  Future<void> loadModel(String modelPath) async {
    try {
      // Cargar el modelo usando tflite_flutter
      _interpreter = await Interpreter.fromAsset(modelPath);

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
      // Preprocesar la imagen
      final preprocessedImage = _preprocessImage(imageBytes, width, height);

      // Ejecutar inferencia
      final output = _runInferenceInternal(preprocessedImage);

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

  /// Preprocesa la imagen para la inferencia
  /// 
  /// Procesa la imagen de entrada:
  /// 1. Convierte YUV420 a RGB (si es necesario)
  /// 2. Redimensiona a 640×640
  /// 3. Normaliza valores [0-1]
  /// 
  /// Retorna un tensor de entrada preparado para el modelo.
  Float32List _preprocessImage(
    Uint8List imageBytes,
    int width,
    int height,
  ) {
    try {
      // Intentar decodificar la imagen
      // Si no se puede decodificar, asumimos que es YUV420 (plano Y)
      final image = img.decodeImage(imageBytes);

      img.Image processedImage;

      if (image != null) {
        // La imagen se pudo decodificar, redimensionarla
        processedImage = img.copyResize(
          image,
          width: _modelInputSize,
          height: _modelInputSize,
          interpolation: img.Interpolation.linear,
        );
      } else {
        // Asumimos que es YUV420 (plano Y) - crear imagen grayscale
        processedImage = _createImageFromYPlane(imageBytes, width, height);
      }

      // Convertir a tensor RGB normalizado [0-1]
      // Formato esperado: [1, height, width, channels] o [height, width, channels]
      final inputTensor = Float32List(_modelInputSize * _modelInputSize * _inputChannels);
      var index = 0;

      for (var y = 0; y < _modelInputSize; y++) {
        for (var x = 0; x < _modelInputSize; x++) {
          final pixel = processedImage.getPixel(x, y);
          
          // Extraer componentes RGB y normalizar [0-1]
          final r = pixel.r.toDouble() / pixelNormalizationDivisor;
          final g = pixel.g.toDouble() / pixelNormalizationDivisor;
          final b = pixel.b.toDouble() / pixelNormalizationDivisor;
          
          // Almacenar en orden RGB
          inputTensor[index++] = r;
          inputTensor[index++] = g;
          inputTensor[index++] = b;
        }
      }

      return inputTensor;
    } catch (e) {
      throw ModelInferenceException(
        'Error durante el preprocesamiento de la imagen: $e',
      );
    }
  }

  /// Crea una imagen desde el plano Y de YUV420
  /// 
  /// Convierte el plano Y (luminancia) a una imagen RGB
  /// donde R=G=B=Y (grayscale).
  img.Image _createImageFromYPlane(
    Uint8List yBytes,
    int width,
    int height,
  ) {
    try {
      // Crear imagen grayscale desde el plano Y
      final image = img.Image(width: width, height: height);

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final index = y * width + x;
          if (index < yBytes.length) {
            final gray = yBytes[index];
            image.setPixel(x, y, img.ColorRgb8(gray, gray, gray));
          }
        }
      }

      // Redimensionar a 640×640
      return img.copyResize(
        image,
        width: _modelInputSize,
        height: _modelInputSize,
        interpolation: img.Interpolation.linear,
      );
    } catch (e) {
      throw ModelInferenceException(
        'Error al crear imagen desde plano Y: $e',
      );
    }
  }

  /// Ejecuta la inferencia sobre una imagen preprocesada
  /// 
  /// Ejecuta el modelo TFLite sobre el tensor de entrada preprocesado
  /// y retorna la salida raw del modelo.
  List<dynamic> _runInferenceInternal(Float32List inputTensor) {
    try {
      // Obtener información sobre los tensores de entrada y salida
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        throw const ModelInferenceException(
          'Error: el modelo no tiene tensores de entrada o salida',
        );
      }

      final outputTensorInfo = outputTensors[0];

      // Crear el buffer de salida basado en la forma del tensor
      final outputShape = outputTensorInfo.shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      
      // Crear buffer de salida como lista plana de doubles
      // tflite_flutter espera un buffer plano para la salida
      final outputBuffer = List<double>.filled(outputSize, 0.0);

      // Ejecutar la inferencia
      // tflite_flutter espera los tensores como List o typed arrays
      // El método run(input, output) espera:
      // - input: Float32List o List<double>
      // - output: List<double> o List con la forma del tensor
      _interpreter!.run(inputTensor, outputBuffer);

      // Convertir la salida a la forma esperada
      return _reshapeOutput(outputBuffer, outputShape);
    } catch (e) {
      throw ModelInferenceException(
        'Error durante la ejecución de la inferencia: $e',
      );
    }
  }

  /// Reformatea la salida del modelo a la forma esperada
  /// 
  /// Convierte el buffer plano de salida a la forma del tensor
  /// especificada por outputShape.
  List<dynamic> _reshapeOutput(
    List<double> outputBuffer,
    List<int> outputShape,
  ) {
    try {
      // Si la salida tiene forma [1, 84, 8400], retornamos List<List<List<double>>>
      // Si tiene forma [84, 8400], retornamos List<List<double>>
      
      if (outputShape.length == 3) {
        // Forma [batch, height, width]
        final batchSize = outputShape[0];
        final height = outputShape[1];
        final width = outputShape[2];
        
        final result = <List<List<double>>>[];
        var index = 0;
        
        for (var b = 0; b < batchSize; b++) {
          final batch = <List<double>>[];
          for (var h = 0; h < height; h++) {
            final row = <double>[];
            for (var w = 0; w < width; w++) {
              if (index < outputBuffer.length) {
                row.add(outputBuffer[index++]);
              } else {
                row.add(0.0);
              }
            }
            batch.add(row);
          }
          result.add(batch);
        }
        
        return result;
      } else if (outputShape.length == 2) {
        // Forma [height, width]
        final height = outputShape[0];
        final width = outputShape[1];
        
        final result = <List<double>>[];
        var index = 0;
        
        for (var h = 0; h < height; h++) {
          final row = <double>[];
          for (var w = 0; w < width; w++) {
            if (index < outputBuffer.length) {
              row.add(outputBuffer[index++]);
            } else {
              row.add(0.0);
            }
          }
          result.add(row);
        }
        
        return result;
      } else {
        // Forma 1D o desconocida, retornar como está
        return outputBuffer;
      }
    } catch (e) {
      throw ModelInferenceException(
        'Error al reformatear la salida del modelo: $e',
      );
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
    } catch (e) {
      throw ModelInferenceException(
        'Error al liberar recursos del modelo: $e',
      );
    }
  }
}

