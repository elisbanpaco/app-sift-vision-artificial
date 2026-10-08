import 'dart:io';

import 'package:opencv_dart/opencv.dart' as cv;

import 'dataset_service.dart';
import 'sift_service.dart';

class MatchResult {
  final DatasetObject object;
  final int matches;
  final int inliers;

  MatchResult({
    required this.object,
    required this.matches,
    required this.inliers,
  });
}

class MatchingService {
  final SiftService _sift = SiftService();

  /// Busca el objeto que mejor coincide con la imagen.
  Future<MatchResult?> recognize(File image) async {
    final objects = await DatasetService().getObjects();
    final query = _sift.extractFeatures(image);

    MatchResult? best;

    try {
      if (query.descriptors.isEmpty) return null;

      for (final object in objects) {
        for (final path in object.images) {
          final reference = _sift.extractFeatures(File(path));

          try {
            if (reference.descriptors.isEmpty) continue;

            final matcher = cv.BFMatcher.create(
              type: cv.NORM_L2,
            );

            try {
              final pairs = matcher.knnMatch(
                query.descriptors,
                reference.descriptors,
                2,
              );

              final good = <cv.DMatch>[];

              for (final pair in pairs) {
                if (pair.length < 2) continue;

                if (pair[0].distance <
                    0.75 * pair[1].distance) {
                  good.add(pair[0]);
                }
              }

              if (good.length < 8) continue;

              final srcPoints = <cv.Point2f>[];
              final dstPoints = <cv.Point2f>[];

              for (final match in good) {
                srcPoints.add(
                  cv.Point2f(
                    query.keypoints[match.queryIdx].x,
                    query.keypoints[match.queryIdx].y,
                  ),
                );
                dstPoints.add(
                  cv.Point2f(
                    reference.keypoints[match.trainIdx].x,
                    reference.keypoints[match.trainIdx].y,
                  ),
                );
              }

              final src = cv.VecPoint2f.fromList(srcPoints);
              final dst = cv.VecPoint2f.fromList(dstPoints);

              try {
                final mask = cv.Mat.empty();
                final homography = cv.findHomography(
                  cv.InputArray.fromVec(src),
                  cv.InputArray.fromVec(dst),
                  method: cv.RANSAC,
                  ransacReprojThreshold: 3.0,
                  mask: mask,
                );

                try {
                  if (homography.isEmpty) continue;

                  int inliers = 0;

                  for (int i = 0; i < good.length; i++) {
                    if (mask.at<int>(i, 0) != 0) {
                      inliers++;
                    }
                  }

                  if (inliers < 8) continue;

                  if (best == null || inliers > best.inliers) {
                    best = MatchResult(
                      object: object,
                      matches: good.length,
                      inliers: inliers,
                    );
                  }
                } finally {
                  homography.dispose();
                  mask.dispose();
                }
              } finally {
                src.dispose();
                dst.dispose();
              }
            } finally {
              matcher.dispose();
            }
          } finally {
            reference.dispose();
          }
        }
      }

      return best;
    } finally {
      query.dispose();
    }
  }
}
