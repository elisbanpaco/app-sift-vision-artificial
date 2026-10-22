// Servicio para procesar imágenes con el algoritmo SIFT.

import 'dart:io';

import 'package:opencv_dart/opencv.dart' as cv;

/// Resultado del procesamiento SIFT.
class SiftResult {
  final cv.VecKeyPoint keypoints;
  final cv.Mat descriptors;

  SiftResult({required this.keypoints, required this.descriptors});

  int get totalKeypoints => keypoints.length;

  void dispose() {
    keypoints.dispose();
    descriptors.dispose();
  }
}

/// Servicio de extracción de características SIFT.
class SiftService {
  /// Procesa una imagen y extrae características.
  SiftResult extractFeatures(File imageFile) {
    // Carga la imagen en escala de grises.
    final image = cv.imread(imageFile.path, flags: cv.IMREAD_GRAYSCALE);

    if (image.isEmpty) {
      image.dispose();
      throw Exception('No se pudo cargar la imagen: ${imageFile.path}');
    }

    try {
      final sift = cv.SIFT.create();
      try {
        final mask = cv.Mat.empty();
        try {
          final (keypoints, descriptors) = sift.detectAndCompute(image, mask);
          return SiftResult(keypoints: keypoints, descriptors: descriptors);
        } finally {
          mask.dispose();
        }
      } finally {
        sift.dispose();
      }
    } finally {
      // Asegura que los recursos se liberen después del procesamiento.
      image.dispose();
    }
  }

  /// Extrae características de todas las imágenes
  /// registradas para un objeto.
  List<SiftResult> extractDatasetFeatures(List<String> imagePaths) {
    final results = <SiftResult>[];

    try {
      for (final path in imagePaths) {
        final result = extractFeatures(File(path));
        results.add(result);
      }

      return results;
    } catch (_) {
      for (final result in results) {
        result.dispose();
      }
      rethrow;
    }
  }
}
