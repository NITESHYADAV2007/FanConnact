import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/photo_fx_service.dart';

class CameraCaptureResult {
  final String filePath;
  final String filter;
  final String bg;
  final bool beauty;
  const CameraCaptureResult({required this.filePath, required this.filter, required this.bg, required this.beauty});
}

const Map<String, List<double>> _cameraFilters = {
  'none': [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0],
  'vivid': [1.5,0,0,0,0, 0,1.5,0,0,0, 0,0,1.5,0,0, 0,0,0,1,0],
  'warm': [1.0,0,0,0,0, 0,1.0,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0],
  'cool': [1.0,0,0,0,0, 0,0.9,0,0,0, 0,0,1.2,0,0, 0,0,0,1,0],
  'noir': [0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0,0,0,1,0],
  'retro': [0.6,0.2,0.1,0,0, 0.1,0.7,0.1,0,0, 0.05,0.05,0.5,0,0, 0,0,0,1,0],
  'dramatic': [1.5,0,0,0,-30, 0,1.5,0,0,-30, 0,0,1.5,0,-30, 0,0,0,1,0],
};

class CameraCaptureScreen extends StatefulWidget {
  final bool isDark;
  final Color accentColor;
  const CameraCaptureScreen({super.key, required this.isDark, required this.accentColor});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _initializing = true;
  String _initError = '';

  String _filter = 'none';
  String _bg = 'none';
  bool _beauty = false;
  double _zoom = 1.0;
  double _maxZoom = 4.0;
  FlashMode _flash = FlashMode.auto;

