-- Convert schema 'sql/_source/deploy/3/001-auto.yml' to 'sql/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE task DROP CONSTRAINT task_projectid;

;

COMMIT;

