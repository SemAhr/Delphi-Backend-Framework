CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE IF NOT EXISTS gender AS ENUM ('N/A', 'H', 'M', 'X');

CREATE TYPE IF NOT EXISTS report_status AS ENUM (
    'RECEIVED',
    'ACTIVE',
    'PHASE_1_IN_PROGRESS',
    'PHASE_2_IN_PROGRESS',
    'PHASE_2_COMPLETED',
    'CONTINUOUS_SEARCH',
    'DEACTIVATED',
    'ERROR'
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reports (
    id TEXT PRIMARY KEY NOT NULL,
    curp TEXT NOT NULL,

    first_name TEXT,
    last_name TEXT,
    second_last_name TEXT,

    birth_date DATE,
    disappearance_date DATE,
    report_date DATE,

    birth_place TEXT,
    gender gender DEFAULT 'N/A',

    status report_status DEFAULT 'RECEIVED',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
