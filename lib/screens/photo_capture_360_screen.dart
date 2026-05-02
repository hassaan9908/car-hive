import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

/// Screen for capturing 16 still photos for a 360° rotation
class PhotoCapture360Screen extends StatefulWidget {
  final Function(List<String> framePaths)? onComplete;

  const PhotoCapture360Screen({super.key, this.onComplete});

  @override
  State<PhotoCapture360Screen> createState() => _PhotoCapture360ScreenState();
}

class _PhotoCapture360ScreenState extends State<PhotoCapture360Screen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final List<String> _capturedPaths = [];
  final int _targetFrames = 16;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      final back = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(back, ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _capturePhoto() async {
    if (kIsWeb) {
      // On web, pick image from gallery as fallback
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _capturedPaths.add(picked.path));
      }
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final xfile = await _cameraController!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final target =
          '${dir.path}/360_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(xfile.path);
      await file.copy(target);
      setState(() => _capturedPaths.add(target));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _finish() async {
    if (_capturedPaths.length < _targetFrames) {
      final remaining = _targetFrames - _capturedPaths.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Not enough frames'),
          content: Text(
              'You have captured ${_capturedPaths.length} frames. Capture $remaining more or finish early?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Continue')),
            ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Finish')),
          ],
        ),
      );

      if (confirm != true) return;
    }

    widget.onComplete?.call(List<String>.from(_capturedPaths));
    Navigator.pop(context, List<String>.from(_capturedPaths));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('360° Photo Capture'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Center(
                      child: kIsWeb
                          ? const Text('Web: pick images from gallery',
                              style: TextStyle(color: Colors.white))
                          : const CircularProgressIndicator(),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black,
              child: Column(
                children: [
                  Text('${_capturedPaths.length} / $_targetFrames frames',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _capturePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _capturedPaths.isNotEmpty
                            ? () => setState(() => _capturedPaths.removeLast())
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _capturedPaths.isNotEmpty ? _finish : null,
                        child: const Text('Finish'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedPaths.length,
                      itemBuilder: (context, index) {
                        final p = _capturedPaths[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: kIsWeb || !File(p).existsSync()
                              ? Container(width: 120, color: Colors.grey)
                              : Image.file(File(p),
                                  width: 120, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
