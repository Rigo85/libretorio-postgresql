-- 00_init.sql

-- Crear la base de datos book-store
CREATE DATABASE "books-store";

-- Conectarse a la base de datos book-store
\c "books-store";

-- Crear el Enum file_kind
CREATE TYPE file_kind AS ENUM ('FILE', 'COMIC-MANGA', 'EPUB', 'NONE', 'AUDIOBOOK');

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
    "name" VARCHAR NOT NULL,
    "parentPath" VARCHAR NOT NULL,
    "parentHash" VARCHAR NOT NULL,
    "fileHash" VARCHAR NOT NULL,
    "localDetails" JSONB,
    "webDetails" JSONB,
    "customDetails" BOOLEAN NOT NULL DEFAULT FALSE,
    "size" VARCHAR NOT NULL,
    "coverId" VARCHAR NOT NULL,
    scan_root_id INTEGER REFERENCES scan_root(id),
    "fileKind" file_kind NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Crear la extensión pg_trgm y pgcrypto
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Crear índices para la tabla archive
CREATE INDEX idx_archive_parentHash ON archive ("parentHash");
CREATE INDEX idx_archive_fileHash ON archive ("fileHash");
CREATE INDEX idx_archive_name ON archive (name);
CREATE INDEX idx_archive_id ON archive (id);
CREATE INDEX idx_archive_scan_root_id ON archive (scan_root_id);
CREATE INDEX idx_archive_localDetails_text ON archive USING gin(("localDetails"::text) gin_trgm_ops);
CREATE INDEX idx_archive_webDetails_text ON archive USING gin(("webDetails"::text) gin_trgm_ops);
CREATE INDEX idx_archive_createdAt ON archive("createdAt");

-- Crear la extensión uuid-ossp para generar UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Crear la tabla users
CREATE TABLE users (
    id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL CHECK (email ~* '^[^@]+@[^@]+\.[^@]+$') ,
    password_hash TEXT NOT NULL,
    is_admin      BOOLEAN DEFAULT FALSE,
    prefs         JSONB  DEFAULT '{}'::jsonb,
    is_active      BOOLEAN DEFAULT TRUE,
    session_id TEXT DEFAULT NULL,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- Tabla para registrar los inicios de sesión de los usuarios
CREATE TABLE user_logins (
    id         BIGSERIAL PRIMARY KEY,
    user_id    UUID REFERENCES users (id),
    ip         INET,
    user_agent TEXT,
    logged_at  TIMESTAMPTZ DEFAULT now()
);

-- Tabla para registrar auditoría de acciones de los usuarios
CREATE TABLE audit_logs (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES users(id),
  entity_name TEXT    NOT NULL,
  entity_id   UUID    NULL,
  action      TEXT    NOT NULL,
  changes     JSONB   DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Crear la tabla session para manejar sesiones de usuario
CREATE TABLE "session" (
   "sid" varchar NOT NULL,
   "sess" jsonb NOT NULL,
   "expire" timestamp(6) NOT NULL,
   CONSTRAINT "session_pkey" PRIMARY KEY ("sid")
);

-- Crear índices para la tabla session
CREATE INDEX "IDX_session_expire" ON "session" ("expire");

-- Crear índices para la tabla users
CREATE INDEX idx_users_email_ci ON users (LOWER(email));
CREATE INDEX idx_users_admin_true ON users (id) WHERE is_admin;
CREATE INDEX idx_users_prefs_gin ON users USING GIN (prefs jsonb_path_ops);
CREATE INDEX idx_users_is_active ON users (is_active);


-- Crear índices para la tabla user_logins
CREATE INDEX idx_logins_user_time ON user_logins (user_id, logged_at DESC);
CREATE INDEX idx_logins_time ON user_logins (logged_at);
CREATE INDEX idx_logins_ip ON user_logins (ip);

-- Crear índices para la tabla audit_logs
CREATE INDEX idx_audit_user_time ON audit_logs (user_id, created_at DESC);
