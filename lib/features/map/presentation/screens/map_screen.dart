import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/config/map_config.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;

  /// Resolve the correct Mapbox Studio style for the current environment.
  String get _styleUri {
    if (Env.isProd) return MapConfig.styleUriProd;
    if (Env.isUat) return MapConfig.styleUriUat;
    return MapConfig.styleUriDev;
  }

  static final _initialCamera = CameraOptions(
    center: Point(
      coordinates: Position(MapConfig.initialLng, MapConfig.initialLat),
    ),
    zoom: MapConfig.initialZoom,
    pitch: 0.0,
    bearing: 0.0,
  );

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;

    await Future.wait([
      // Clean, minimal UI
      map.compass.updateSettings(CompassSettings(enabled: false)),
      map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
      map.attribution.updateSettings(
        AttributionSettings(marginBottom: 8, marginRight: 8),
      ),
      // Lock to top-down 2D — prevents accidental tilt/rotate on a discovery map
      map.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: false,
          pitchEnabled: false,
          doubleTapToZoomInEnabled: true,
          doubleTouchToZoomOutEnabled: true,
          quickZoomEnabled: true,
        ),
      ),
      // Pulsing user location dot
      map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: 0xFF6366F1,
        ),
      ),
    ]);

    // Phase 2: add GeoJsonSource + SymbolLayers + cluster layers here
  }

  void _onCameraChanged(CameraChangedEventData event) {
    // Phase 2: debounce → read CoordinateBounds → fire Supabase fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MapWidget(
        key: const ValueKey('concert_map'),
        styleUri: _styleUri,
        cameraOptions: _initialCamera,
        onMapCreated: _onMapCreated,
        onCameraChangeListener: _onCameraChanged,
      ),
    );
  }
}
