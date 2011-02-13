-- Convert schema 'sql/_source/deploy/4/001-auto.yml' to 'sql/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE task ADD UNIQUE task_projectid (projectid);

;

COMMIT;

