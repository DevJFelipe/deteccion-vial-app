/// Constantes específicas para la detección
/// 
/// Este archivo contiene las constantes relacionadas con el procesamiento
/// de detecciones, umbrales NMS, dimensiones del modelo y configuración
/// de preprocesamiento/post-procesamiento.
library;

/// Umbral de Intersection over Union (IoU) para Non-Maximum Suppression (NMS)
/// 
/// Valores entre 0.0 y 1.0. Valores más altos = menos detecciones superpuestas.
/// Este umbral determina cuándo dos detecciones se consideran la misma detección.
/// 
/// Valor recomendado: 0.45 (balance entre precisión y recall)
const double nmsThreshold = 0.45;

/// Umbral de confianza mínimo para considerar una detección válida
/// 
/// Valores entre 0.0 y 1.0. Valores más altos = menos falsos positivos.
/// Solo las detecciones con confianza mayor a este valor serán reportadas.
/// 
/// Valor recomendado: 0.5 (balance entre precisión y recall)
const double confidenceThreshold = 0.5;

/// Dimensiones esperadas del tensor de salida del modelo YOLOv8s
/// 
/// Formato: [batch_size, num_values_per_detection, num_detections]
/// - batch_size: 1 (una imagen a la vez)
/// - num_values_per_detection: 84 (4 bbox + 80 clases COCO)
/// - num_detections: 8400 (número de detecciones por imagen)
/// 
/// El modelo YOLOv8s puede tener diferentes tamaños de salida según la versión:
/// - [1, 84, 8400] para modelos estándar
/// - [1, 84, 6300] para algunos modelos optimizados
const int modelOutputBatchSize = 1;
const int modelOutputValuesPerDetection = 84; // 4 (bbox) + 80 (clases COCO)
const int modelOutputNumDetections = 8400;

/// Estructura de la salida del modelo YOLOv8s
/// 
/// Cada detección en el tensor de salida tiene el siguiente formato:
/// [x_center, y_center, width, height, objectness, class0_score, class1_score, ..., class79_score]
/// 
/// - x_center, y_center: coordenadas del centro del bounding box (normalizadas 0-1)
/// - width, height: ancho y alto del bounding box (normalizadas 0-1)
/// - objectness: probabilidad de que haya un objeto (0-1)
/// - class0_score ... class79_score: probabilidades de cada clase COCO (0-1)
/// 
/// La confianza final se calcula como: objectness * max(class_scores)
const int bboxXIndex = 0;
const int bboxYIndex = 1;
const int bboxWidthIndex = 2;
const int bboxHeightIndex = 3;
const int objectnessIndex = 4;
const int classScoresStartIndex = 5;
const int numCocoClasses = 80;

/// Tamaño esperado de entrada del modelo (640×640 píxeles)
/// 
/// El modelo YOLOv8s requiere imágenes de entrada de tamaño fijo 640×640.
/// Las imágenes deben ser redimensionadas a este tamaño antes de la inferencia.
const int modelInputSize = 640;
const int modelInputWidth = 640;
const int modelInputHeight = 640;

/// Rango de normalización para valores de píxeles
/// 
/// Los valores de píxeles deben estar normalizados en el rango [0, 1].
/// Para convertir de valores uint8 (0-255) a valores normalizados (0-1):
/// normalized_value = pixel_value / 255.0
const double pixelNormalizationMin = 0.0;
const double pixelNormalizationMax = 1.0;
const double pixelNormalizationDivisor = 255.0;

/// Mapeo de clases COCO a clases del proyecto
/// 
/// El modelo YOLOv8s está entrenado con el dataset COCO que tiene 80 clases.
/// Para este proyecto, solo nos interesan 2 clases específicas:
/// - 'hueco' (pothole)
/// - 'grieta' (crack)
/// 
/// NOTA: Este mapeo debe ser configurado según cómo se entrenó el modelo.
/// Si el modelo fue entrenado específicamente para detección vial, las clases
/// pueden estar en índices específicos. Si no, puede ser necesario usar un
/// modelo fine-tuned o mapear clases COCO genéricas a nuestras clases.
/// 
/// Por defecto, asumimos que:
/// - Clase 0 en el modelo mapea a 'hueco'
/// - Clase 1 en el modelo mapea a 'grieta'
/// 
/// Si el modelo es genérico COCO, puede ser necesario mapear clases específicas
/// de COCO (como 'road', 'pavement', etc.) a nuestras clases.
const Map<int, String> cocoClassToProjectClass = {
  0: 'hueco',
  1: 'grieta',
};

/// Clases del proyecto que queremos detectar
const List<String> projectClasses = ['hueco', 'grieta'];

/// Índices de las clases en la salida del modelo (si el modelo fue fine-tuned)
/// 
/// Si el modelo fue entrenado específicamente para este proyecto, estas clases
/// estarán en los primeros índices de la salida. Si no, usar el mapeo COCO.
const int classIndexHueco = 0;
const int classIndexGrieta = 1;

