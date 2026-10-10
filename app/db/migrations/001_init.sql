CREATE TABLE sites (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        TEXT NOT NULL,
  url         TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE checks (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  site_id           BIGINT NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  is_up             BOOLEAN NOT NULL,
  status_code       INTEGER,
  response_time_ms  INTEGER,
  error             TEXT,
  checked_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX checks_site_time_idx ON checks (site_id, checked_at DESC);