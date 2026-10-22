import 'dart:io';
import 'dart:math';

import 'package:app_sift_vision_artificial/services/dataset_service.dart';
import 'package:app_sift_vision_artificial/services/matching_service.dart';
import 'package:app_sift_vision_artificial/services/object_region.dart';
import 'package:flutter_test/flutter_test.dart';

class _Dataset extends DatasetService {
  final List<DatasetObject> objects;
  _Dataset(this.objects);
  @override
  Future<List<DatasetObject>> getObjects() async => objects;
}

class _StoredDataset extends DatasetService {
  final Directory directory;
  _StoredDataset(this.directory);
  @override
  Future<Directory> getDatasetDirectory() async => directory;
}

void main() {
  test(
    'Guarda los recuadros y los recupera al abrir el dataset otra vez',
    () async {
      final directory = await Directory.systemTemp.createTemp('sift_regions_');
      try {
        final image = File('${directory.path}/source.jpg');
        await image.writeAsBytes([1, 2, 3]);
        final service = _StoredDataset(directory);
        final object = await service.saveObject('Caja', [image]);
        await service.saveRegions(object, {
          object.images.single: const ObjectRegion(.1, .2, .7, .8),
        });
        final reloaded = (await _StoredDataset(directory).getObjects()).single;
        expect(reloaded.regions[reloaded.images.single]!.toJson(), [
          .1,
          .2,
          .7,
          .8,
        ]);
        await expectLater(
          service.saveRegions(reloaded, {
            reloaded.images.single: const ObjectRegion(.9, .2, .1, .8),
          }),
          throwsArgumentError,
        );
        expect((await service.getObjects()).single.regions.length, 1);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test('Lee datasets antiguos y conserva los recuadros al serializar', () {
    final object = DatasetObject.fromJson({
      'id': 'test',
      'name': 'Caja',
      'images': ['a.jpg'],
    });
    expect(object.regions, isEmpty);
    final marked = DatasetObject(
      id: object.id,
      name: object.name,
      images: object.images,
      regions: {'a.jpg': const ObjectRegion(.2, .3, .8, .9)},
    );
    final loaded = DatasetObject.fromJson(marked.toJson());
    expect(loaded.regions['a.jpg']!.toJson(), [.2, .3, .8, .9]);
  });

  test('Proyecta esquinas y rechaza homografías degeneradas', () {
    const region = ObjectRegion(.25, .25, .75, .75);
    final result = projectObjectRegion(
      region,
      [1, 0, 50, 0, 1, 20, 0, 0, 1],
      200,
      100,
      400,
      200,
    )!;
    expect(result.first.x, .25);
    expect(result.first.y, .225);
    expect(result[2].x, .5);
    expect(result[2].y, .475);
    expect(
      projectObjectRegion(region, List.filled(9, 0), 200, 100, 400, 200),
      isNull,
    );
    expect(
      projectObjectRegion(
        region,
        [1, 0, 9999, 0, 1, 0, 0, 0, 1],
        200,
        100,
        400,
        200,
      ),
      isNull,
    );
    expect(
      projectObjectRegion(
        region,
        [1, 0, 0, 0, 0, 0, 0, 0, 1],
        200,
        100,
        400,
        200,
      ),
      isNull,
    );
  });

  test(
    'Localiza el objeto girado sobre otro fondo y rechaza solo el fondo',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sift_localization_',
      );
      try {
        final random = Random(123);
        final referencePixels = List.generate(
          320 * 320,
          (_) => random.nextInt(256),
        );
        final queryPixels = List.generate(
          480 * 400,
          (_) => random.nextInt(256),
        );
        // Trasladar y girar 90 grados solamente la región del objeto.
        for (int y = 0; y < 192; y++) {
          for (int x = 0; x < 192; x++) {
            queryPixels[(100 + x) * 480 + 130 + (191 - y)] =
                referencePixels[(64 + y) * 320 + 64 + x];
          }
        }
        Future<File> pgm(
          String name,
          List<int> pixels,
          int width,
          int height,
        ) async {
          final file = File('${directory.path}/$name.pgm');
          await file.writeAsBytes([
            ...('P5\n$width $height\n255\n'.codeUnits),
            ...pixels,
          ]);
          return file;
        }

        final reference = await pgm('reference', referencePixels, 320, 320);
        final query = await pgm('query', queryPixels, 480, 400);
        final object = DatasetObject(
          id: 'test',
          name: 'Objeto de prueba',
          images: [reference.path],
          regions: {reference.path: const ObjectRegion(.2, .2, .8, .8)},
        );
        final service = MatchingService(dataset: _Dataset([object]));
        final result = await service.recognize(query);
        expect(result, isNotNull);
        expect(result!.object.name, object.name);
        expect(result.inliers, greaterThanOrEqualTo(8));
        final expected = [
          (x: 322 / 480, y: 100 / 400),
          (x: 322 / 480, y: 292 / 400),
          (x: 130 / 480, y: 292 / 400),
          (x: 130 / 480, y: 100 / 400),
        ];
        for (int i = 0; i < 4; i++) {
          expect(result.outline[i].x, closeTo(expected[i].x, .025));
          expect(result.outline[i].y, closeTo(expected[i].y, .025));
        }
        // Mismo fondo original, sin el objeto registrado.
        final backgroundPixels = List<int>.of(referencePixels);
        for (int y = 64; y < 256; y++) {
          for (int x = 64; x < 256; x++) {
            backgroundPixels[y * 320 + x] = 128;
          }
        }
        final background = await pgm('background', backgroundPixels, 320, 320);
        expect(await service.recognize(background), isNull);
        final blank = await pgm('blank', List.filled(320 * 320, 128), 320, 320);
        expect(await service.recognize(blank), isNull);
        final unmarked = MatchingService(
          dataset: _Dataset([
            DatasetObject(id: 'old', name: 'Viejo', images: [reference.path]),
          ]),
        );
        await expectLater(unmarked.recognize(query), throwsStateError);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
