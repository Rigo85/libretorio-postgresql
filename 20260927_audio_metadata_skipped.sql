-- Add a terminal, reusable outcome for media which is not an audiobook.
-- Run only in books-store, with the scanner idle and a backup available.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE audio_metadata DROP CONSTRAINT audio_metadata_status_check;
ALTER TABLE audio_metadata ADD CONSTRAINT audio_metadata_status_check
    CHECK (status IN ('pending','processing','ready','needs_review','failed','skipped'));
COMMIT;
