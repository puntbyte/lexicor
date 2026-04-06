create table adjpositions (
  positionid CHARACTER(1) not null,
  position VARCHAR(24) not null,
  check (`positionid` in ('a', 'p', 'ip'))
);

create unique index pk_adjpositions
  on adjpositions(positionid);

create table casedwords (
  casedwordid int not null,
  wordid int not null,
  casedword VARCHAR(80) not null
);

create index k_casedwords_wordid
  on casedwords(wordid);

create index k_casedwords_wordid_casedwordid
  on casedwords(wordid, casedwordid);

create unique index pk_casedwords
  on casedwords(casedwordid);

create unique index uk_casedwords_casedword
  on casedwords(casedword);

create table domains (
  domainid int not null,
  domain VARCHAR(32) not null,
  domainname VARCHAR(32) not null,
  posid CHARACTER(1) not null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create unique index pk_domains
  on domains(domainid);

create unique index uk_domains_domain_posid
  on domains(domain, posid);

create table ilis (
  ili VARCHAR(7) not null,
  synsetid int not null
);

create unique index pk_ilis
  on ilis(synsetid);

create table lexes (
  luid int not null,
  posid CHARACTER(1) not null,
  wordid int not null,
  casedwordid int default null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create index k_lexes_casedwordid
  on lexes(casedwordid);

create index k_lexes_wordid
  on lexes(wordid);

create unique index pk_lexes
  on lexes(luid);

create table lexes_morphs (
  luid int not null,
  wordid int not null,
  posid CHARACTER(1) not null,
  morphid int not null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create index k_lexes_morphs_luid
  on lexes_morphs(luid);

create index k_lexes_morphs_morphid
  on lexes_morphs(morphid);

create index k_lexes_morphs_wordid
  on lexes_morphs(wordid);

create unique index pk_lexes_morphs
  on lexes_morphs(morphid, luid, posid);

create table lexes_pronunciations (
  luid int not null,
  wordid int not null,
  posid CHARACTER(1) not null,
  pronunciationid int not null,
  variety VARCHAR(2) default null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create index k_lexes_pronunciations_luid
  on lexes_pronunciations(luid);

create index k_lexes_pronunciations_pronunciationid
  on lexes_pronunciations(pronunciationid);

create index k_lexes_pronunciations_wordid
  on lexes_pronunciations(wordid);

create table lexrelations (
  synset1id int not null,
  lu1id int not null,
  word1id int not null,
  synset2id int not null,
  lu2id int not null,
  word2id int not null,
  relationid int not null
);

create index k_lexrelations_lu1id
  on lexrelations(lu1id);

create index k_lexrelations_lu1id_synset1id
  on lexrelations(lu1id, synset1id);

create index k_lexrelations_lu2id
  on lexrelations(lu2id);

create index k_lexrelations_lu2id_synset2id
  on lexrelations(lu2id, synset2id);

create index k_lexrelations_relationid
  on lexrelations(relationid);

create index k_lexrelations_synset1id
  on lexrelations(synset1id);

create index k_lexrelations_synset2id
  on lexrelations(synset2id);

create index k_lexrelations_word1id
  on lexrelations(word1id);

create index k_lexrelations_word1id_synset1id
  on lexrelations(word1id, synset1id);

create index k_lexrelations_word2id
  on lexrelations(word2id);

create index k_lexrelations_word2id_synset2id
  on lexrelations(word2id, synset2id);

create unique index pk_lexrelations
  on lexrelations(synset1id, lu1id, lu2id, synset2id, relationid);

create table morphs (
  morphid int not null,
  morph VARCHAR(70) not null
);

create unique index pk_morphs
  on morphs(morphid);

create unique index uk_morphs_morph
  on morphs(morph);

create table poses (
  posid CHARACTER(1) not null,
  pos VARCHAR(20) not null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create unique index pk_poses
  on poses(posid);

create table pronunciations (
  pronunciationid int not null,
  pronunciation VARCHAR(50) not null
);

create unique index pk_pronunciations
  on pronunciations(pronunciationid);

create unique index uk_pronunciations_pronunciation
  on pronunciations(pronunciation);

create table relations (
  relationid int not null,
  relation VARCHAR(50) not null,
  recurses TINYINT(1) not null
);

create unique index pk_relations
  on relations(relationid);

create unique index uk_relations_relation
  on relations(relation);

create table samples (
  sampleid int not null,
  sample MEDIUMTEXT not null,
  source MEDIUMTEXT,
  synsetid int not null,
  luid int default null,
  wordid int default null
);

create index k_samples_luid
  on samples(luid);

create index k_samples_synsetid
  on samples(synsetid);

create index k_samples_wordid
  on samples(wordid);

create unique index pk_samples
  on samples(synsetid, sampleid);

create table semrelations (
  synset1id int not null,
  synset2id int not null,
  relationid int not null
);

create index k_semrelations_relationid
  on semrelations(relationid);

create index k_semrelations_synset1id
  on semrelations(synset1id);

create index k_semrelations_synset2id
  on semrelations(synset2id);

create unique index pk_semrelations
  on semrelations(synset1id, synset2id, relationid);

create table senses (
  senseid int not null,
  sensekey VARCHAR(100) default null,
  synsetid int not null,
  luid int not null,
  wordid int not null,
  casedwordid int default null,
  lexid int not null,
  sensenum int default null,
  tagcount int default null
);

create index k_senses_casedwordid
  on senses(casedwordid);

create index k_senses_luid
  on senses(luid);

create index k_senses_synsetid
  on senses(synsetid);

create index k_senses_wordid
  on senses(wordid);

create unique index pk_senses
  on senses(senseid);

create unique index uk_senses_luid_sensekey
  on senses(luid, sensekey);

create unique index uk_senses_luid_synsetid
  on senses(luid, synsetid);

create unique index uk_senses_sensekey
  on senses(sensekey);

create table senses_adjpositions (
  synsetid int not null,
  luid int not null,
  wordid int not null,
  positionid CHARACTER(1) not null,
  check (`positionid` in ('a', 'p', 'ip'))
);

create index k_senses_adjpositions_luid
  on senses_adjpositions(luid);

create index k_senses_adjpositions_synsetid
  on senses_adjpositions(synsetid);

create index k_senses_adjpositions_wordid
  on senses_adjpositions(wordid);

create table senses_vframes (
  synsetid int not null,
  luid int not null,
  wordid int not null,
  frameid int not null
);

create index k_senses_vframes_frameid
  on senses_vframes(frameid);

create index k_senses_vframes_luid
  on senses_vframes(luid);

create index k_senses_vframes_synsetid
  on senses_vframes(synsetid);

create index k_senses_vframes_wordid
  on senses_vframes(wordid);

create table senses_vtemplates (
  synsetid int not null,
  luid int not null,
  wordid int not null,
  templateid int not null
);

create index k_senses_vtemplates_luid
  on senses_vtemplates(luid);

create index k_senses_vtemplates_synsetid
  on senses_vtemplates(synsetid);

create index k_senses_vtemplates_templateid
  on senses_vtemplates(templateid);

create index k_senses_vtemplates_wordid
  on senses_vtemplates(wordid);

create table sqlite_master (
  type text,
  name text,
  tbl_name text,
  rootpage int,
  sql text
);

create table sqlite_stat1 (
  tbl,
  idx,
  stat
);

create table sqlite_stat4 (
  tbl,
  idx,
  neq,
  nlt,
  ndlt,
  sample
);

create table synsets (
  synsetid int not null,
  posid CHARACTER(1) not null,
  domainid int not null,
  definition MEDIUMTEXT not null,
  check (`posid` in ('n', 'v', 'a', 'r', 's'))
);

create unique index pk_synsets
  on synsets(synsetid);

create table usages (
  usageid int not null,
  usagenote MEDIUMTEXT not null,
  synsetid int not null,
  luid int default null,
  wordid int default null
);

create index k_usages_luid
  on usages(luid);

create index k_usages_synsetid
  on usages(synsetid);

create index k_usages_wordid
  on usages(wordid);

create unique index pk_usages
  on usages(synsetid, usageid);

create table vframes (
  frameid int not null,
  frame VARCHAR(50) not null
);

create unique index pk_vframes
  on vframes(frameid);

create unique index uk_vframes_frame
  on vframes(frame);

create table vtemplates (
  templateid int not null,
  template MEDIUMTEXT not null
);

create unique index pk_vtemplates
  on vtemplates(templateid);

create unique index uk_vtemplates_template
  on vtemplates(template);

create table wikidatas (
  wikidata VARCHAR(12) not null,
  synsetid int not null
);

create unique index pk_wikidatas
  on wikidatas(synsetid, wikidata);

create table words (
  wordid int not null,
  word VARCHAR(80) not null
);

create unique index pk_words
  on words(wordid);

create unique index uk_words_word
  on words(word);