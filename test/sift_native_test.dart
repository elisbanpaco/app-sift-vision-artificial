import 'dart:io';
import 'dart:math';

import 'package:app_sift_vision_artificial/services/sift_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv.dart' as cv;

void main() {
  test('Los módulos nativos ejecutan SIFT, BFMatcher y homografía', () async {
    final directory = await Directory.systemTemp.createTemp('sift_test_');
    try {
      // Textura reproducible, sin depender de fotos privadas ni de la cámara.
      final random = Random(42);
      final pixels = List<int>.generate(256 * 256, (_) => random.nextInt(256));
      final file = File('${directory.path}/texture.pgm');
      await file.writeAsBytes([...('P5\n256 256\n255\n'.codeUnits), ...pixels]);
      final features = SiftService().extractFeatures(file);
      try {
        expect(features.totalKeypoints, greaterThan(8));
        expect(features.descriptors.cols, 128);
        final matcher = cv.BFMatcher.create(type: cv.NORM_L2);
        try {
          final pairs = matcher.knnMatch(
            features.descriptors,
            features.descriptors,
            2,
          );
          try {
            expect(pairs.length, features.totalKeypoints);
          } finally {
            pairs.dispose();
          }
        } finally {
          matcher.dispose();
        }
      } finally {
        features.dispose();
      }

      final points = cv.VecPoint2f.fromList([
        cv.Point2f(0, 0),
        cv.Point2f(100, 0),
        cv.Point2f(100, 100),
        cv.Point2f(0, 100),
      ]);
      final mask = cv.Mat.empty();
      try {
        final homography = cv.findHomography(
          cv.InputArray.fromVec(points),
          cv.InputArray.fromVec(points),
          method: cv.RANSAC,
          mask: mask,
        );
        try {
          expect(homography.isEmpty, isFalse);
          expect(mask.rows, 4);
        } finally {
          homography.dispose();
        }
      } finally {
        mask.dispose();
        points.dispose();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
