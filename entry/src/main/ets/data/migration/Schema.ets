export const SCHEMA_VERSION: number = 1;

export const SCHEMA_V1: string[] = [
  `CREATE TABLE places (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 120),
    normalized_name TEXT NOT NULL,
    latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
    longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
    coordinate_system TEXT NOT NULL CHECK(coordinate_system IN ('WGS84','GCJ02')),
    address TEXT NOT NULL DEFAULT '', country TEXT NOT NULL DEFAULT '', country_code TEXT NOT NULL DEFAULT '',
    province TEXT NOT NULL DEFAULT '', city TEXT NOT NULL DEFAULT '', district TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
    UNIQUE(normalized_name, latitude, longitude, coordinate_system))`,
  `CREATE TABLE visits (
    id TEXT PRIMARY KEY NOT NULL,
    place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    visited_at INTEGER NOT NULL CHECK(visited_at >= 0),
    local_date TEXT NOT NULL, utc_offset_minutes INTEGER NOT NULL,
    diary TEXT NOT NULL DEFAULT '' CHECK(length(diary) <= 100000),
    mood INTEGER NOT NULL DEFAULT 0 CHECK(mood BETWEEN 0 AND 5),
    source TEXT NOT NULL CHECK(source IN ('current_location','map_selection','existing_place')),
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)`,
  'CREATE INDEX visits_place_time ON visits(place_id, visited_at DESC, id)',
  'CREATE INDEX visits_time ON visits(visited_at, id)',
  'CREATE INDEX places_city ON places(city)',
  'CREATE INDEX places_country ON places(country_code)',
  'CREATE INDEX places_coordinate ON places(coordinate_system, latitude, longitude)'
];

export const PLACE_SUMMARY_SQL: string = `SELECT p.*, COUNT(v.id) AS visit_count,
  GROUP_CONCAT(DISTINCT SUBSTR(v.local_date, 1, 4)) AS visited_years,
  COALESCE(MIN(v.visited_at), 0) AS first_visited_at, COALESCE(MAX(v.visited_at), 0) AS last_visited_at
  FROM places p LEFT JOIN visits v ON v.place_id = p.id`;