  bool _capturing = false;
  bool _processing = false;
  Uint8List? _reviewBytes;
  String? _reviewMsg;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() { _initializing = true; _initError = ''; });
    try {
      final cams = await availableCameras();
      if (!mounted) return;
      _cameras = cams;
      final preferFront = cams.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = preferFront >= 0 ? preferFront : 0;
      await _startController();
    } catch (e) {
      if (!mounted) return;
      setState(() { _initializing = false; _initError = 'Camera not available: $e'; });
    }
  }

  Future<void> _startController() async {
    if (_cameras.isEmpty) return;
    final desc = _cameras[_cameraIndex];
    final c = CameraController(desc, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      final minZ = await c.getMinZoomLevel();
      final maxZ = await c.getMaxZoomLevel();
      _maxZoom = maxZ.clamp(1.0, 4.0);
      await c.setZoomLevel(minZ.clamp(1.0, _maxZoom));
      if (!mounted) return;
      setState(() { _initializing = false; _initError = ''; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _initializing = false; _initError = 'Could not start camera: $e'; });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    final old = _controller;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _initializing = true);
    await old?.dispose();
    await _startController();
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = switch (_flash) {
      FlashMode.auto => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      _ => FlashMode.auto,
    };
    await c.setFlashMode(next);
    if (mounted) setState(() => _flash = next);
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing || _processing) return;
    setState(() => _capturing = true);
    try {
      final xf = await c.takePicture();
      final bytes = await xf.readAsBytes();
      setState(() { _capturing = false; _processing = true; _reviewMsg = 'Applying background...'; });

      final bg = kSportBackgrounds.firstWhere((b) => b.key == _bg, orElse: () => kSportBackgrounds.first);
      final filter = _cameraFilters[_filter] ?? _cameraFilters['none']!;

      Uint8List? out = bg.key == 'none'
          ? await PhotoFxService.processFlat(photoBytes: bytes, filterMatrix: filter, beauty: _beauty)
          : await PhotoFxService.cutoutToGradient(photoBytes: bytes, bg: bg, filterMatrix: filter, beauty: _beauty);
      out ??= await PhotoFxService.processFlat(photoBytes: bytes, filterMatrix: filter, beauty: _beauty);
      if (!mounted) return;
      setState(() { _processing = false; _reviewBytes = out; _reviewMsg = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _capturing = false; _processing = false; _reviewMsg = null; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<void> _usePhoto() async {
    final bytes = _reviewBytes;
    if (bytes == null) return;
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory('${base.path}/fc_cam_${DateTime.now().millisecondsSinceEpoch}');
      await dir.create(recursive: true);
      final file = File('${dir.path}/avatar.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      Navigator.of(context).pop(CameraCaptureResult(filePath: file.path, filter: _filter, bg: _bg, beauty: _beauty));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  void _retake() {
    setState(() { _reviewBytes = null; _reviewMsg = null; });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final accent = widget.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent : Colors.white24),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _reviewBytes != null
            ? _buildReview(accent)
            : _buildLive(accent),
      ),
    );
  }

  Widget _buildLive(Color accent) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              const Text('Take a Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Preview fills all remaining space; controls float on top.
        Expanded(
          child: _initializing
              ? const Center(child: CircularProgressIndicator())
              : _initError.isNotEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_initError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))))
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(_cameraFilters[_filter] ?? _cameraFilters['none']!),
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: 1000,
                                  height: 1000 / _controller!.value.aspectRatio,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          ),
                          if (_processing || _capturing) Container(color: Colors.black54, alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 10),
                            Text(_reviewMsg ?? 'Capturing...', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ])),

                          // Filters (top overlay)
                          Positioned(
                            top: 8, left: 8, right: 8,
                            child: _overlayRow(
                              accent,
                              header: 'Filters',
                              chips: [
                                for (final f in _cameraFilters.keys) _chip(f[0].toUpperCase() + f.substring(1), _filter == f, () => setState(() => _filter = f)),
                              ],
                            ),
                          ),

                          // Sports Backgrounds (overlay)
                          Positioned(
                            top: 56, left: 8, right: 8,
                            child: _overlayRow(
                              accent,
                              header: 'Sports Background',
                              chips: [
                                for (final b in kSportBackgrounds) _chip(b.label, _bg == b.key, () => setState(() => _bg = b.key)),
                              ],
                            ),
                          ),

                          // Bottom panel: beauty + zoom + capture controls
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  colors: [Color(0xE6000000), Colors.transparent],
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Beauty Mode', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                                      Switch(value: _beauty, activeTrackColor: accent, onChanged: (v) => setState(() => _beauty = v)),
                                      const Spacer(),
                                      Text('Zoom ${_zoom.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Slider(
                                    value: _zoom,
                                    min: 1.0,
                                    max: _maxZoom,
                                    activeColor: accent,
                                    inactiveColor: Colors.white24,
                                    onChanged: (v) {
                                      setState(() => _zoom = v);
                                      _controller?.setZoomLevel(v);
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed: _controller != null && _controller!.value.isInitialized ? _flipCamera : null,
                                        icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28),
                                      ),
                                      IconButton(
                                        onPressed: _controller != null && _controller!.value.isInitialized ? _toggleFlash : null,
                                        icon: Icon(switch (_flash) { FlashMode.torch => Icons.flash_on, FlashMode.off => Icons.flash_off, _ => Icons.flash_auto }, color: Colors.white, size: 28),
                                      ),
                                      GestureDetector(
                                        onTap: _capture,
                                        child: Container(
                                          width: 64, height: 64,
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          padding: const EdgeInsets.all(6),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.black, width: 4),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _pickGalleryFallback(),
                                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
                                      ),
                                      const SizedBox(width: 28),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _overlayRow(Color accent, {required String header, required List<Widget> chips}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.6)),
          const SizedBox(height: 5),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ],
      ),
    );
  }

  Future<void> _pickGalleryFallback() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final out = await PhotoFxService.processFlat(photoBytes: bytes, filterMatrix: _cameraFilters[_filter] ?? _cameraFilters['none']!, beauty: _beauty);
    if (!mounted) return;
    setState(() => _reviewBytes = out ?? bytes);
  }

  Widget _buildReview(Color accent) {
    final bytes = _reviewBytes;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              const Text('Review Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 24), onPressed: _retake),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: bytes == null
                ? const CircularProgressIndicator()
                : Container(
                    width: 320, height: 320,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.replay, color: Colors.white),
                label: const Text('Retake', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
              ),
              FilledButton.icon(
                onPressed: _usePhoto,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Use Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
