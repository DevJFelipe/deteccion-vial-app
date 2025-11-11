/// Constantes específicas del modelo YOLOv8n
/// 
/// Este archivo contiene las constantes relacionadas con la configuración
/// del modelo de detección, dimensiones, índices de salida y umbrales de post-procesamiento.
library;

import 'app_constants.dart';

/// Ancho de la imagen de entrada del modelo (píxeles)
const int modelInputWidth = 640;

/// Alto de la imagen de entrada del modelo (píxeles)
const int modelInputHeight = 640;

/// Número de canales de la imagen de entrada (RGB = 3)
const int modelInputChannels = 3;

/// Tamaño total del tensor de entrada (640 * 640 * 3)
const int modelInputSize = modelInputWidth * modelInputHeight * modelInputChannels;

/// Número de clases que el modelo puede detectar
const int numClasses = 2;

/// Índices de las clases en la salida del modelo
/// Debe coincidir con el orden en detectionClasses
const int classIndexHueco = 0;
const int classIndexGrieta = 1;

/// Número de valores por detección en la salida del modelo
/// Formato: [x_center, y_center, width, height, confidence, class_scores...]
const int valuesPerDetection = 4 + 1 + numClasses; // bbox (4) + conf (1) + clases (numClasses)

/// Umbral de confianza por clase (opcional, para filtrado adicional)
const Map<String, double> classConfidenceThresholds = {
  'hueco': confidenceThreshold,
  'grieta': confidenceThreshold,
};

/// Escala de normalización para las coordenadas del bounding box
/// Las coordenadas del modelo están normalizadas entre 0 y 1
const double bboxNormalizationScale = 1.0;

/// Valor máximo permitido para coordenadas normalizadas
const double maxNormalizedValue = 1.0;

/// Valor mínimo permitido para coordenadas normalizadas
const double minNormalizedValue = 0.0;

