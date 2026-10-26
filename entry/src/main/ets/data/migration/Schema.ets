export const SCHEMA_VERSION: number = 4;

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

// ArkData transaction connections do not inherit a store connection's foreign_keys PRAGMA.
// Schema triggers enforce the same relationship on every connection, including new transactions.
export const SCHEMA_V2: string[] = [
  `CREATE TRIGGER IF NOT EXISTS visits_parent_insert BEFORE INSERT ON visits
    WHEN NOT EXISTS (SELECT 1 FROM places WHERE id = NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Visit requires an existing Place'); END`,
  `CREATE TRIGGER IF NOT EXISTS visits_parent_update BEFORE UPDATE OF place_id ON visits
    WHEN NOT EXISTS (SELECT 1 FROM places WHERE id = NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Visit requires an existing Place'); END`,
  `CREATE TRIGGER IF NOT EXISTS places_visit_cascade AFTER DELETE ON places
    BEGIN DELETE FROM visits WHERE place_id = OLD.id; END`,
  `CREATE TRIGGER IF NOT EXISTS places_identity_guard BEFORE UPDATE OF id ON places
    WHEN OLD.id != NEW.id AND EXISTS (SELECT 1 FROM visits WHERE place_id = OLD.id)
    BEGIN SELECT RAISE(ABORT, 'Place identity is stable'); END`
];


export const SCHEMA_V3: string[] = [
  `CREATE TABLE activities (
    id TEXT PRIMARY KEY NOT NULL, local_date TEXT NOT NULL,
    title TEXT NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 120),
    category_id TEXT NOT NULL CHECK(category_id IN ('work','study','life','exercise','rest','travel','other')),
    start_minute INTEGER NOT NULL CHECK(start_minute BETWEEN 0 AND 1439),
    end_minute INTEGER NOT NULL CHECK(end_minute > start_minute AND end_minute <= 1440),
    place_id TEXT REFERENCES places(id) ON DELETE SET NULL,
    note TEXT NOT NULL DEFAULT '' CHECK(length(note) <= 10000),
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)`,
  `CREATE TRIGGER activities_place_identity BEFORE UPDATE OF id ON places
    WHEN OLD.id != NEW.id AND EXISTS (SELECT 1 FROM activities WHERE place_id=OLD.id)
    BEGIN SELECT RAISE(ABORT, 'Place identity is stable'); END`,
  'CREATE INDEX activities_date_time ON activities(local_date,start_minute,id)',
  'CREATE INDEX activities_title_date ON activities(title,local_date)',
  `CREATE TRIGGER activities_place_insert BEFORE INSERT ON activities
    WHEN NEW.place_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM places WHERE id=NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Activity requires an existing Place'); END`,
  `CREATE TRIGGER activities_place_update BEFORE UPDATE OF place_id ON activities
    WHEN NEW.place_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM places WHERE id=NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Activity requires an existing Place'); END`,
  `CREATE TRIGGER activities_place_delete AFTER DELETE ON places
    BEGIN UPDATE activities SET place_id=NULL WHERE place_id=OLD.id; END`,
  `CREATE TRIGGER activities_overlap_insert BEFORE INSERT ON activities
    WHEN EXISTS (SELECT 1 FROM activities WHERE local_date=NEW.local_date AND id!=NEW.id
      AND start_minute<NEW.end_minute AND end_minute>NEW.start_minute)
    BEGIN SELECT RAISE(ABORT, 'Activity time overlap'); END`,
  `CREATE TRIGGER activities_overlap_update BEFORE UPDATE ON activities
    WHEN EXISTS (SELECT 1 FROM activities WHERE local_date=NEW.local_date AND id!=NEW.id
      AND start_minute<NEW.end_minute AND end_minute>NEW.start_minute)
    BEGIN SELECT RAISE(ABORT, 'Activity time overlap'); END`
];


// Preserve UUIDs and all note fields while allowing overnight and point entries.
export const SCHEMA_V4: string[] = [
  'DROP TRIGGER activities_place_identity',
  'DROP TRIGGER activities_place_insert',
  'DROP TRIGGER activities_place_update',
  'DROP TRIGGER activities_place_delete',
  'DROP TRIGGER activities_overlap_insert',
  'DROP TRIGGER activities_overlap_update',
  `CREATE TABLE activities_v4 (
    id TEXT PRIMARY KEY NOT NULL, local_date TEXT NOT NULL,
    title TEXT NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 120),
    category_id TEXT NOT NULL CHECK(category_id IN ('work','study','life','exercise','rest','travel','other')),
    start_minute INTEGER NOT NULL CHECK(start_minute BETWEEN 0 AND 2879),
    end_minute INTEGER NOT NULL CHECK(end_minute >= start_minute AND end_minute <= 2880),
    place_id TEXT REFERENCES places(id) ON DELETE SET NULL,
    note TEXT NOT NULL DEFAULT '' CHECK(length(note) <= 10000),
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)`,
  `INSERT INTO activities_v4 (id,local_date,title,category_id,start_minute,end_minute,place_id,note,created_at,updated_at)
    SELECT id,local_date,title,category_id,start_minute,end_minute,place_id,note,created_at,updated_at FROM activities`,
  'DROP TABLE activities',
  'ALTER TABLE activities_v4 RENAME TO activities',
  'CREATE INDEX activities_date_time ON activities(local_date,start_minute,id)',
  'CREATE INDEX activities_title_date ON activities(title,local_date)',
  `CREATE TRIGGER activities_place_identity BEFORE UPDATE OF id ON places
    WHEN OLD.id != NEW.id AND EXISTS (SELECT 1 FROM activities WHERE place_id=OLD.id)
    BEGIN SELECT RAISE(ABORT, 'Place identity is stable'); END`,
  `CREATE TRIGGER activities_place_insert BEFORE INSERT ON activities
    WHEN NEW.place_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM places WHERE id=NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Activity requires an existing Place'); END`,
  `CREATE TRIGGER activities_place_update BEFORE UPDATE OF place_id ON activities
    WHEN NEW.place_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM places WHERE id=NEW.place_id)
    BEGIN SELECT RAISE(ABORT, 'Activity requires an existing Place'); END`,
  `CREATE TRIGGER activities_place_delete AFTER DELETE ON places
    BEGIN UPDATE activities SET place_id=NULL WHERE place_id=OLD.id; END`,
  `CREATE TABLE day_routines (
    local_date TEXT PRIMARY KEY NOT NULL,
    wake_minute INTEGER CHECK(wake_minute BETWEEN 0 AND 1439),
    sleep_minute INTEGER CHECK(sleep_minute BETWEEN 0 AND 2880),
    updated_at INTEGER NOT NULL,
    CHECK(wake_minute IS NULL OR sleep_minute IS NULL OR sleep_minute > wake_minute))`
];
