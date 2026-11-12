-- Marvel database: schema + data (SQLite)
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS Hero;
DROP TABLE IF EXISTS Death;
DROP TABLE IF EXISTS Resurrection;
DROP TABLE IF EXISTS Role;
DROP TABLE IF EXISTS MovieStone;
DROP TABLE IF EXISTS Movie;
DROP TABLE IF EXISTS Stone;
DROP TABLE IF EXISTS Phase;
DROP TABLE IF EXISTS Actor;
DROP TABLE IF EXISTS Character;

CREATE TABLE Phase (
  PhaseID   INTEGER PRIMARY KEY,
  PhaseName TEXT NOT NULL
);

CREATE TABLE Stone (
  StoneID   INTEGER PRIMARY KEY,
  StoneName TEXT NOT NULL UNIQUE
);

CREATE TABLE Character (
  CharacterID   INTEGER PRIMARY KEY,
  CharacterName TEXT NOT NULL UNIQUE
);

CREATE TABLE Actor (
  ActorID   INTEGER PRIMARY KEY,
  ActorName TEXT NOT NULL UNIQUE
);

CREATE TABLE Movie (
  MovieID      INTEGER PRIMARY KEY,
  Title        TEXT    NOT NULL UNIQUE,
  UniverseYear INTEGER,
  ReleaseYear  INTEGER NOT NULL,
  IMDBRating   REAL,
  PhaseID      INTEGER NOT NULL REFERENCES Phase(PhaseID)
);

CREATE TABLE MovieStone (
  MovieID INTEGER NOT NULL REFERENCES Movie(MovieID),
  StoneID INTEGER NOT NULL REFERENCES Stone(StoneID),
  PRIMARY KEY (MovieID, StoneID)
);

-- One actor per character per movie (the Hulk is Edward Norton in movie 2, Mark Ruffalo elsewhere)
CREATE TABLE Role (
  CharacterID INTEGER NOT NULL REFERENCES Character(CharacterID),
  MovieID     INTEGER NOT NULL REFERENCES Movie(MovieID),
  ActorID     INTEGER NOT NULL REFERENCES Actor(ActorID),
  PRIMARY KEY (CharacterID, MovieID)
);

CREATE TABLE Death (
  CharacterID INTEGER NOT NULL REFERENCES Character(CharacterID),
  MovieID     INTEGER NOT NULL REFERENCES Movie(MovieID),
  PRIMARY KEY (CharacterID, MovieID)
);

CREATE TABLE Resurrection (
  CharacterID INTEGER NOT NULL REFERENCES Character(CharacterID),
  MovieID     INTEGER NOT NULL REFERENCES Movie(MovieID),
  PRIMARY KEY (CharacterID, MovieID)
);

CREATE TABLE Hero (
  CharacterID INTEGER PRIMARY KEY REFERENCES Character(CharacterID)
);

INSERT INTO Phase (PhaseID, PhaseName) VALUES
  (1, 'Phase 1'),
  (2, 'Phase 2'),
  (3, 'Phase 3');

INSERT INTO Stone (StoneID, StoneName) VALUES
  (1, 'Space'),
  (2, 'Mind'),
  (3, 'Reality'),
  (4, 'Power'),
  (5, 'Time'),
  (6, 'Soul');

INSERT INTO Character (CharacterID, CharacterName) VALUES
  (1, 'Iron Man'),
  (2, 'Captain America'),
  (3, 'Black Widow'),
  (4, 'Thor'),
  (5, 'The Hulk'),
  (6, 'Hawkeye'),
  (7, 'Nick Fury'),
  (8, 'War Machine'),
  (9, 'JARVIS'),
  (10, 'Vision'),
  (11, 'Spider-Man'),
  (12, 'Thanos'),
  (13, 'Starlord'),
  (14, 'Gamora'),
  (15, 'Drax'),
  (16, 'Groot'),
  (17, 'Rocket Racoon'),
  (18, 'Ultron'),
  (19, 'Ant-Man'),
  (20, 'Doctor Strange'),
  (21, 'Black Panther');

