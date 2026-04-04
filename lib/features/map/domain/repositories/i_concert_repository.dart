import '../entities/concert.dart';

/// Viewport bounds passed to every spatial query.
class ViewportBounds {
  const ViewportBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;
}

/// Result returned from a viewport fetch.
/// Both consumers are satisfied in one round-trip:
///   [geoJson]  → injected directly into Mapbox GeoJsonSource
///   [concerts] → used by tap handler → detail sheet
class ConcertViewportResult {
  const ConcertViewportResult({
    required this.geoJson,
    required this.concerts,
  });

  final String geoJson;
  final List<Concert> concerts;
}

/// Domain contract — no infrastructure imports cross this boundary.
abstract interface class IConcertRepository {
  Future<ConcertViewportResult> fetchInViewport(ViewportBounds bounds);
}
