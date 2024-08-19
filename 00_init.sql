-- 00_init.sql

-- Crear la base de datos book-store
CREATE DATABASE "books-store";

-- Conectarse a la base de datos book-store
\c "books-store";

-- Crear el Enum file_kind
CREATE TYPE file_kind AS ENUM ('FILE', 'COMIC-MANGA', 'EPUB', 'NONE');

-- Crear la tabla scan_root
CREATE TABLE scan_root (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    path VARCHAR UNIQUE NOT NULL,
    directories TEXT NOT NULL
);

-- Crear la tabla archive
CREATE TABLE archive (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    "parentPath" VARCHAR NOT NULL,
    "parentHash" VARCHAR NOT NULL,
    "localDetails" JSONB,
    "webDetails" JSONB,
    "customDetails" BOOLEAN NOT NULL DEFAULT FALSE,
    "size" VARCHAR NOT NULL,
    "coverId" VARCHAR NOT NULL,
    scan_root_id INTEGER REFERENCES scan_root(id)
    fileKind file_kind NOT NULL
);

-- Crear la extensión pg_trgm y pgcrypto
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Crear índices para la tabla archive
CREATE INDEX idx_archive_parentHash ON archive("parentHash");
CREATE INDEX idx_archive_name ON archive(name);
CREATE INDEX idx_archive_id ON archive(id);
CREATE INDEX idx_archive_scan_root_id ON archive(scan_root_id);
CREATE INDEX idx_archive_localDetails_text ON archive USING gin((localDetails::text) gin_trgm_ops);
CREATE INDEX idx_archive_webDetails_text ON archive USING gin((webDetails::text) gin_trgm_ops);
