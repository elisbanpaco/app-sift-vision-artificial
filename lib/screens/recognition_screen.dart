
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/matching_service.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final _picker = ImagePicker();
  final _matchingService = MatchingService();

  File? _image;
  MatchResult? _result;
  bool _processing = false;

  Future<void> _recognize() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() {
      _image = File(image.path);
      _result = null;
      _processing = true;
    });

    try {
      final result = await _matchingService.recognize(_image!);

      if (!mounted) return;

      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconocer objeto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _image == null
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 100,
                      ),
                    )
                  : Image.file(
                      _image!,
                      fit: BoxFit.contain,
                    ),
            ),

            if (_processing)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (!_processing && _image != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _result == null
                      ? const Text(
                          'Objeto no reconocido',
                          textAlign: TextAlign.center,
                        )
                      : Column(
                          children: [
                            Text(
                              _result!.object.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Coincidencias: ${_result!.matches}',
                            ),
                            Text(
                              'Coincidencias verificadas: ${_result!.inliers}',
                            ),
                          ],
                        ),
                ),
              ),

            ElevatedButton.icon(
              onPressed: _processing ? null : _recognize,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Reconocer objeto'),
            ),
          ],
        ),
      ),
    );
  }
}
