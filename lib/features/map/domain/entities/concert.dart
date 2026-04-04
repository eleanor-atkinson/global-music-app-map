import 'package:freezed_annotation/freezed_annotation.dart';

part 'concert.freezed.dart';

/// Core domain entity. Framework-free — no Supabase or Mapbox imports.
/// Used by the UI (detail sheet, search results) and passed through use cases.
@freezed
class Concert with _$Concert {
  const factory Concert({
    required String id,
    required String artistName,
    required String genre,
    required DateTime eventDate,
    required String venueName,
    required double latitude,
    required double longitude,
    String? thumbnailUrl,
    String? ticketUrl,
  }) = _Concert;
}
