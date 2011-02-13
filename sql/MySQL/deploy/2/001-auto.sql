-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon Jan 24 21:26:41 2011
-- 
;
SET foreign_key_checks=0;
--
-- Table: `project`
--
CREATE TABLE `project` (
  `projectid` integer NOT NULL auto_increment,
  `name` text NOT NULL,
  `url` text NOT NULL,
  `description` text NOT NULL,
  `owner` text NOT NULL,
  PRIMARY KEY (`projectid`),
  UNIQUE `project_name` (`name`)
) ENGINE=InnoDB;
--
-- Table: `commit_push`
--
CREATE TABLE `commit_push` (
  `sha256` text NOT NULL,
  `content` text NOT NULL,
  `projectid` integer NOT NULL,
  `timestamp` datetime NOT NULL,
  INDEX `commit_push_idx_projectid` (`projectid`),
  PRIMARY KEY (`sha256`),
  CONSTRAINT `commit_push_fk_projectid` FOREIGN KEY (`projectid`) REFERENCES `project` (`projectid`)
) ENGINE=InnoDB;
--
-- Table: `task`
--
CREATE TABLE `task` (
  `taskid` integer NOT NULL auto_increment,
  `sha256` text NOT NULL,
  `projectid` integer NOT NULL,
  `running` bool NOT NULL DEFAULT '0',
  INDEX `task_idx_sha256` (`sha256`),
  INDEX `task_idx_projectid` (`projectid`),
  PRIMARY KEY (`taskid`),
  UNIQUE `task_projectid` (`projectid`),
  UNIQUE `task_sha256` (`sha256`),
  CONSTRAINT `task_fk_sha256` FOREIGN KEY (`sha256`) REFERENCES `commit_push` (`sha256`),
  CONSTRAINT `task_fk_projectid` FOREIGN KEY (`projectid`) REFERENCES `project` (`projectid`)
) ENGINE=InnoDB;
SET foreign_key_checks=1