-- supervisors table
CREATE TABLE supervisors (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT
);

-- test_users table
CREATE TABLE test_users (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT,
  age INTEGER NOT NULL,
  supervisor_id INTEGER NOT NULL
    REFERENCES supervisors(id)
);

CREATE INDEX ix_test_users_supervisor_id
  ON test_users(supervisor_id);

-- journals table
CREATE TABLE journals (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL
    REFERENCES test_users(id),
  description TEXT,
  supervisor_id INTEGER NOT NULL
    REFERENCES supervisors(id)
);

CREATE INDEX ix_journals_user_id
  ON journals(user_id);
CREATE INDEX ix_journals_supervisor_id
  ON journals(supervisor_id);

-- experiences table
CREATE TABLE experiences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL
    REFERENCES test_users(id),
  app_id INTEGER,
  rating INTEGER,
  description TEXT,
  supervisor_id INTEGER NOT NULL
    REFERENCES supervisors(id)
);

CREATE INDEX ix_experiences_user_id
  ON experiences(user_id);
CREATE INDEX ix_experiences_app_id
  ON experiences(app_id);
CREATE INDEX ix_experiences_rating
  ON experiences(rating);
CREATE INDEX ix_experiences_supervisor_id
  ON experiences(supervisor_id);