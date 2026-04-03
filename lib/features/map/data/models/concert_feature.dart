import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/concert.dart';

part 'concert_feature.freezed.dart';

/// Represents a single GeoJSON Feature as returned by the
/// `fetch_concerts_in_bounds` Supabase RPC.
///
/// Keeps coordinates alongside properties so it can serve two consumers:
///   1. Mapbox — raw GeoJSON string passed directly to GeoJsonSource
///   2. UI     — parsed [ConcertFeature] list used by the tap → detail sheet
@freezed
class ConcertFeature with _$ConcertFeature {
  const ConcertFeature._();

  const factory ConcertFeature({
    required String id,
    required double longitude,
    required double latitude,
    required String artistName,
    required String genre,
    required DateTime eventDate,
    required String venueName,
    String? thumbnailUrl,
    String? ticketUrl,
  }) = _ConcertFeature;

  /// Parses a single GeoJSON Feature map from the Supabase RPC response.
  ///
  /// Expected shape:
  /// ```json
  /// {
  ///   "type": "Feature",
  ///   "geometry": { "type": "Point", "coordinates": [lng, lat] },
  ///   "properties": {
  ///     "id": "uuid",
  ///     "artist": "...", "genre": "...", "date": "ISO8601",
  ///     "venue": "...", "thumbnail_url": "...", "ticket_url": "..."
  ///   }
  /// }
  /// ```
  factory ConcertFeature.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final coords =
        ((feature['geometry'] as Map<String, dynamic>)['coordinates']
            as List<dynamic>);
    final props = feature['properties'] as Map<String, dynamic>;

    return ConcertFeature(
      id: props['id'] as String,
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
      artistName: props['artist'] as String? ?? '',
      genre: props['genre'] as String? ?? '',
      eventDate: DateTime.parse(props['date'] as String),
      venueName: props['venue'] as String? ?? '',
      thumbnailUrl: props['thumbnail_url'] as String?,
      ticketUrl: props['ticket_url'] as String?,
    );
  }

  /// Maps to the domain entity for use-case and UI consumption.
  Concert toDomain() => Concert(
        id: id,
        artistName: artistName,
        genre: genre,
        eventDate: eventDate,
        venueName: venueName,
        latitude: latitude,
        longitude: longitude,
        thumbnailUrl: thumbnailUrl,
        ticketUrl: ticketUrl,
      );
}
