-- ============================================================
-- Migration 001: Concerts table with PostGIS spatial support
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Step 1: Enable PostGIS (already available on Supabase, just needs enabling)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- Table
-- ============================================================

CREATE TABLE IF NOT EXISTS concerts (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_name    TEXT        NOT NULL,
  genre          TEXT        NOT NULL,
  event_date     TIMESTAMPTZ NOT NULL,
  venue_name     TEXT        NOT NULL,

  -- geography type stores lon/lat in WGS84 (SRID 4326).
  -- Use geography (not geometry) so ST_DWithin distances are in metres.
  location       GEOGRAPHY(Point, 4326) NOT NULL,

  thumbnail_url  TEXT,
  ticket_url     TEXT,
  is_published   BOOLEAN     NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================

-- GIST spatial index — makes ST_DWithin / ST_Within O(log n)
CREATE INDEX IF NOT EXISTS concerts_location_idx
  ON concerts USING GIST(location);

-- Partial index on published concerts — the hot path for all queries
-- Cannot use NOW() in index predicate (not immutable); date filtering
-- is handled by the RPC WHERE clause instead
CREATE INDEX IF NOT EXISTS concerts_upcoming_published_idx
  ON concerts (event_date)
  WHERE is_published = true;

-- ============================================================
-- updated_at trigger
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER concerts_updated_at
  BEFORE UPDATE ON concerts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- RPC: fetch_concerts_in_bounds
-- Returns a GeoJSON FeatureCollection of upcoming published
-- concerts within the given map viewport bounding box.
-- Called by SupabaseConcertSource.fetchInBounds()
-- ============================================================

CREATE OR REPLACE FUNCTION fetch_concerts_in_bounds(
  west  FLOAT,
  south FLOAT,
  east  FLOAT,
  north FLOAT
)
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER  -- runs as owner, so RLS SELECT policy applies to callers
AS $$
  SELECT json_build_object(
    'type', 'FeatureCollection',
    'features', COALESCE(
      json_agg(
        json_build_object(
          'type',     'Feature',
          'geometry', ST_AsGeoJSON(c.location)::json,
          'properties', json_build_object(
            'id',            c.id,
            'artist',        c.artist_name,
            'genre',         c.genre,
            'date',          c.event_date,
            'venue',         c.venue_name,
            'thumbnail_url', c.thumbnail_url,
            'ticket_url',    c.ticket_url
          )
        )
      ),
      '[]'::json
    )
  )
  FROM concerts c
  WHERE
    c.is_published = true
    AND c.event_date >= NOW()
    AND c.location && ST_MakeEnvelope(west, south, east, north, 4326);
$$;

-- Grant execute to the anon role (used by the Flutter app's anon key)
GRANT EXECUTE ON FUNCTION fetch_concerts_in_bounds(FLOAT, FLOAT, FLOAT, FLOAT)
  TO anon;

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE concerts ENABLE ROW LEVEL SECURITY;

-- Anyone (including unauthenticated anon key) can read published concerts
CREATE POLICY "Published concerts are publicly readable"
  ON concerts
  FOR SELECT
  USING (is_published = true);

-- Only the service_role (your admin scripts / backend) can write
-- No INSERT/UPDATE/DELETE policy for anon or authenticated roles
-- = denied by default

-- ============================================================
-- Seed: a few test concerts for dev (delete before UAT)
-- ============================================================

INSERT INTO concerts
  (artist_name, genre, event_date, venue_name, location, thumbnail_url, is_published)
VALUES
  ('Turnstile',    'hardcore',  NOW() + INTERVAL '3 days',  'The Roxy, Los Angeles',
   ST_Point(-118.3617, 34.0983)::geography, NULL, true),

  ('IDLES',        'post-punk', NOW() + INTERVAL '5 days',  'Brixton Academy, London',
   ST_Point(-0.1132, 51.4614)::geography,   NULL, true),

  ('Amyl and the Sniffers', 'punk', NOW() + INTERVAL '7 days', 'Corner Hotel, Melbourne',
   ST_Point(144.9971, -37.8182)::geography, NULL, true),

  ('Militarie Gun', 'hardcore', NOW() + INTERVAL '10 days', 'Bottom of the Hill, SF',
   ST_Point(-122.4063, 37.7521)::geography, NULL, true),

  ('Portrayal of Guilt', 'black metal', NOW() + INTERVAL '14 days', 'Club ATP, Berlin',
   ST_Point(13.4050, 52.5200)::geography,   NULL, true);
