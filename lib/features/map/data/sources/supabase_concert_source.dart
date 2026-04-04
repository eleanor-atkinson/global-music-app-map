import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/concert_feature.dart';

/// Raw result from the Supabase RPC — kept in the data layer.
/// The repository maps this to the domain [ConcertViewportResult].
class SupabaseConcertResult {
  const SupabaseConcertResult({
    required this.geoJson,
    required this.features,
  });

  /// Raw GeoJSON FeatureCollection string — pass directly to Mapbox GeoJsonSource.
  final String geoJson;

  /// Parsed features — used to build the domain Concert list.
  final List<ConcertFeature> features;
}

/// Responsible for one thing: calling the Supabase RPC and returning the
/// raw GeoJSON alongside parsed features.
///
/// Does NOT know about domain entities or Mapbox — those concerns belong
/// to the repository and presentation layers respectively.
class SupabaseConcertSource {
  const SupabaseConcertSource(this._client);

  final SupabaseClient _client;

  Future<SupabaseConcertResult> fetchInBounds({
    required double west,
    required double south,
    required double east,
    required double north,
  }) async {
    final response = await _client.rpc(
      'fetch_concerts_in_bounds',
      params: {
        'west': west,
        'south': south,
        'east': east,
        'north': north,
      },
    );

    // response is already a decoded Map from supabase_flutter
    final featureCollection = response as Map<String, dynamic>;
    final rawFeatures =
        (featureCollection['features'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return SupabaseConcertResult(
      geoJson: jsonEncode(featureCollection),
      features: rawFeatures.map(ConcertFeature.fromGeoJsonFeature).toList(),
    );
  }
}
