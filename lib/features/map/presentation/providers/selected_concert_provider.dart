import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/concert.dart';

/// Holds the concert the user tapped on the map.
/// Null means no sheet is open.
final selectedConcertProvider = StateProvider<Concert?>((ref) => null);
