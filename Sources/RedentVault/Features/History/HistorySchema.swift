/// Versioned SQL for aggregate pages and contextual navigation events.
enum HistorySchema {
    static let version = 1

    static let pragmas = """
    PRAGMA journal_mode=WAL;
    PRAGMA synchronous=NORMAL;
    """

    static let createAggregateTable = """
    CREATE TABLE IF NOT EXISTS visits (
      id TEXT PRIMARY KEY, url TEXT NOT NULL UNIQUE, host TEXT NOT NULL,
      title TEXT NOT NULL DEFAULT '', visit_count INTEGER NOT NULL DEFAULT 1,
      last_visit REAL NOT NULL, unknown_count INTEGER NOT NULL DEFAULT 0);
    CREATE INDEX IF NOT EXISTS visits_last_visit ON visits(last_visit DESC);
    CREATE INDEX IF NOT EXISTS visits_host ON visits(host);
    """

    static let createContextualTable = """
    CREATE TABLE IF NOT EXISTS contextual_visits (
      navigation_id TEXT PRIMARY KEY, url TEXT NOT NULL, host TEXT NOT NULL,
      title TEXT NOT NULL DEFAULT '', tab_id TEXT, space_id TEXT,
      container_id TEXT, visited_at REAL NOT NULL);
    CREATE INDEX IF NOT EXISTS contextual_visits_url ON contextual_visits(url);
    CREATE INDEX IF NOT EXISTS contextual_visits_space ON contextual_visits(space_id);
    CREATE INDEX IF NOT EXISTS contextual_visits_container ON contextual_visits(container_id);
    CREATE INDEX IF NOT EXISTS contextual_visits_host ON contextual_visits(host);
    """

    static let columns = "id, url, host, title, visit_count, last_visit"
}
