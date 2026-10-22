// Servicio para procesar imágenes con el algoritmo SIFT.

import 'dart:io';

import 'package:opencv_dart/opencv.dart' as cv;

import 'object_region.dart';

/// Resultado del procesamiento SIFT.
class SiftResult {
  final cv.VecKeyPoint keypoints;
  final cv.Mat descriptors;
  final int width;
  final int height;

  SiftResult({
    required this.keypoints,
    required this.descriptors,
    required this.width,
    required this.height,
  });

  int get totalKeypoints => keypoints.length;

  void dispose() {
    keypoints.dispose();
    descriptors.dispose();
  }
}

/// Servicio de extracción de características SIFT.
class SiftService {
  /// Procesa una imagen y extrae características.
  SiftResult extractFeatures(File imageFile, {ObjectRegion? region}) {
    if (region != null && !region.isValid) {
      throw ArgumentError('Región del objeto inválida');
    }
    // Carga la imagen en escala de grises.
    final image = cv.imread(imageFile.path, flags: cv.IMREAD_GRAYSCALE);

    if (image.isEmpty) {
      image.dispose();
      throw Exception('No se pudo cargar la imagen: ${imageFile.path}');
    }

    try {
      final sift = cv.SIFT.create();
      try {
        final mask = region == null
            ? cv.Mat.empty()
            : cv.Mat.zeros(image.rows, image.cols, cv.MatType.CV_8UC1);
        try {
          if (region != null) {
            final left = (region.left * image.cols).floor();
            final top = (region.top * image.rows).floor();
            cv.rectangle(
              mask,
              cv.Rect(
                left,
                top,
                (region.right * image.cols).ceil() - left,
                (region.bottom * image.rows).ceil() - top,
              ),
              cv.Scalar.all(255),
              thickness: -1,
            );
          }
          final (keypoints, descriptors) = sift.detectAndCompute(image, mask);
          return SiftResult(
            keypoints: keypoints,
            descriptors: descriptors,
            width: image.cols,
            height: image.rows,
          );
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
