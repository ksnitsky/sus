--- migration:up
CREATE TYPE task_status AS ENUM (
  'not_started',
  'in_progress',
  'completed',
  'paused'
);

CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status task_status NOT NULL DEFAULT 'not_started',
  time_spent_seconds INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

--- migration:down
DROP TABLE IF EXISTS tasks;
DROP TYPE IF EXISTS task_status;

--- migration:end
