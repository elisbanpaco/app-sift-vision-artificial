import 'dart:io';

import 'package:opencv_dart/opencv.dart' as cv;

import 'dataset_service.dart';
import 'object_region.dart';
import 'sift_service.dart';

typedef ImagePoint = ({double x, double y});

class MatchResult {
  final DatasetObject object;
  final int matches;
  final int inliers;

  /// Esquinas del objeto proyectadas, normalizadas respecto de la consulta.
  final List<ImagePoint> outline;

  MatchResult({
    required this.object,
    required this.matches,
    required this.inliers,
    required this.outline,
  });
}

/// Proyecta el rectángulo de referencia con una homografía 3x3.
/// Rechaza transformaciones degeneradas, cruzadas o fuera de la escena.
List<ImagePoint>? projectObjectRegion(
  ObjectRegion region,
  List<double> h,
  int referenceWidth,
  int referenceHeight,
  int queryWidth,
  int queryHeight,
) {
  if (!region.isValid ||
      h.length != 9 ||
      [
        referenceWidth,
        referenceHeight,
        queryWidth,
        queryHeight,
      ].any((v) => v <= 0)) {
    return null;
  }
  final corners = [
    (x: region.left, y: region.top),
    (x: region.right, y: region.top),
    (x: region.right, y: region.bottom),
    (x: region.left, y: region.bottom),
  ];
  final result = <ImagePoint>[];
  double? denominatorSign;
  for (final point in corners) {
    final x = point.x * referenceWidth;
    final y = point.y * referenceHeight;
    final w = h[6] * x + h[7] * y + h[8];
    if (!w.isFinite || w.abs() < 1e-9) return null;
    denominatorSign ??= w.sign;
    if (w.sign != denominatorSign) return null;
    final px = (h[0] * x + h[1] * y + h[2]) / w / queryWidth;
    final py = (h[3] * x + h[4] * y + h[5]) / w / queryHeight;
    if (!px.isFinite || !py.isFinite || px.abs() > 4 || py.abs() > 4) {
      return null;
    }
    result.add((x: px, y: py));
  }
  double area = 0;
  double? turn;
  for (int i = 0; i < 4; i++) {
    final a = result[i], b = result[(i + 1) % 4], c = result[(i + 2) % 4];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cross.abs() < 1e-9) return null;
    turn ??= cross.sign;
    if (cross.sign != turn) return null;
    area += a.x * b.y - b.x * a.y;
  }
  // Una homografía no debe invertir el orden de las esquinas del objeto.
  if (area < 0.0002 || area > 8) return null;
  if (result.every((p) => p.x < 0) ||
      result.every((p) => p.x > 1) ||
      result.every((p) => p.y < 0) ||
      result.every((p) => p.y > 1)) {
    return null;
  }
  return result;
}

class MatchingService {
  final SiftService _sift = SiftService();
  final DatasetService _dataset;

  MatchingService({DatasetService? dataset})
    : _dataset = dataset ?? DatasetService();

  Future<MatchResult?> recognize(File image) async {
    final objects = await _dataset.getObjects();
    if (!objects.any((object) => object.regions.isNotEmpty)) {
      throw StateError(
        'Primero abre «Ver dataset» y marca el objeto en al menos una imagen.',
      );
    }
    final query = _sift.extractFeatures(image);
    MatchResult? best;
    try {
      if (query.descriptors.rows < 2) return null;
      final matcher = cv.BFMatcher.create(type: cv.NORM_L2);
      try {
        for (final object in objects) {
          for (final path in object.images) {
            final region = object.regions[path];
            if (region == null || !region.isValid) continue;
            final reference = _sift.extractFeatures(File(path), region: region);
            try {
              if (reference.descriptors.rows < 8) continue;
              final pairs = matcher.knnMatch(
                reference.descriptors,
                query.descriptors,
                2,
              );
              final good = <({int source, int target})>[];
              final targets = <int>{};
              try {
                for (final pair in pairs) {
                  if (pair.length < 2) continue;
                  final first = pair[0], second = pair[1];
                  try {
                    if (first.distance < 0.75 * second.distance &&
                        targets.add(first.trainIdx)) {
                      good.add((
                        source: first.queryIdx,
                        target: first.trainIdx,
                      ));
                    }
                  } finally {
                    first.dispose();
                    second.dispose();
                  }
                }
              } finally {
                pairs.dispose();
              }
              if (good.length < 8) continue;
              final srcPoints = <cv.Point2f>[], dstPoints = <cv.Point2f>[];
              for (final match in good) {
                final source = reference.keypoints[match.source];
                final target = query.keypoints[match.target];
                try {
                  srcPoints.add(cv.Point2f(source.x, source.y));
                  dstPoints.add(cv.Point2f(target.x, target.y));
                } finally {
                  source.dispose();
                  target.dispose();
                }
              }
              final src = cv.VecPoint2f.fromList(srcPoints);
              final dst = cv.VecPoint2f.fromList(dstPoints);
              for (final point in [...srcPoints, ...dstPoints]) {
                point.dispose();
              }
              final mask = cv.Mat.empty();
              try {
                final homography = cv.findHomography(
                  cv.InputArray.fromVec(src),
                  cv.InputArray.fromVec(dst),
                  method: cv.RANSAC,
                  ransacReprojThreshold: 3,
                  mask: mask,
                );
                try {
                  if (homography.isEmpty || mask.isEmpty) continue;
                  int inliers = 0;
                  for (int i = 0; i < good.length; i++) {
                    if (mask.at<int>(i, 0) != 0) inliers++;
                  }
                  if (inliers < 8 || inliers / good.length < 0.45) continue;
                  final outline = projectObjectRegion(
                    region,
                    List.generate(
                      9,
                      (i) => homography.at<double>(i ~/ 3, i % 3),
                    ),
                    reference.width,
                    reference.height,
                    query.width,
                    query.height,
                  );
                  if (outline == null) continue;
                  if (best == null || inliers > best.inliers) {
                    best = MatchResult(
                      object: object,
                      matches: good.length,
                      inliers: inliers,
                      outline: outline,
                    );
                  }
                } finally {
                  homography.dispose();
                }
              } finally {
                mask.dispose();
                src.dispose();
                dst.dispose();
              }
            } finally {
              reference.dispose();
            }
          }
        }
      } finally {
        matcher.dispose();
      }
      return best;
    } finally {
      query.dispose();
    }
  }
}