INSERT INTO Actor (ActorID, ActorName) VALUES
  (1, 'Robert Downey Jr.'),
  (2, 'Chris Evans'),
  (3, 'Scarlett Johansson'),
  (4, 'Chris Hemsworth'),
  (5, 'Mark Ruffalo'),
  (6, 'Edward Norton'),
  (7, 'Jeremy Renner'),
  (8, 'Samuel L. Jackson'),
  (9, 'Terrence Howard'),
  (10, 'Don Cheadle'),
  (11, 'Paul Bettany'),
  (12, 'Tom Holland'),
  (13, 'Josh Brolin'),
  (14, 'Chris Pratt'),
  (15, 'Zoe Saldana'),
  (16, 'Dave Bautista'),
  (17, 'Vin Diesel'),
  (18, 'Bradley Cooper'),
  (19, 'James Spader'),
  (20, 'Paul Rudd'),
  (21, 'Benedict Cumberbatch'),
  (22, 'Chadwick Boseman');

INSERT INTO Movie (MovieID, Title, UniverseYear, ReleaseYear, IMDBRating, PhaseID) VALUES
  (1, 'Iron Man', 2010, 2008, 7.9, 1),
  (2, 'The Incredible Hulk', 2011, 2008, 6.8, 1),
  (3, 'Iron Man 2', 2011, 2010, 7, 1),
  (4, 'The Avengers', 2012, 2012, 8.1, 1),
  (5, 'Iron Man 3', 2012, 2013, 7.2, 2),
  (6, 'Avengers: Age of Ultron', 2015, 2015, 7.4, 2),
  (7, 'Captain America: Civil War', 2016, 2016, 7.8, 3),
  (8, 'Spider-Man: Homecoming', 2016, 2017, 7.5, 3),
  (9, 'Avengers: Infinity War', 2018, 2018, 8.5, 3),
  (10, 'Avengers: Endgame', 2023, 2019, 8.4, 3),
  (11, 'Captain America: The First Avenger', 1943, 2011, 6.9, 1),
  (12, 'Thor: Dark World', 2013, 2013, 7, 2),
  (13, 'Captain America: The Winter Soldier', 2014, 2014, 7.8, 2),
  (14, 'Captain Marvel', 1995, 2019, 7, 3),
  (15, 'Thor', 2011, 2011, 7, 1),
  (16, 'Thor: Ragnarok', 2018, 2017, 7.9, 3),
  (17, 'Guardians of Galaxy', 2014, 2014, 8.1, 2),
  (18, 'Guardians of Galaxy Vol. 2', 2014, 2017, 7.7, 3),
  (19, 'Ant-Man', 2015, 2015, 7.3, 2),
  (20, 'Ant-Man and the Wasp', 2018, 2018, 7.2, 3),
  (21, 'Doctor Strange', 2017, 2016, 7.5, 3),
  (22, 'Black Panther', 2016, 2018, 7.4, 3);

INSERT INTO MovieStone (MovieID, StoneID) VALUES
  (11, 1),
  (4, 1),
  (4, 2),
  (12, 3),
  (17, 4),
  (6, 2),
  (21, 5),
  (9, 4),
  (9, 1),
  (9, 3),
  (9, 6),
  (9, 5),
  (9, 2),
  (14, 1),
  (10, 4),
  (10, 1),
  (10, 3),
  (10, 6),
  (10, 5),
  (10, 2);

