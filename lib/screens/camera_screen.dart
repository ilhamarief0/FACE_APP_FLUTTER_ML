import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final Function(String imagePath) onPictureTaken;
  final bool isEnrollment;

  const CameraScreen({
    Key? key,
    required this.camera,
    required this.onPictureTaken,
    this.isEnrollment = false,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      widget.onPictureTaken(image.path);
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isEnrollment ? 'Rekam Wajah Anda' : 'Ambil Foto Absensi';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final double cameraAspectRatio = _controller.value.aspectRatio;

            // Calculate dimensions to fill the screen while maintaining aspect ratio
            double previewWidth = size.width;
            double previewHeight = size.width / cameraAspectRatio;

            if (previewHeight < size.height) {
              previewHeight = size.height;
              previewWidth = size.height * cameraAspectRatio;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize?.height,
                      height: _controller.value.previewSize?.width,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: size.width * 0.7,
                          height: size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.red, // This color will be "cut out"
                            borderRadius: BorderRadius.circular(size.width * 0.7 / 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size.width * 0.7 + 4, // Slightly larger for the white border
                    height: size.width * 0.7 + 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  child: Column(
                    children: [
                      Text(
                        'Posisikan wajah Anda di dalam lingkaran',
                        style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 5, color: Colors.black)]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FloatingActionButton(
                        backgroundColor: Colors.blue.shade800,
                        onPressed: () => _takePicture(context),
                        child: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator(color: Colors.blue.shade800));
          }
        },
      ),
    );
  }
}
