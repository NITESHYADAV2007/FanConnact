import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path_provider/path_provider.dart';

/// Sports background presets (mirrors signup.html drawBgGradient).
/// Each entry: key -> (label, LinearGradient top->bottom).
class SportBg {
  final String key;
  final String label;
  final LinearGradient gradient;
  const SportBg(this.key, this.label, this.gradient);
}

const List<SportBg> kSportBackgrounds = [
  SportBg('none', 'None', LinearGradient(colors: [Colors.transparent, Colors.transparent])),
  SportBg('stadium', '🏟 Stadium', LinearGradient(colors: [Color(0xFF1d4ed8), Color(0xFF60a5fa), Color(0xFF15803d), Color(0xFF166534), Color(0xFF052e16)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.32, 0.45, 0.7, 1.0])),
  SportBg('cricket', '🏏 Cricket', LinearGradient(colors: [Color(0xFFbbf7d0), Color(0xFF4ade80), Color(0xFF16a34a), Color(0xFF15803d), Color(0xFF14532d)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.28, 0.45, 0.7, 1.0])),
  SportBg('football', '⚽ Football', LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6), Color(0xFF15803d), Color(0xFF166534), Color(0xFF052e16)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('basketball', '🏀 Basketball', LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFd97706), Color(0xFFb45309), Color(0xFF78350f)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.5, 1.0])),
  SportBg('tennis', '🎾 Tennis', LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6), Color(0xFF15803d), Color(0xFF166534), Color(0xFF052e16)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('hockey', '🏒 Hockey', LinearGradient(colors: [Color(0xFFe0f2fe), Color(0xFF7dd3fc), Color(0xFF15803d), Color(0xFF166534), Color(0xFF052e16)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('kabaddi', '🤼 Kabaddi', LinearGradient(colors: [Color(0xFFfcd34d), Color(0xFFf59e0b), Color(0xFFd97706), Color(0xFF92400e)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.5, 1.0])),
  SportBg('volleyball', '🏐 Volleyball', LinearGradient(colors: [Color(0xFFfde68a), Color(0xFF38bdf8), Color(0xFF0ea5e9), Color(0xFF0369a1), Color(0xFF0c4a6e)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('tabletennis', '🏓 Table Tennis', LinearGradient(colors: [Color(0xFF1e293b), Color(0xFF475569), Color(0xFFdc2626), Color(0xFFb91c1c), Color(0xFF7f1d1d)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('baseball', '⚾ Baseball', LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF2563eb), Color(0xFF16a34a), Color(0xFF15803d), Color(0xFF052e16)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.3, 0.45, 0.7, 1.0])),
  SportBg('esports', '🎮 Esports', LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFFa855f7), Color(0xFF3b82f6), Color(0xFF1e1b4b)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.35, 0.6, 1.0])),
];

class PhotoFxService {
  static const int outSize = 400;

  /// Person cut-out (MLKit selfie segmentation) composited over [bg].
  /// Applies [filterMatrix] (4x5 color matrix, 0-255 scale) + optional beauty.
  /// Returns PNG bytes (outSize x outSize) or null if segmentation failed.
  static Future<Uint8List?> cutoutToGradient({
    required Uint8List photoBytes,
    required SportBg bg,
    List<double>? filterMatrix,
    bool beauty = false,
    int size = outSize,
  }) async {
    if (bg.key == 'none') return processFlat(photoBytes: photoBytes, filterMatrix: filterMatrix, beauty: beauty, size: size);
    try {
      final codec = await ui.instantiateImageCodec(photoBytes);
      final frame = await codec.getNextFrame();
      final square = await _coverSquare(frame.image, size);
      final rgba = await _imageToRgba(square);

      final tmpDir = await getTemporaryDirectory();
      final dir = Directory('${tmpDir.path}/fc_seg_${DateTime.now().millisecondsSinceEpoch}');
      await dir.create(recursive: true);
      File? tmp;
      try {
        final sqBytes = await _encodeImage(square, png: true);
        tmp = File('${dir.path}/in.png');
        await tmp.writeAsBytes(sqBytes);

        final segmenter = SelfieSegmenter(mode: SegmenterMode.single);
        final mask = await segmenter.processImage(InputImage.fromFilePath(tmp.path));
        await segmenter.close();
        if (mask == null || mask.confidences.length != size * size) {
          debugPrint('PhotoFx: mask null or size mismatch (${mask?.width}x${mask?.height})');
          return null;
        }

        final grad = await _gradientToRgba(bg.gradient, size);
        final out = _composite(rgba, grad, mask.confidences, size);

        _applyFilter(out, filterMatrix);
        if (beauty) _applyBeauty(out, size);
        return _encodeRgba(out, size);
      } finally {
        try { await tmp?.delete(); } catch (_) {}
        try { await dir.delete(recursive: true); } catch (_) {}
      }
    } catch (e) {
      debugPrint('PhotoFx cutout failed: $e');
      return null;
    }
  }

  /// Square-crops [photoBytes] and applies filter + optional beauty. No background.
  static Future<Uint8List?> processFlat({
    required Uint8List photoBytes,
    List<double>? filterMatrix,
    bool beauty = false,
    int size = outSize,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(photoBytes);
      final frame = await codec.getNextFrame();
      final square = await _coverSquare(frame.image, size);
      final rgba = await _imageToRgba(square);
      _applyFilter(rgba, filterMatrix);
      if (beauty) _applyBeauty(rgba, size);
      return _encodeRgba(rgba, size);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _coverSquare(ui.Image src, int size) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    final sw = src.width.toDouble();
    final sh = src.height.toDouble();
    final scale = max(size / sw, size / sh);
    final dw = sw * scale;
    final dh = sh * scale;
    final dx = (size - dw) / 2;
    final dy = (size - dh) / 2;
    c.drawImageRect(
      src,
      Rect.fromLTWH(0, 0, sw, sh),
      Rect.fromLTWH(dx, dy, dw, dh),
      Paint()..filterQuality = FilterQuality.medium,
    );
    return rec.endRecording().toImage(size, size);
  }

  static Future<Uint8List> _imageToRgba(ui.Image img) async {
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return bd!.buffer.asUint8List();
  }

  static Future<Uint8List> _encodeImage(ui.Image img, {bool png = true}) async {
    final bd = await img.toByteData(format: png ? ui.ImageByteFormat.png : ui.ImageByteFormat.rawRgba);
    return bd!.buffer.asUint8List();
  }

  /// Renders gradient (+ subtle vignette like the web) to RGBA bytes.
  static Future<Uint8List> _gradientToRgba(LinearGradient gradient, int size) async {
    final rec = ui.PictureRecorder();
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    final c = Canvas(rec, rect);
    c.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    final vg = RadialGradient(
      colors: [const Color(0x00000000), const Color(0x47000000)],
      stops: const [0.45, 1.0],
    );
    c.drawRect(rect, Paint()..shader = vg.createShader(rect));
    final img = await rec.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }

  static Uint8List _composite(Uint8List fg, Uint8List bg, List<double> mask, int size) {
    final len = size * size;
    final out = Uint8List(len * 4);
    for (var i = 0; i < len; i++) {
      final a = mask[i];
      final inv = 1 - a;
      final o = i * 4;
      out[o] = (fg[o] * a + bg[o] * inv).round().clamp(0, 255);
      out[o + 1] = (fg[o + 1] * a + bg[o + 1] * inv).round().clamp(0, 255);
      out[o + 2] = (fg[o + 2] * a + bg[o + 2] * inv).round().clamp(0, 255);
      out[o + 3] = 255;
    }
    return out;
  }

  static void _applyFilter(Uint8List rgba, List<double>? m) {
    if (m == null || m.length < 20) return;
    final len = rgba.length ~/ 4;
    for (var i = 0; i < len; i++) {
      final o = i * 4;
      final r = rgba[o].toDouble();
      final g = rgba[o + 1].toDouble();
      final b = rgba[o + 2].toDouble();
      final a = rgba[o + 3].toDouble();
      rgba[o] = (m[0] * r + m[1] * g + m[2] * b + m[3] * a + m[4]).round().clamp(0, 255);
      rgba[o + 1] = (m[5] * r + m[6] * g + m[7] * b + m[8] * a + m[9]).round().clamp(0, 255);
      rgba[o + 2] = (m[10] * r + m[11] * g + m[12] * b + m[13] * a + m[14]).round().clamp(0, 255);
      rgba[o + 3] = (m[15] * r + m[16] * g + m[17] * b + m[18] * a + m[19]).round().clamp(0, 255);
    }
  }

  /// Beauty mode: skin-heuristic mask (like the web) + dilate + soft-focus blend + slight brightness.
  static void _applyBeauty(Uint8List rgba, int size) {
    final w = size, h = size;
    final skin = Uint8List(w * h);
    for (var i = 0, p = 0; i < rgba.length; i += 4, p++) {
      final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      final mx = max(r, max(g, b));
      final mn = min(r, min(g, b));
      skin[p] = (r > 50 && g > 20 && b > 10 && r > g && r > b && r - g > 8 && mx - mn > 12) ? 255 : 0;
    }
    final dil = Uint8List(w * h);
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        var m = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (skin[(y + dy) * w + (x + dx)] > 0) { m = 255; }
          }
        }
        dil[y * w + x] = m;
      }
    }
    final src = Uint8List.fromList(rgba);
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final p = y * w + x;
        if (dil[p] == 0) continue;
        var r = 0, g = 0, b = 0, n = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final idx = ((y + dy) * w + (x + dx)) * 4;
            r += src[idx]; g += src[idx + 1]; b += src[idx + 2]; n++;
          }
        }
        final o = p * 4;
        final sr = src[o].toDouble(), sg = src[o + 1].toDouble(), sb = src[o + 2].toDouble();
        const f = 0.42, br = 1.05;
        rgba[o] = (sr * br * (1 - f) + (r / n) * f).round().clamp(0, 255);
        rgba[o + 1] = (sg * br * (1 - f) + (g / n) * f).round().clamp(0, 255);
        rgba[o + 2] = (sb * br * (1 - f) + (b / n) * f).round().clamp(0, 255);
      }
    }
  }

  static Future<Uint8List> _encodeRgba(Uint8List rgba, int size) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, size, size, ui.PixelFormat.rgba8888, completer.complete);
    final img = await completer.future;
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }
}