INSERT INTO Role (CharacterID, MovieID, ActorID) VALUES
  (1, 1, 1),
  (1, 2, 1),
  (1, 3, 1),
  (1, 4, 1),
  (1, 5, 1),
  (1, 6, 1),
  (1, 7, 1),
  (1, 8, 1),
  (1, 9, 1),
  (1, 10, 1),
  (2, 11, 2),
  (2, 4, 2),
  (2, 12, 2),
  (2, 13, 2),
  (2, 6, 2),
  (2, 7, 2),
  (2, 8, 2),
  (2, 9, 2),
  (2, 14, 2),
  (2, 10, 2),
  (3, 3, 3),
  (3, 4, 3),
  (3, 13, 3),
  (3, 6, 3),
  (3, 7, 3),
  (3, 9, 3),
  (3, 14, 3),
  (3, 10, 3),
  (4, 15, 4),
  (4, 4, 4),
  (4, 12, 4),
  (4, 6, 4),
  (4, 16, 4),
  (4, 9, 4),
  (4, 10, 4),
  (5, 4, 5),
  (5, 5, 5),
  (5, 6, 5),
  (5, 16, 5),
  (5, 9, 5),
  (5, 14, 5),
  (5, 10, 5),
  (5, 2, 6),
  (6, 15, 7),
  (6, 4, 7),
  (6, 6, 7),
  (6, 7, 7),
  (6, 10, 7),
  (7, 1, 8),
  (7, 3, 8),
  (7, 15, 8),
  (7, 11, 8),
  (7, 4, 8),
  (7, 13, 8),
  (7, 6, 8),
  (7, 9, 8),
  (7, 14, 8),
  (7, 10, 8),
  (8, 1, 9),
  (8, 3, 10),
  (8, 5, 10),
  (8, 6, 10),
  (8, 7, 10),
  (8, 9, 10),
  (8, 14, 10),
  (8, 10, 10),
  (9, 1, 11),
  (9, 3, 11),
  (9, 4, 11),
  (9, 5, 11),
  (9, 6, 11),
  (10, 6, 11),
  (10, 7, 11),
  (10, 9, 11),
  (11, 3, 12),
  (11, 7, 12),
  (11, 8, 12),
  (11, 9, 12),
  (11, 10, 12),
  (12, 4, 13),
  (12, 17, 13),
  (12, 6, 13),
  (12, 9, 13),
  (12, 10, 13),
  (13, 17, 14),
  (13, 18, 14),
  (13, 9, 14),
  (13, 10, 14),
  (14, 17, 15),
  (14, 18, 15),
  (14, 9, 15),
  (14, 10, 15),
  (15, 17, 16),
  (15, 18, 16),
  (15, 9, 16),
  (15, 10, 16),
  (16, 17, 17),
  (16, 18, 17),
  (16, 9, 17),
  (16, 10, 17),
  (17, 17, 18),
  (17, 18, 18),
  (17, 9, 18),
  (17, 10, 18),
  (18, 6, 19),
  (19, 19, 20),
  (19, 7, 20),
  (19, 20, 20),
  (19, 10, 20),
  (20, 21, 21),
  (20, 16, 21),
  (20, 9, 21),
  (20, 10, 21),
  (21, 7, 22),
  (21, 22, 22),
  (21, 9, 22),
  (21, 10, 22);

INSERT INTO Death (CharacterID, MovieID) VALUES
  (1, 10),
  (2, 10),
  (4, 15),
  (7, 9),
  (9, 6),
  (10, 9),
  (11, 9),
  (12, 9),
  (12, 10),
  (13, 9),
  (14, 9),
  (15, 9),
  (16, 17),
  (16, 9),
  (18, 6),
  (20, 9),
  (21, 9);

INSERT INTO Resurrection (CharacterID, MovieID) VALUES
  (4, 15),
  (7, 10),
  (10, 10),
  (11, 10),
  (12, 10),
  (13, 10),
  (14, 10),
  (15, 10),
  (16, 17),
  (20, 10),
  (21, 10);

INSERT INTO Hero (CharacterID) VALUES
  (1),
  (2),
  (3),
  (4),
  (5),
  (6),
  (7),
  (8),
  (9),
  (10),
  (11),
  (13),
  (14),
  (15),
  (16),
  (17),
  (19),
  (20),
  (21);

COMMIT;
