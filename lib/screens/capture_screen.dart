import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/video_service.dart';
import '../services/dataset_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _videoService = VideoService();
  final _datasetService = DatasetService();

  File? _video;
  bool _processing = false;

  Future<void> _selectVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    setState(() {
      _video = File(file.path);
    });
  }

  Future<void> _recordVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
    );

    if (file == null) return;

    setState(() {
      _video = File(file.path);
    });
  }

  Future<void> _saveDataset() async {
    final name = _nameController.text.trim();

    if (_video == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre y selecciona un video'),
        ),
      );
      return;
    }

    setState(() => _processing = true);

    List<File> frames = [];

    try {
      frames = await _videoService.extractFrames(_video!);

      await _datasetService.saveObject(name, frames);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objeto registrado correctamente'),
        ),
      );

      _nameController.clear();
      setState(() => _video = null);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      await _videoService.clearFrames(frames);

      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar objeto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del objeto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _processing ? null : _recordVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('Grabar video'),
            ),

            ElevatedButton.icon(
              onPressed: _processing ? null : _selectVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Seleccionar video'),
            ),

            if (_video != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Video seleccionado: ${_video!.uri.pathSegments.last}',
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _processing ? null : _saveDataset,
              child: _processing
                  ? const CircularProgressIndicator()
                  : const Text('Crear dataset'),
            ),
          ],
        ),
      ),
    );
  }
}
