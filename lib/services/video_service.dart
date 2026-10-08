
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Servicio para extraer fotogramas de un video.
class VideoService {
  /// Extrae una imagen por segundo del video.
  ///
  /// Devuelve los archivos JPEG generados.
  Future<List<File>> extractFrames(File video) async {
    if (!await video.exists()) {
      throw ArgumentError('El video no existe');
    }

    final tempDir = await getTemporaryDirectory();

    final outputDir = Directory(
      '${tempDir.path}/frames_${const Uuid().v4()}',
    );

    await outputDir.create(recursive: true);

    final outputPath = '${outputDir.path}/frame_%04d.jpg';

    // Escapar rutas para FFmpeg.
    String quote(String path) {
      return "'${path.replaceAll("'", "'\\''")}'";
    }

    final command =
        '-y -i ${quote(video.path)} '
        '-vf "fps=1,scale=640:-2" '
        '-q:v 2 ${quote(outputPath)}';

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception(
          'No se pudieron extraer los fotogramas',
        );
      }

      final frames = outputDir
          .listSync()
          .whereType<File>()
          .where(
            (file) => file.path.toLowerCase().endsWith('.jpg'),
          )
          .toList();

      frames.sort(
        (a, b) => a.path.compareTo(b.path),
      );

      if (frames.isEmpty) {
        throw Exception('El video no generó fotogramas');
      }

      return frames;
    } catch (_) {
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Elimina los fotogramas temporales después
  /// de guardarlos en el dataset.
  Future<void> clearFrames(List<File> frames) async {
    if (frames.isEmpty) return;

    final directory = frames.first.parent;
    final tempDir = await getTemporaryDirectory();

    // Solo eliminar directorios temporales generados
    // por este servicio.
    if (directory.parent.path != tempDir.path ||
        !directory.path
            .split(Platform.pathSeparator)
            .last
            .startsWith('frames_')) {
      return;
    }

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
