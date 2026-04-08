import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/config/map_config.dart';

class MarkerImageService {
  const MarkerImageService(this._map);

  final MapboxMap _map;

  Future<void> registerDefaultMarker() async {
    final bytes = await _loadAssetAsPng('assets/marker.png');
    final size = await _pngSize(bytes);

    await _map.style.addStyleImage(
      MapConfig.fallbackMarkerImage,
      2.0,
      MbxImage(width: size.width.toInt(), height: size.height.toInt(), data: bytes),
      false,
      [],
      [],
      null,
    );
  }

  static Future<Uint8List> _loadAssetAsPng(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  static Future<ui.Size> _pngSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return ui.Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }
}
