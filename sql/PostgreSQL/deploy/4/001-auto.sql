-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun Feb 13 17:36:49 2011
-- 
;
--
-- Table: project
--
CREATE TABLE "project" (
  "projectid" serial NOT NULL,
  "name" text NOT NULL,
  "url" text NOT NULL,
  "description" text NOT NULL,
  "owner" text NOT NULL,
  PRIMARY KEY ("projectid"),
  CONSTRAINT "project_name" UNIQUE ("name")
);

;
--
-- Table: commit_push
--
CREATE TABLE "commit_push" (
  "sha256" text NOT NULL,
  "content" text NOT NULL,
  "projectid" integer NOT NULL,
  "timestamp" timestamp NOT NULL,
  PRIMARY KEY ("sha256")
);
CREATE INDEX "commit_push_idx_projectid" on "commit_push" ("projectid");

;
--
-- Table: task
--
CREATE TABLE "task" (
  "taskid" serial NOT NULL,
  "sha256" text NOT NULL,
  "projectid" integer NOT NULL,
  "running" bool DEFAULT '0' NOT NULL,
  "started_when" timestamp,
  PRIMARY KEY ("taskid"),
  CONSTRAINT "task_sha256" UNIQUE ("sha256")
);
CREATE INDEX "task_idx_sha256" on "task" ("sha256");
CREATE INDEX "task_idx_projectid" on "task" ("projectid");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "commit_push" ADD FOREIGN KEY ("projectid")
  REFERENCES "project" ("projectid") DEFERRABLE;

;
ALTER TABLE "task" ADD FOREIGN KEY ("sha256")
  REFERENCES "commit_push" ("sha256") DEFERRABLE;

;
ALTER TABLE "task" ADD FOREIGN KEY ("projectid")
  REFERENCES "project" ("projectid") DEFERRABLE;

