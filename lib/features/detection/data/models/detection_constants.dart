/// Constantes específicas para la detección
/// 
/// Este archivo contiene las constantes relacionadas con el procesamiento
/// de detecciones, umbrales NMS, dimensiones del modelo y configuración
/// de preprocesamiento/post-procesamiento.
/// 
/// IMPORTANTE: Estas constantes están configuradas para un modelo YOLOv8s
/// fine-tuned con 2 clases (hueco, grieta).
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
/// Valor: 0.55 (reduce falsos positivos marginales de ~50%)
const double confidenceThreshold = 0.55;

/// Número de clases que el modelo puede detectar
/// 
/// Este modelo fue fine-tuned específicamente para detección vial con 2 clases:
/// - Clase 0: 'grieta' (crack)
/// - Clase 1: 'hueco' (pothole)
const int numClasses = 2;

/// Dimensiones esperadas del tensor de salida del modelo YOLOv8s
/// 
/// Formato YOLOv8: [batch_size, num_values_per_detection, num_detections]
/// - batch_size: 1 (una imagen a la vez)
/// - num_values_per_detection: 6 (4 bbox + 2 clases)
/// - num_detections: 8400 (número de detecciones por imagen en 640x640)
/// 
/// NOTA: YOLOv8 NO tiene objectness score separado como YOLOv5.
/// La confianza es directamente el max(class_scores).
const int modelOutputBatchSize = 1;
const int modelOutputValuesPerDetection = 6; // 4 (bbox) + 2 (clases)
const int modelOutputNumDetections = 8400;

/// Estructura de la salida del modelo YOLOv8s (fine-tuned 2 clases)
/// 
/// Cada detección en el tensor de salida tiene el siguiente formato:
/// [x_center, y_center, width, height, class0_score, class1_score]
/// 
/// - x_center, y_center: coordenadas del centro del bounding box (normalizadas 0-1)
/// - width, height: ancho y alto del bounding box (normalizadas 0-1)
/// - class0_score: probabilidad de 'grieta' (0-1)
/// - class1_score: probabilidad de 'hueco' (0-1)
/// 
/// La confianza final es: max(class0_score, class1_score)
/// La clase detectada es: argmax(class_scores)
const int bboxXIndex = 0;
const int bboxYIndex = 1;
const int bboxWidthIndex = 2;
const int bboxHeightIndex = 3;
const int classScoresStartIndex = 4;

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

/// Mapeo de índices de clase a nombres de clase del proyecto
/// 
/// El modelo fue entrenado específicamente para detección vial con 2 clases:
/// - Índice 0: 'grieta' (crack)
/// - Índice 1: 'hueco' (pothole)
const Map<int, String> classIndexToName = {
  0: 'grieta',
  1: 'hueco',
};

/// Clases del proyecto que el modelo detecta (orden según el modelo)
const List<String> projectClasses = ['grieta', 'hueco'];

/// Índices de las clases en la salida del modelo
const int classIndexGrieta = 0;
const int classIndexHueco = 1;

/// Colores para visualización de cada clase (en formato ARGB)
/// Usado para dibujar bounding boxes en el overlay
const Map<String, int> classColors = {
  'hueco': 0xFFFF5722,   // Deep Orange
  'grieta': 0xFF2196F3,  // Blue
};

/// Intervalo de throttling para procesamiento de frames (en milisegundos)
/// 
/// Limita la frecuencia de inferencias para evitar sobrecargar el dispositivo.
/// Un valor de 200ms = ~5 FPS de detección (suficiente para detección vial)
const int inferenceThrottleMs = 200;

// ============================================================================
// Filtros de tamaño de bounding box (MUY ESTRICTOS para reducir falsos positivos)
// ============================================================================

/// Área mínima de bounding box (como fracción de la imagen)
/// 
/// Los huecos y grietas reales ocupan al menos 1% de la imagen.
/// Detecciones más pequeñas son probablemente ruido.
const double minBboxArea = 0.01;

/// Área máxima de bounding box (como fracción de la imagen)
/// 
/// Los huecos y grietas reales NO ocupan más del 12% de la imagen.
/// Detecciones más grandes son claramente falsos positivos.
/// Un hueco típico ocupa 2-10% del área visible.
const double maxBboxArea = 0.12;

/// Dimensión mínima de bounding box (ancho o alto)
/// 
/// Los bounding boxes deben tener al menos 3% de ancho/alto.
const double minBboxDimension = 0.03;

/// Dimensión máxima de bounding box (ancho o alto)
/// 
/// Los bounding boxes no deben superar 40% de ancho/alto.
/// Un hueco que ocupa más del 40% de la pantalla es sospechoso.
const double maxBboxDimension = 0.40;

/// Aspect ratio mínimo (ancho/alto)
/// 
/// Los huecos y grietas tienen proporciones razonables.
/// Valor 0.3 = el ancho puede ser hasta 3x menor que el alto.
const double minAspectRatio = 0.3;

/// Aspect ratio máximo (ancho/alto)
/// 
/// Valor 3.5 = el ancho puede ser hasta 3.5x mayor que el alto.
/// Las grietas pueden ser alargadas pero no extremadamente.
const double maxAspectRatio = 3.5;

/// Número máximo de detecciones por frame
/// 
/// Limita las detecciones para evitar falsos positivos excesivos.
/// En una escena típica, no debería haber más de 3 huecos/grietas visibles.
const int maxDetectionsPerFrame = 3;

/// Umbral de IoU para NMS por clase (muy estricto)
/// 
/// Se usa para NMS dentro de cada clase. Valor más bajo = más agresivo.
const double nmsPerClassThreshold = 0.25;
