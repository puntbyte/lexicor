-- migration_full.sql
-- Full migration for OEWN -> Lexicor (with definitions + usage examples).
-- Produces dictionary_full.sqlite (~40 MB vs ~28 MB for the light version).
--
-- Source schema reference: tool/sql/oewn.sql
-- Key source tables used beyond the light build:
--   synsets.definition  MEDIUMTEXT  — synset gloss/definition
--   samples             table       — usage example sentences per synset

-- 1. FAST SETUP
PRAGMA journal_mode = MEMORY;
PRAGMA synchronous = OFF;
PRAGMA foreign_keys = OFF;

-- 2. CREATE SCHEMA
CREATE TABLE IF NOT EXISTS part_of_speech (
  id CHAR(1) PRIMARY KEY NOT NULL,
  name VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS domain_category (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(32) NOT NULL,
  part_of_speech_id CHAR(1) NOT NULL REFERENCES part_of_speech(id)
);

CREATE TABLE IF NOT EXISTS relationship_type (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(50) NOT NULL,
  is_recursive BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS word (
  id INTEGER PRIMARY KEY NOT NULL,
  text VARCHAR(80) NOT NULL
);

-- definition column (MEDIUMTEXT stored as TEXT in SQLite)
CREATE TABLE IF NOT EXISTS synset (
  id INTEGER PRIMARY KEY NOT NULL,
  part_of_speech_id CHAR(1) NOT NULL REFERENCES part_of_speech(id),
  domain_category_id INTEGER NOT NULL REFERENCES domain_category(id),
  definition TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sense (
  id INTEGER PRIMARY KEY NOT NULL,
  word_id INTEGER NOT NULL REFERENCES word(id),
  synset_id INTEGER NOT NULL REFERENCES synset(id),
  sense_sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS morphological_form (
  id INTEGER PRIMARY KEY NOT NULL,
  text VARCHAR(70) NOT NULL
);

CREATE TABLE IF NOT EXISTS word_morphology (
  word_id INTEGER NOT NULL REFERENCES word(id),
  part_of_speech_id CHAR(1) NOT NULL REFERENCES part_of_speech(id),
  morphological_form_id INTEGER NOT NULL REFERENCES morphological_form(id)
);

-- Usage example sentences (from source.samples)
-- One row per example sentence. Multiple rows per synset are normal.
CREATE TABLE IF NOT EXISTS sample (
  id INTEGER PRIMARY KEY NOT NULL,
  synset_id INTEGER NOT NULL REFERENCES synset(id),
  text TEXT NOT NULL
);

-- WITHOUT ROWID optimization for junction tables
CREATE TABLE IF NOT EXISTS semantic_relationship (
  source_synset_id INTEGER NOT NULL,
  target_synset_id INTEGER NOT NULL,
  relationship_type_id INTEGER NOT NULL,
  PRIMARY KEY (source_synset_id, target_synset_id, relationship_type_id)
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS lexical_relationship (
  source_sense_id INTEGER NOT NULL,
  target_sense_id INTEGER NOT NULL,
  relationship_type_id INTEGER NOT NULL,
  PRIMARY KEY (source_sense_id, target_sense_id, relationship_type_id)
) WITHOUT ROWID;

-- 3. BULK LOAD
BEGIN;
INSERT OR IGNORE INTO part_of_speech
  SELECT posid, pos FROM source.poses;

INSERT OR IGNORE INTO domain_category
  SELECT domainid, domainname, posid FROM source.domains;

INSERT OR IGNORE INTO relationship_type
  SELECT relationid, relation, recurses FROM source.relations;

INSERT OR IGNORE INTO word
  SELECT wordid, word FROM source.words;

INSERT OR IGNORE INTO morphological_form
  SELECT morphid, morph FROM source.morphs;

-- Include definition from source.synsets
INSERT OR IGNORE INTO synset
  SELECT synsetid, posid, domainid, definition FROM source.synsets;

INSERT OR IGNORE INTO sense
  SELECT senseid, wordid, synsetid, sensenum FROM source.senses;

INSERT OR IGNORE INTO word_morphology
  SELECT DISTINCT wordid, posid, morphid FROM source.lexes_morphs;

-- Usage examples (text only — source column and luid not needed in our schema)
INSERT OR IGNORE INTO sample
  SELECT sampleid, synsetid, sample FROM source.samples;

INSERT OR IGNORE INTO semantic_relationship
  SELECT DISTINCT synset1id, synset2id, relationid FROM source.semrelations;

INSERT OR IGNORE INTO lexical_relationship
  SELECT DISTINCT s1.senseid, s2.senseid, lr.relationid FROM source.lexrelations lr
  JOIN source.senses s1 ON (lr.word1id = s1.wordid AND lr.synset1id = s1.synsetid)
  JOIN source.senses s2 ON (lr.word2id = s2.wordid AND lr.synset2id = s2.synsetid);

COMMIT;

-- 4. CREATE INDEXES
CREATE INDEX idx_word_text           ON word(text);
CREATE INDEX idx_sense_word_id       ON sense(word_id);
CREATE INDEX idx_sense_synset_id     ON sense(synset_id);
CREATE INDEX idx_word_morph_word_pos ON word_morphology(word_id, part_of_speech_id);
CREATE INDEX idx_synset_domain       ON synset(domain_category_id);
CREATE INDEX idx_sense_word_order    ON sense(word_id, sense_sort_order);
CREATE INDEX idx_sample_synset_id    ON sample(synset_id);

-- 5. CLEANUP & OPTIMIZE
DROP INDEX IF EXISTS idx_lexrel_source;
DROP INDEX IF EXISTS idx_semrel_source;

ANALYZE;
VACUUM;

-- 6. PREPARE FOR SHIPPING
PRAGMA journal_mode = DELETE;