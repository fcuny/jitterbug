-- Convert schema 'sql/_source/deploy/4/001-auto.yml' to 'sql/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE task ADD CONSTRAINT "task_projectid" UNIQUE (projectid);

;

COMMIT;

