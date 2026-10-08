import 'dart:io';

import 'package:flutter/material.dart';

import '../services/dataset_service.dart';

class DatasetScreen extends StatefulWidget {
  const DatasetScreen({super.key});

  @override
  State<DatasetScreen> createState() => _DatasetScreenState();
}

class _DatasetScreenState extends State<DatasetScreen> {
  final DatasetService _service = DatasetService();

  late Future<List<DatasetObject>> _objects;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  void _loadObjects() {
    _objects = _service.getObjects();
  }

  Future<void> _deleteObject(DatasetObject object) async {
    await _service.deleteObject(object.id);

    if (!mounted) return;

    setState(_loadObjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset de objetos'),
      ),
      body: FutureBuilder<List<DatasetObject>>(
        future: _objects,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final objects = snapshot.data ?? [];

          if (objects.isEmpty) {
            return const Center(
              child: Text('No hay objetos registrados'),
            );
          }

          return ListView.builder(
            itemCount: objects.length,
            itemBuilder: (context, index) {
              final object = objects[index];

              return Card(
                child: ListTile(
                  leading: object.images.isNotEmpty
                      ? Image.file(
                          File(object.images.first),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                  title: Text(object.name),
                  subtitle: Text(
                    '${object.images.length} imágenes',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteObject(object),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
