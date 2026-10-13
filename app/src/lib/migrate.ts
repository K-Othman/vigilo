import { pool } from "./db";

const schema = `
  CREATE TABLE IF NOT EXISTS sites (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT NOT NULL,
    url         TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  CREATE TABLE IF NOT EXISTS checks (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id           BIGINT NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    is_up             BOOLEAN NOT NULL,
    status_code       INTEGER,
    response_time_ms  INTEGER,
    error             TEXT,
    checked_at        TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  CREATE INDEX IF NOT EXISTS checks_site_time_idx ON checks (site_id, checked_at DESC);

  INSERT INTO sites (name, url) VALUES
    ('Example',     'https://example.com'),
    ('GitHub',      'https://github.com'),
    ('Broken site', 'https://this-site-does-not-exist.invalid')
  ON CONFLICT (url) DO NOTHING;
`;

export async function migrate() {
  await pool.query(schema);
}