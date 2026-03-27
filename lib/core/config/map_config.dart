/// Central map configuration constants.
abstract final class MapConfig {
  /// Mapbox Studio style URLs per environment.
  /// Replace with your actual style IDs from studio.mapbox.com
  static const styleUriDev =
      'mapbox://styles/your-username/your-dev-style-id';
  static const styleUriUat =
      'mapbox://styles/your-username/your-uat-style-id';
  static const styleUriProd =
      'mapbox://styles/your-username/your-prod-style-id';

  /// Initial camera — centred roughly on the world
  static const initialLng = 0.0;
  static const initialLat = 20.0;
  static const initialZoom = 2.0;

  /// Zoom thresholds
  static const clusterMaxZoom = 14.0; // clusters dissolve above this
  static const markerMinZoom = 1.0;

  /// Clustering
  static const clusterRadius = 50; // pixels

  /// GeoJSON source / layer IDs — single source of truth
  static const concertsSourceId = 'concerts-source';
  static const clusterLayerId = 'cluster-circles';
  static const clusterCountLayerId = 'cluster-count';
  static const markerLayerId = 'concert-markers';

  /// Default fallback marker image name (registered in MarkerImageService)
  static const fallbackMarkerImage = 'marker-default';
}
