-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Apr 17 16:25:31 2013
-- 

;
BEGIN TRANSACTION;
--
-- Table: project
--
CREATE TABLE project (
  projectid INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url text NOT NULL,
  description text NOT NULL,
  owner text NOT NULL
);
CREATE UNIQUE INDEX project_name ON project (name);
--
-- Table: commit_push
--
CREATE TABLE commit_push (
  sha256 text NOT NULL,
  content text NOT NULL,
  projectid int NOT NULL,
  timestamp datetime NOT NULL,
  PRIMARY KEY (sha256),
  FOREIGN KEY (projectid) REFERENCES project(projectid)
);
CREATE INDEX commit_push_idx_projectid ON commit_push (projectid);
--
-- Table: task
--
CREATE TABLE task (
  taskid INTEGER PRIMARY KEY NOT NULL,
  sha256 text NOT NULL,
  projectid int NOT NULL,
  running bool NOT NULL DEFAULT '0',
  started_when datetime,
  FOREIGN KEY (sha256) REFERENCES commit_push(sha256),
  FOREIGN KEY (projectid) REFERENCES project(projectid)
);
CREATE INDEX task_idx_sha256 ON task (sha256);
CREATE INDEX task_idx_projectid ON task (projectid);
CREATE UNIQUE INDEX task_sha256 ON task (sha256);
COMMIT;
