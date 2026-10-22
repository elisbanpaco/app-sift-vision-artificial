import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_sift_vision_artificial/services/object_region.dart';
import 'package:app_sift_vision_artificial/widgets/object_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Alinea recuadro y gestos con la foto dentro de las bandas vacías',
    (tester) async {
      final directory = (await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'sift_overlay_',
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 400, 200),
          Paint()..color = Colors.blueGrey,
        );
        canvas.drawRect(
          const Rect.fromLTWH(100, 40, 200, 120),
          Paint()..color = Colors.amber,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(400, 200);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${directory.path}/image.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return directory;
      }))!;
      final file = File('${directory.path}/image.png');
      ObjectRegion? selected;
      final boundaryKey = GlobalKey();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: ObjectImage(
                      image: file,
                      outline: const [
                        (x: .25, y: .2),
                        (x: .75, y: .2),
                        (x: .75, y: .8),
                        (x: .25, y: .8),
                      ],
                      label: 'Caja de prueba',
                      onRegionChanged: (region) => selected = region,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Caja de prueba'), findsOneWidget);
      final area = find.byKey(const ValueKey('object-image-area'));
      expect(tester.getSize(area), const Size(400, 200));
      final origin = tester.getTopLeft(area);
      final gesture = await tester.startGesture(
        origin + const Offset(300, 160),
      );
      await gesture.moveTo(origin + const Offset(100, 40));
      await gesture.up();
      expect(selected!.toJson(), [.25, .2, .75, .8]);
      // Vista de QA local para comprobar posición del contorno y etiqueta.
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final preview = await boundary.toImage(pixelRatio: 2);
        final previewData = await preview.toByteData(
          format: ui.ImageByteFormat.png,
        );
        await File('/tmp/sift-overlay-preview.png')
            .writeAsBytes(previewData!.buffer.asUint8List());
        preview.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );
}
