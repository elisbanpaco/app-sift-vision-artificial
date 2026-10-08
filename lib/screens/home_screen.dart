
import 'package:flutter/material.dart';

import 'capture_screen.dart';
import 'dataset_screen.dart';
import 'recognition_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconocimiento SIFT'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.visibility,
              size: 90,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            const Text(
              'Reconocimiento de Objetos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: const Icon(Icons.video_call),
              label: const Text('Registrar objeto'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaptureScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.dataset),
              label: const Text('Ver dataset'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DatasetScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Reconocer objeto'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecognitionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
