// Servicio para procesar imágenes con el algoritmo SIFT.

import 'package:opencv_dart/opencv.dart' as cv;

/// Resultado del procesamiento SIFT.
class SiftResult {
  final cv.VecKeyPoint keypoints; // Lista de puntos clave detectados en la imagen.
  final cv.Mat descriptors;        // Matriz de descriptores asociados a los puntos clave.

  SiftResult({
    required this.keypoints,        // Inicializa la lista de puntos clave.
    required this.descriptors,      // Inicializa la matriz de descriptores.
  });

  int get totalKeypoints => keypoints.length; // Devuelve el número total de puntos clave detectados.

  void dispose() {
    keypoints.dispose();            // Libera los recursos asociados a los puntos clave.
    descriptors.dispose();      // Libera los recursos asociados a la matriz de descriptores.
  }
}

/// Servicio de extracción de características SIFT.
class SiftService {
  /// Procesa una imagen y extrae características.
  SiftResult procesarImagen(String imagePath) {

    // Carga la imagen en escala de grises.
    final image = cv.imread(
      imagePath,
      flags: cv.IMREAD_GRAYSCALE,
    );

    if (image.isEmpty) {
      image.dispose();
      throw Exception('No se pudo cargar la imagen: $imagePath');
    }

    final sift = cv.SIFT.create(); // Crea una instancia del detector SIFT.

    try {
      final (keypoints, descriptors) =
          sift.detectAndCompute(        // Detecta puntos clave y calcula descriptores.
        image,                          // Imagen de entrada.
        cv.Mat.empty(),                 // Máscara opcional (vacía en este caso).
      );

      return SiftResult(                // Devuelve el resultado del procesamiento SIFT.
        keypoints: keypoints,
        descriptors: descriptors,
      );
    } finally {                         // Asegura que los recursos se liberen después del procesamiento.
      sift.dispose();
      image.dispose();
    }
  }
}
