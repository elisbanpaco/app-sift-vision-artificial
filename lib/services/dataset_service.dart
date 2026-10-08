// Servicio para gestionar el dataset de imágenes y sus características.


import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Objeto registrado en el dataset.
class DatasetObject {
  final String id;
  final String name;
  final List<String> images;

  DatasetObject({
    required this.id,
    required this.name,
    required this.images,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'images': images,
  };

  factory DatasetObject.fromJson(Map<String, dynamic> json) {
    return DatasetObject(
      id: json['id'] as String,
      name: json['name'] as String,
      images: List<String>.from(json['images'] as List),
    );
  }
}

/// Servicio para gestionar el dataset de objetos.
class DatasetService {
  final _uuid = const Uuid();

  /// Directorio donde se almacenan los objetos.
  Future<Directory> getDatasetDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${appDir.path}/dataset');

    await directory.create(recursive: true);
    return directory;
  }

  /// Registra un objeto con las imágenes extraídas del video.
  Future<DatasetObject> saveObject(
    String name,
    List<File> frames,
  ) async {
    if (name.trim().isEmpty || frames.isEmpty) {
      throw ArgumentError('Nombre o imágenes no válidos');
    }

    final datasetDir = await getDatasetDirectory();
    final id = _uuid.v4();

    final objectDir = Directory('${datasetDir.path}/$id');
    await objectDir.create(recursive: true);

    final images = <String>[];

    try {
      for (int i = 0; i < frames.length; i++) {
        final source = frames[i];

        final extension = source.path
            .split('.')
            .last
            .toLowerCase();

        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          throw ArgumentError('Formato de imagen no admitido');
        }

        final destination = File(
          '${objectDir.path}/frame_$i.$extension',
        );

        await source.copy(destination.path);
        images.add(destination.path);
      }

      final object = DatasetObject(
        id: id,
        name: name.trim(),
        images: images,
      );

      final metadata = File('${objectDir.path}/metadata.json');

      await metadata.writeAsString(
        jsonEncode(object.toJson()),
      );

      return object;
    } catch (_) {
      await objectDir.delete(recursive: true);
      rethrow;
    }
  }

  /// Recupera todos los objetos registrados.
  Future<List<DatasetObject>> getObjects() async {
    final directory = await getDatasetDirectory();
    final objects = <DatasetObject>[];

    await for (final entity in directory.list()) {
      if (entity is! Directory) continue;

      final metadata = File('${entity.path}/metadata.json');

      if (!await metadata.exists()) continue;

      final json = jsonDecode(
        await metadata.readAsString(),
      ) as Map<String, dynamic>;

      objects.add(DatasetObject.fromJson(json));
    }

    return objects;
  }

  /// Elimina un objeto registrado.
  Future<void> deleteObject(String id) async {
    final directory = await getDatasetDirectory();

    if (!RegExp(
      r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
    ).hasMatch(id)) {
      throw ArgumentError('ID inválido');
    }

    final objectDir = Directory('${directory.path}/$id');

    if (await objectDir.exists()) {
      await objectDir.delete(recursive: true);
    }
  }
}
