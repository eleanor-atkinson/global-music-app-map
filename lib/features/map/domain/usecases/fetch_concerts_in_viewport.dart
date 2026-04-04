import '../repositories/i_concert_repository.dart';

export '../repositories/i_concert_repository.dart'
    show ConcertViewportResult, ViewportBounds;

/// Single-responsibility use case: fetch concerts visible in the current
/// map viewport and return both the raw GeoJSON (for Mapbox) and the
/// parsed domain entities (for UI).
class FetchConcertsInViewport {
  const FetchConcertsInViewport(this._repository);

  final IConcertRepository _repository;

  Future<ConcertViewportResult> call(ViewportBounds bounds) =>
      _repository.fetchInViewport(bounds);
}
