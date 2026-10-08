import 'package:image_picker/image_picker.dart';
import '../services/sift_service.dart';

// Función para probar el procesamiento SIFT en una imagen seleccionada desde la galería.
Future<void> probarSift() async {
  final picker = ImagePicker();                 // Crea una instancia del selector de imágenes.

  final imagen = await picker.pickImage(        // Abre la galería para seleccionar una imagen.
    source: ImageSource.gallery,                // Especifica que la fuente de la imagen es la galería.
  );

  if (imagen == null) return;

  final siftService = SiftService();                                // Crea una instancia del servicio SIFT para procesar la imagen.
  final resultado = siftService.procesarImagen(imagen.path);        // Procesa la imagen seleccionada y obtiene los resultados SIFT.

  try { // Bloque try-finally para asegurar la liberación de recursos después del procesamiento.
    debugPrint('Imagen: ${imagen.name}');
    debugPrint('Puntos clave: ${resultado.totalKeypoints}');
    debugPrint(
      'Dimensiones descriptores: '
      '${resultado.descriptors.rows} x '
      '${resultado.descriptors.cols}',
    );
  } finally {
    resultado.dispose();
  }
}