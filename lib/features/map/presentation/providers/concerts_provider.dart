import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/concert_repository.dart';
import '../../data/sources/supabase_concert_source.dart';
import '../../domain/repositories/i_concert_repository.dart';
import '../../domain/usecases/fetch_concerts_in_viewport.dart';

// ── Infrastructure providers ─────────────────────────────────────────────────

final _supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final _concertSourceProvider = Provider<SupabaseConcertSource>(
  (ref) => SupabaseConcertSource(ref.watch(_supabaseClientProvider)),
);

final _concertRepositoryProvider = Provider<IConcertRepository>(
  (ref) => ConcertRepository(ref.watch(_concertSourceProvider)),
);

final _fetchConcertsUseCaseProvider = Provider<FetchConcertsInViewport>(
  (ref) => FetchConcertsInViewport(ref.watch(_concertRepositoryProvider)),
);

// ── State notifier ────────────────────────────────────────────────────────────

/// Holds the current viewport fetch result.
/// Phase 3 will call [fetch] from the camera-change listener.
class ConcertsNotifier extends AsyncNotifier<ConcertViewportResult?> {
  @override
  Future<ConcertViewportResult?> build() async => null;

  Future<void> fetch(ViewportBounds bounds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(_fetchConcertsUseCaseProvider).call(bounds),
    );
  }
}

final concertsProvider =
    AsyncNotifierProvider<ConcertsNotifier, ConcertViewportResult?>(
  ConcertsNotifier.new,
);
