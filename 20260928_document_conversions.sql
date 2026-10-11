-- Additive, Libretorio only. Apply with ON_ERROR_STOP and a verified backup.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE document_conversion_runs (
    id uuid PRIMARY KEY,
    scan_root_id integer NOT NULL REFERENCES scan_root(id),
    upper_id integer NOT NULL,
    total integer NOT NULL CHECK (total >= 0),
    status text NOT NULL CHECK (status IN ('running','completed','completed_with_errors','interrupted','failed')),
    summary jsonb NOT NULL DEFAULT '{}'::jsonb,
    last_error text,
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);
CREATE TABLE document_conversions (
    archive_id integer PRIMARY KEY REFERENCES archive(id) ON DELETE CASCADE,
    run_id uuid NOT NULL REFERENCES document_conversion_runs(id),
    status text NOT NULL CHECK (status IN ('processing','ready','failed')),
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    retry_after timestamptz,
    details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(details) = 'object'),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX document_conversion_runs_root ON document_conversion_runs(scan_root_id, started_at);
COMMENT ON TABLE document_conversions IS 'Regenerable PDFs; absence of a row means not yet checked. Scanner is the only writer.';
COMMIT;
