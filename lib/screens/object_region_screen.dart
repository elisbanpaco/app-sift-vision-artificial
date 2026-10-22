import 'dart:io';

import 'package:flutter/material.dart';

import '../services/dataset_service.dart';
import '../services/object_region.dart';
import '../widgets/object_image.dart';

class ObjectRegionScreen extends StatefulWidget {
  final DatasetObject object;
  const ObjectRegionScreen({super.key, required this.object});

  @override
  State<ObjectRegionScreen> createState() => _ObjectRegionScreenState();
}

class _ObjectRegionScreenState extends State<ObjectRegionScreen> {
  late final Map<String, ObjectRegion> _regions = Map.of(widget.object.regions);
  int _index = 0;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DatasetService().saveRegions(widget.object, _regions);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.object.images;
    if (images.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.object.name)),
        body: const Center(child: Text('Este dataset no tiene imágenes')),
      );
    }
    final path = images[_index];
    final region = _regions[path];
    return Scaffold(
      appBar: AppBar(title: Text('Marcar ${widget.object.name}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Arrastra un recuadro ajustado al objeto. Marca varias imágenes con diferentes lados; solo se usarán las imágenes marcadas.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ObjectImage(
                  image: File(path),
                  outline: region == null
                      ? const []
                      : [
                          (x: region.left, y: region.top),
                          (x: region.right, y: region.top),
                          (x: region.right, y: region.bottom),
                          (x: region.left, y: region.bottom),
                        ],
                  label: region == null ? null : widget.object.name,
                  onRegionChanged: _saving
                      ? null
                      : (value) => setState(() => _regions[path] = value),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Imagen anterior',
                    onPressed: _saving || _index == 0
                        ? null
                        : () => setState(() => _index--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Imagen ${_index + 1} de ${images.length}'),
                  IconButton(
                    tooltip: 'Imagen siguiente',
                    onPressed: _saving || _index == images.length - 1
                        ? null
                        : () => setState(() => _index++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (images.length > 1)
                Slider(
                  value: _index.toDouble(),
                  min: 0,
                  max: (images.length - 1).toDouble(),
                  divisions: images.length - 1,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _index = value.round()),
                ),
              Text('${_regions.length} imágenes marcadas'),
              TextButton(
                onPressed: region == null || _saving
                    ? null
                    : () => setState(() => _regions.remove(path)),
                child: const Text('Quitar recuadro de esta imagen'),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando…' : 'Guardar recuadros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
