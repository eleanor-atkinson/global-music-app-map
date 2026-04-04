import '../../domain/repositories/i_concert_repository.dart';
import '../sources/supabase_concert_source.dart';

/// Concrete implementation of [IConcertRepository].
/// Translates [SupabaseConcertResult] → [ConcertViewportResult] so the
/// domain and presentation layers never touch Supabase directly.
class ConcertRepository implements IConcertRepository {
  const ConcertRepository(this._source);

  final SupabaseConcertSource _source;

  @override
  Future<ConcertViewportResult> fetchInViewport(ViewportBounds bounds) async {
    final result = await _source.fetchInBounds(
      west: bounds.west,
      south: bounds.south,
      east: bounds.east,
      north: bounds.north,
    );

    return ConcertViewportResult(
      geoJson: result.geoJson,
      concerts: result.features.map((f) => f.toDomain()).toList(),
    );
  }
}
