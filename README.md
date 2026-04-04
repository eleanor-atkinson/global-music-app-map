# Global Music Map

A mobile app for discovering independent concerts — Snap Map style, for live music.

> Flutter · Mapbox · Supabase · PostGIS · Riverpod

---

<!-- Drop a GIF of the app here once you have one -->
<!-- ![App demo](assets/demo.gif) -->

---

## What it does

- Full-screen interactive map that loads concerts for whatever is currently visible on screen
- Markers cluster at low zoom levels and expand as you zoom in
- Tap a marker to slide up a detail sheet — artist, genre, venue, date, and a ticket link
- Live data from a PostGIS-backed Supabase database, fetched on every camera move (debounced)

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter (Dart) |
| Map | Mapbox Maps Flutter SDK |
| State management | Riverpod |
| Backend / database | Supabase · PostgreSQL · PostGIS |
| Serialisation | Freezed · json_serializable |

## Architecture

Feature-first clean architecture:

```
lib/
  features/map/
    data/         — Supabase RPC source, GeoJSON models, repository impl
    domain/       — Concert entity, repository interface, use cases
    presentation/
      providers/  — Riverpod state
      screens/    — MapScreen
      widgets/    — ConcertDetailSheet
  core/
    config/       — env flags, Mapbox config
    theme/
```

Key decisions:
- **Viewport-driven fetching** — `fetch_concerts_in_bounds` PostGIS RPC is called (debounced 400ms) on every camera move, so only visible data is loaded
- **Native clustering** — Mapbox's built-in `cluster: true` on the GeoJSON source handles merging with no extra network calls
- **Animated sheet** — `DraggableScrollableSheet` + `SlideTransition` with easeOutCubic; snaps between 42% and 92% screen height

## Running locally

**Prerequisites:**
- Flutter SDK ≥ 3.19
- A [Mapbox](https://mapbox.com) account (public token)
- A [Supabase](https://supabase.com) project with the PostGIS migration applied (`supabase/migrations/001_concerts.sql`)

**Setup:**

```bash
# 1. Install dependencies
flutter pub get

# 2. Create your env file from the template and fill in your tokens
cp env/dev.json.example env/dev.json

# 3. Run on iOS Simulator
make dev
```

The `make dev` target boots the simulator, handles iOS signing automatically, and attaches Flutter for hot reload.

## Database

Migrations live in `supabase/migrations/`. The key function:

```sql
fetch_concerts_in_bounds(west, south, east, north)
-- Returns a GeoJSON FeatureCollection of upcoming published concerts
-- within the supplied bounding box. Uses a PostGIS GIST index.
```

## Roadmap

- [ ] Search and filter by genre
- [ ] User location — centre map and show nearby shows
- [ ] Artist thumbnail markers
- [ ] User-submitted concert listings
- [ ] Push notifications for nearby shows
