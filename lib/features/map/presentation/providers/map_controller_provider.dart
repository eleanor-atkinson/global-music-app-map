import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Holds the live MapboxMap controller once the map widget calls onMapCreated.
/// Providers that need to push GeoJSON (ConcertsNotifier) watch this.
final mapControllerProvider = StateProvider<MapboxMap?>((ref) => null);
