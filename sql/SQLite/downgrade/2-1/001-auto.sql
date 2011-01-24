-- Convert schema 'sql/_source/deploy/2/001-auto.yml' to 'sql/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE task_temp_alter (
  taskid INTEGER PRIMARY KEY NOT NULL,
  sha256 text NOT NULL,
  projectid int NOT NULL
);

;
INSERT INTO task_temp_alter SELECT taskid, sha256, projectid FROM task;

;
DROP TABLE task;

;
CREATE TABLE task (
  taskid INTEGER PRIMARY KEY NOT NULL,
  sha256 text NOT NULL,
  projectid int NOT NULL
);

;
CREATE INDEX task_idx_sha25602 ON task (sha256);

;
CREATE INDEX task_idx_projectid02 ON task (projectid);

;
CREATE UNIQUE INDEX task_projectid02 ON task (projectid);

;
CREATE UNIQUE INDEX task_sha25602 ON task (sha256);

;
INSERT INTO task SELECT taskid, sha256, projectid FROM task_temp_alter;

;
DROP TABLE task_temp_alter;

;

COMMIT;

