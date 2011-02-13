-- Convert schema 'sql/_source/deploy/1/001-auto.yml' to 'sql/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE task ADD COLUMN running bool NOT NULL DEFAULT '0';

;

COMMIT;

