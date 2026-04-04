import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/extensions/debouncer.dart';
import '../../domain/repositories/i_concert_repository.dart';
import '../providers/concerts_provider.dart';
import '../providers/map_controller_provider.dart';
import '../providers/selected_concert_provider.dart';
import '../widgets/concert_detail_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 400));

  // ── Style URI ────────────────────────────────────────────────────────────

  String get _styleUri {
    if (Env.isProd) return MapConfig.styleUriProd;
    if (Env.isUat) return MapConfig.styleUriUat;
    return MapConfig.styleUriDev;
  }

  static final _initialCamera = CameraOptions(
    center: Point(
      coordinates: Position(MapConfig.initialLng, MapConfig.initialLat),
    ),
    zoom: MapConfig.initialZoom,
    pitch: 0.0,
    bearing: 0.0,
  );

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  // ── Map initialisation ───────────────────────────────────────────────────

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    ref.read(mapControllerProvider.notifier).state = map;

    await Future.wait([
      map.compass.updateSettings(CompassSettings(enabled: false)),
      map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
      map.attribution.updateSettings(
        AttributionSettings(marginBottom: 8, marginRight: 8),
      ),
      map.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: false,
          pitchEnabled: false,
          doubleTapToZoomInEnabled: true,
          doubleTouchToZoomOutEnabled: true,
          quickZoomEnabled: true,
        ),
      ),
      map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: 0xFF6366F1,
        ),
      ),
    ]);

    await _setupLayers(map);
  }

  // ── Layer setup ──────────────────────────────────────────────────────────

  Future<void> _setupLayers(MapboxMap map) async {
    await map.style.addSource(
      GeoJsonSource(
        id: MapConfig.concertsSourceId,
        data: '{"type":"FeatureCollection","features":[]}',
        cluster: true,
        clusterMaxZoom: MapConfig.clusterMaxZoom,
        clusterRadius: MapConfig.clusterRadius.toDouble(),
      ),
    );

    await map.style.addLayer(
      CircleLayer(
        id: MapConfig.clusterLayerId,
        sourceId: MapConfig.concertsSourceId,
        filter: ['has', 'point_count'],
        circleColor: 0xFF6366F1,
        circleRadius: 22.0,
        circleStrokeWidth: 2.0,
        circleStrokeColor: 0xFFFFFFFF,
        circleOpacity: 0.9,
      ),
    );

    await map.style.addLayer(
      SymbolLayer(
        id: MapConfig.clusterCountLayerId,
        sourceId: MapConfig.concertsSourceId,
        filter: ['has', 'point_count'],
        textField: '{point_count_abbreviated}',
        textSize: 13.0,
        textColor: 0xFFFFFFFF,
        textIgnorePlacement: true,
        textAllowOverlap: true,
      ),
    );

    await map.style.addLayer(
      CircleLayer(
        id: MapConfig.markerLayerId,
        sourceId: MapConfig.concertsSourceId,
        filter: ['!', ['has', 'point_count']],
        circleColor: 0xFF6366F1,
        circleRadius: 10.0,
        circleStrokeWidth: 2.0,
        circleStrokeColor: 0xFFFFFFFF,
        circleOpacity: 1.0,
      ),
    );

    await _fetchForCurrentViewport();
  }

  // ── Camera change handler ────────────────────────────────────────────────

  void _onCameraChanged(CameraChangedEventData _) {
    _debouncer.call(_fetchForCurrentViewport);
  }

  Future<void> _fetchForCurrentViewport() async {
    final map = _map;
    if (map == null) return;

    final cameraState = await map.getCameraState();
    final cameraOptions = CameraOptions(
      center: cameraState.center,
      zoom: cameraState.zoom,
      bearing: cameraState.bearing,
      pitch: cameraState.pitch,
    );
    final bounds = await map.coordinateBoundsForCamera(cameraOptions);

    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;

    await ref.read(concertsProvider.notifier).fetch(
          ViewportBounds(
            west: (sw[0] as num).toDouble(),
            south: (sw[1] as num).toDouble(),
            east: (ne[0] as num).toDouble(),
            north: (ne[1] as num).toDouble(),
          ),
        );
  }

  // ── Tap handler ──────────────────────────────────────────────────────────

  Future<void> _onMapTap(MapContentGestureContext context) async {
    final map = _map;
    if (map == null) return;

    // Query rendered features within a small box around the tap point
    final x = context.touchPosition.x;
    final y = context.touchPosition.y;
    const hitSlop = 20.0;

    final features = await map.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenBox(
        ScreenBox(
          min: ScreenCoordinate(x: x - hitSlop, y: y - hitSlop),
          max: ScreenCoordinate(x: x + hitSlop, y: y + hitSlop),
        ),
      ),
      RenderedQueryOptions(
        layerIds: [MapConfig.markerLayerId],
      ),
    );

    if (features.isEmpty) {
      // Tapped empty map — dismiss sheet
      ref.read(selectedConcertProvider.notifier).state = null;
      return;
    }

    // Extract the concert id from the tapped feature's properties
    final props = features.first?.queriedFeature.feature['properties']
        as Map<Object?, Object?>?;
    final id = props?['id'] as String?;
    if (id == null) return;

    // Look up the full Concert from the in-memory list
    final result = ref.read(concertsProvider).valueOrNull;
    final concert = result?.concerts.where((c) => c.id == id).firstOrNull;
    if (concert == null) return;

    ref.read(selectedConcertProvider.notifier).state = concert;
  }

  // ── React to new concert data ────────────────────────────────────────────

  Future<void> _updateGeoJsonSource(String geoJson) async {
    final map = _map;
    if (map == null) return;

    final hasSource = await map.style.styleSourceExists(MapConfig.concertsSourceId);
    if (!hasSource) return;

    final source = await map.style
        .getSource(MapConfig.concertsSourceId) as GeoJsonSource?;
    await source?.updateGeoJSON(geoJson);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen(concertsProvider, (_, next) {
      next.whenData((result) {
        if (result != null) _updateGeoJsonSource(result.geoJson);
      });
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('concert_map'),
            styleUri: _styleUri,
            cameraOptions: _initialCamera,
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChanged,
            onTapListener: _onMapTap,
          ),
          _LoadingIndicator(),
          _ErrorBanner(),
          const ConcertDetailSheet(),
        ],
      ),
    );
  }
}

// ── Small overlay widgets ────────────────────────────────────────────────────

class _LoadingIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      concertsProvider.select((s) => s.isLoading),
    );
    if (!isLoading) return const SizedBox.shrink();
    return const Positioned(
      top: 56,
      right: 16,
      child: SafeArea(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      concertsProvider.select((s) => s.hasError ? s.error : null),
    );
    if (error == null) return const SizedBox.shrink();
    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
          ),
          child: Text(
            'Could not load concerts. Check your connection.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
