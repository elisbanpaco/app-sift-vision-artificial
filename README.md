# 👁️ SIFT Vision: Reconocimiento de Objetos con Flutter y OpenCV

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![OpenCV](https://img.shields.io/badge/opencv-%23white.svg?style=for-the-badge&logo=opencv&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

Una aplicación móvil desarrollada en Flutter que implementa visión artificial clásica para la detección y el reconocimiento de objetos utilizando el algoritmo **SIFT** (Scale-Invariant Feature Transform). 


## 🚀 Características Principales

*   **Registro de Objetos**: Permite a crear un conjunto de datos (dataset) local capturando imágenes o con un video del mismo y autmáticamente procesarlos.
*   **Extracción de Características (SIFT)**: Utiliza el detector SIFT para encontrar puntos clave invariantes a la escala, iluminación y rotación, calculando sus descriptores.
*   **Gestión de Dataset**: Interfaz dedicada para visualizar, administrar y depurar los objetos previamente registrados.
*   **Reconocimiento Preciso**: Emparejamiento de descriptores de la imagen de consulta con el dataset usando un robusto *pipeline* de visión computacional:
    *   *Brute-Force Matcher (L2 Norm)*.
    *   *Lowe's Ratio Test* para filtrar emparejamientos débiles.
    *   *RANSAC (Homografía)* para validar la consistencia geométrica de los puntos y reducir drásticamente los falsos positivos.

## 🛠️ Arquitectura y Tecnologías

El proyecto sigue una estructura limpia, separando la interfaz de usuario de la lógica pesada de procesamiento:

*   **Framework**: Flutter (Dart) para interfaces multiplataforma.
*   **Visión Artificial**: `opencv_dart` para el *binding* con el motor C++ de OpenCV.
*   **Procesamiento de Video**: `ffmpeg_kit_flutter_new_video` para la manipulación y extracción ágil de fotogramas.
*   **Almacenamiento Local**: `path_provider` para la persistencia del dataset.

### Estructura del Código

```text
lib/
├── main.dart               # Punto de entrada y configuración de la app
├── screens/                # Vistas de la aplicación (UI)
│   ├── home_screen.dart    # Menú principal de navegación
│   ├── capture_screen.dart # Interfaz de captura de nuevos objetos
│   ├── dataset_screen.dart # Visualización y gestión del dataset
│   └── recognition_screen.dart # Vista de reconocimiento de la cámara
├── services/               # Lógica de negocio y procesamiento
│   ├── dataset_service.dart  # Persistencia y gestión de archivos locales
│   ├── sift_service.dart     # Wrapper para la extracción SIFT
│   ├── matching_service.dart # Lógica de emparejamiento (BFMatcher + RANSAC)
│   └── video_service.dart    # Manejo de FFMPEG para extracción de frames
└── widgets/                # Componentes reutilizables de UI (cámaras, alertas, etc.)
```

## ⚙️ Requisitos Previos

Asegúrate de contar con el entorno preparado para desarrollo móvil con Flutter:

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión >= 3.13.5)
*   Dart SDK
*   Android Studio o Xcode (para emulación o compilación en dispositivos físicos)
*   Dispositivo físico recomendado (para utilizar eficientemente la cámara y probar rendimiento de procesamiento nativo).

## 🏃‍♂️ Instalación y Uso

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/elisbanpaco/app-sift-vision-artificial.git
   cd app-sift-vision-artificial
   ```

2. **Instalar dependencias de Flutter:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## 🧠 ¿Cómo funciona el algoritmo de reconocimiento bajo el capó?

1. **Extracción SIFT (`sift_service.dart`)**: Al registrar un objeto o analizar una consulta, la imagen se convierte a escala de grises. SIFT detecta *keypoints* (puntos de interés) y extrae sus respectivos *descriptores* matemáticos (vectores de 128 dimensiones).
2. **Matching KNN (`matching_service.dart`)**: Durante el reconocimiento, los descriptores de la cámara se comparan contra todo el dataset usando `BFMatcher` (K-Nearest Neighbors con K=2).
3. **Lowe's Ratio Test**: Se descartan emparejamientos ambiguos. Solo se conservan aquellos donde la distancia al mejor emparejamiento es significativamente menor (0.75x) que la distancia al segundo mejor.
4. **Validación Geométrica (RANSAC)**: Con los *matches* resultantes, se intenta calcular una matriz de homografía 2D entre la imagen de referencia y la de consulta. Si la transformación geométrica es coherente y tiene suficientes *inliers* (mínimo 8 puntos), el objeto se considera como detectado con éxito.

## 🤝 Contribución

¡La participación de la comunidad es bienvenida! Si tienes sugerencias arquitectónicas, mejoras de rendimiento (ej. indexación FLANN en vez de BFMatcher para datasets masivos), o quieres solucionar un bug:

1. Haz un *Fork* del proyecto.
2. Crea una rama para tu característica (`git checkout -b feature/MejoraIncreible`).
3. Haz *Commit* de tus cambios (`git commit -m 'Añadir mejora increíble'`).
4. Haz *Push* a tu rama (`git push origin feature/MejoraIncreible`).
5. Abre un *Pull Request* hacia el repositorio original.

## 📄 Licencia

Este proyecto está abierto para su uso y estudio. Por favor, consulta el archivo `LICENSE` MIT del repositorio para más detalles, y ten en cuenta las licencias de librerías de terceros (como OpenCV).

---
*Desarrollado con ❤️ y entusiasmo para la comunidad de visión por computadora e ingeniería de software.*
