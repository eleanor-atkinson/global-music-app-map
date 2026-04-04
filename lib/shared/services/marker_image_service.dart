import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/config/map_config.dart';

/// Registers marker images into the Mapbox style at runtime.
///
/// Phase 3 registers only the fallback marker (a solid indigo circle).
/// Phase 4 will extend this to fetch + register artist thumbnails.
class MarkerImageService {
  const MarkerImageService(this._map);

  final MapboxMap _map;

  /// Registers a default circular marker used as the fallback icon
  /// for any concert whose artist thumbnail hasn't loaded yet.
  Future<void> registerDefaultMarker() async {
    final bytes = await _renderDefaultMarker(size: 48);
    await _map.style.addStyleImage(
      MapConfig.fallbackMarkerImage,
      1.0,
      MbxImage(width: 48, height: 48, data: bytes),
      false, // not SDF — we use a pre-coloured bitmap
      [],
      [],
      null,
    );
  }

  /// Paints a 48×48 indigo filled circle with a white border.
  Future<Uint8List> _renderDefaultMarker({required int size}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    // White border
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );
    // Indigo fill
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()..color = const Color(0xFF6366F1),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData!.buffer.asUint8List();
  }
}
