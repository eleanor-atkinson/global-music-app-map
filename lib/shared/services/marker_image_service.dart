import 'dart:math';
import 'dart:typed_data';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/config/map_config.dart';

class MarkerImageService {
  const MarkerImageService(this._map);

  final MapboxMap _map;

  Future<void> registerDefaultMarker() async {
    const size = 48;
    final bytes = _buildCircleRgba(
      size: size,
      fillR: 99, fillG: 102, fillB: 241,   // indigo #6366F1
      borderR: 255, borderG: 255, borderB: 255,
      borderWidth: 3,
    );
    await _map.style.addStyleImage(
      MapConfig.fallbackMarkerImage,
      1.0,
      MbxImage(width: size, height: size, data: bytes),
      false,
      [],
      [],
      null,
    );
  }

  /// Generates raw RGBA bytes for an anti-aliased filled circle.
  /// Avoids the Flutter rendering pipeline which can produce mismatched
  /// pixel formats that Mapbox rejects at runtime.
  static Uint8List _buildCircleRgba({
    required int size,
    required int fillR, required int fillG, required int fillB,
    required int borderR, required int borderG, required int borderB,
    required int borderWidth,
  }) {
    final bytes = Uint8List(size * size * 4);
    final center = (size - 1) / 2;
    final outerR = center;
    final innerR = outerR - borderWidth;

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final dist = sqrt((x - center) * (x - center) + (y - center) * (y - center));
        final idx = (y * size + x) * 4;

        if (dist <= innerR) {
          bytes[idx]     = fillR;
          bytes[idx + 1] = fillG;
          bytes[idx + 2] = fillB;
          bytes[idx + 3] = 255;
        } else if (dist <= outerR) {
          bytes[idx]     = borderR;
          bytes[idx + 1] = borderG;
          bytes[idx + 2] = borderB;
          bytes[idx + 3] = 255;
        }
        // else: transparent (already 0)
      }
    }
    return bytes;
  }
}
