-- Convert schema 'sql/_source/deploy/4/001-auto.yml' to 'sql/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE UNIQUE INDEX task_projectid ON task (projectid);

;

COMMIT;

