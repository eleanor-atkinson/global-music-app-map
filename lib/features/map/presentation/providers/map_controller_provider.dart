import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Holds the live MapboxMap controller once the map is initialised.
/// Phase 2 providers that need to push GeoJSON will watch this.
final mapControllerProvider = StateProvider<MapboxMap?>((ref) => null);
