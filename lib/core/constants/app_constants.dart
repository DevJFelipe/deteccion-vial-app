/// Constantes generales de la aplicación
/// 
/// Este archivo contiene todas las constantes de configuración
/// para el modelo de detección, cámara, GPS, base de datos y rendimiento.
library;

/// Ruta del modelo TensorFlow Lite cuantizado
const String modelPath = 'assets/models/yolov8n_int8.tflite';

/// Tamaño de entrada del modelo YOLOv8n (640x640 píxeles)
const int inputSize = 640;

/// Umbral de confianza mínimo para considerar una detección válida
/// Valores entre 0.0 y 1.0. Valores más altos = menos falsos positivos
const double confidenceThreshold = 0.5;

/// Umbral de Intersection over Union (IoU) para Non-Maximum Suppression (NMS)
/// Valores entre 0.0 y 1.0. Valores más altos = menos detecciones superpuestas
const double iouThreshold = 0.45;

/// Lista de clases de detección soportadas por el modelo
/// Orden debe coincidir con los índices de salida del modelo
const List<String> detectionClasses = ['hueco', 'grieta'];

/// FPS objetivo para la captura de video de la cámara
/// Balance entre rendimiento y calidad de detección
const int targetFPS = 15;

/// Precisión GPS mínima aceptable en metros
/// Detecciones con precisión mayor a este valor serán descartadas
const double gpsAccuracyThreshold = 10.0;

/// Nombre de la base de datos SQLite local
const String databaseName = 'deteccion_vial.db';

/// Versión de la base de datos
/// Incrementar este valor cuando se modifique el esquema
const int databaseVersion = 1;

/// Tiempo máximo permitido para la inferencia del modelo en milisegundos
/// Si la inferencia excede este tiempo, se considerará un error de rendimiento
const int maxInferenceTime = 200;

