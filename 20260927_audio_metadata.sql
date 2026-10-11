-- Additive migration. Run only against the Libretorio database, with a backup.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE TABLE audio_metadata (
    archive_id integer NOT NULL REFERENCES archive(id) ON DELETE CASCADE,
    relative_path text NOT NULL,
    source_signature text NOT NULL,
    extractor_version text NOT NULL,
    status text NOT NULL CHECK (status IN ('pending','processing','ready','needs_review','failed')),
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    job_token uuid,
    lease_until timestamptz,
    retry_after timestamptz,
    duration_seconds double precision,
    chapters jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(chapters) = 'array'),
    details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(details) = 'object'),
    last_error text,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (archive_id, relative_path),
    CHECK (duration_seconds IS NULL OR (duration_seconds > 0 AND duration_seconds < 'Infinity'::float8)),
    CHECK (relative_path !~ '(^/|(^|/)\.\.(/|$))')
);
COMMENT ON TABLE audio_metadata IS 'Regenerable technical audio metadata; no user progress or bibliographic metadata.';
COMMIT;
