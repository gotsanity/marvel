-- marvel-additional-data.sql
-- Run AFTER marvel.sql. Compatible with SQLite 3.26.0 and later (no ALTER TABLE ... DROP COLUMN).
-- Extends the schema (all tables in 3NF) and adds every MCU theatrical film released through 2026-11-05.
-- Sources: Wikipedia film, actor and character articles; List of MCU film actors; Box Office Mojo / The Numbers;
-- Rotten Tomatoes, Metacritic and CinemaScore as cited on Wikipedia. Researched November 2026.
-- Box office for Spider-Man: Brand New Day and all IMDb / Rotten Tomatoes scores change over time.
-- NULL means the value is not published in a reliable source (never estimated).

-- Foreign-key enforcement is off while tables are rebuilt (SQLite's standard rebuild procedure);
-- PRAGMA foreign_key_check at the end lists any violation (it returns no rows when the data is clean).
PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

------------------------------------------------------------------
-- 1. Schema changes
------------------------------------------------------------------
-- Actors and crew are both people (Jon Favreau acts and directs), so Actor becomes Person.
ALTER TABLE Actor RENAME TO Person;
ALTER TABLE Person RENAME COLUMN ActorID TO PersonID;
ALTER TABLE Person RENAME COLUMN ActorName TO PersonName;
-- BirthPlace is one atomic value; separate City/Country columns would create a City -> Country dependency.
ALTER TABLE Person ADD COLUMN BirthName  TEXT;
ALTER TABLE Person ADD COLUMN BirthDate  TEXT;   -- ISO 8601
ALTER TABLE Person ADD COLUMN DeathDate  TEXT;   -- NULL if living
ALTER TABLE Person ADD COLUMN BirthPlace TEXT;

-- Role key widened to (CharacterID, PersonID, MovieID): multiverse films have several actors per character.
CREATE TABLE Role_new (
  CharacterID INTEGER NOT NULL REFERENCES Character(CharacterID),
  PersonID    INTEGER NOT NULL REFERENCES Person(PersonID),
  MovieID     INTEGER NOT NULL REFERENCES Movie(MovieID),
  PRIMARY KEY (CharacterID, PersonID, MovieID)
);
INSERT INTO Role_new (CharacterID, PersonID, MovieID) SELECT CharacterID, ActorID, MovieID FROM Role;
DROP TABLE Role;
ALTER TABLE Role_new RENAME TO Role;

CREATE TABLE CrewRole (
  CrewRoleID   INTEGER PRIMARY KEY,
  CrewRoleName TEXT NOT NULL UNIQUE
);
CREATE TABLE MovieCrew (
  MovieID    INTEGER NOT NULL REFERENCES Movie(MovieID),
  PersonID   INTEGER NOT NULL REFERENCES Person(PersonID),
  CrewRoleID INTEGER NOT NULL REFERENCES CrewRole(CrewRoleID),
  PRIMARY KEY (MovieID, PersonID, CrewRoleID)
);

ALTER TABLE Phase ADD COLUMN Saga TEXT;

CREATE TABLE Species (
  SpeciesID   INTEGER PRIMARY KEY,
  SpeciesName TEXT NOT NULL UNIQUE
);
ALTER TABLE Character ADD COLUMN RealName    TEXT;
ALTER TABLE Character ADD COLUMN SpeciesID   INTEGER REFERENCES Species(SpeciesID);   -- NULL = never stated
ALTER TABLE Character ADD COLUMN Description TEXT;

CREATE TABLE Distributor (
  DistributorID   INTEGER PRIMARY KEY,
  DistributorName TEXT NOT NULL UNIQUE
);
-- ReleaseDate replaces ReleaseYear (keeping both would be a transitive dependency); year = strftime('%Y', ReleaseDate).
ALTER TABLE Movie ADD COLUMN ReleaseDate               TEXT;
ALTER TABLE Movie ADD COLUMN RuntimeMinutes            INTEGER;
ALTER TABLE Movie ADD COLUMN MPAARating                TEXT;
ALTER TABLE Movie ADD COLUMN IMDbID                    TEXT;
ALTER TABLE Movie ADD COLUMN DistributorID             INTEGER REFERENCES Distributor(DistributorID);
ALTER TABLE Movie ADD COLUMN BudgetMinUSD              INTEGER;   -- budgets are often reported as a range
ALTER TABLE Movie ADD COLUMN BudgetMaxUSD              INTEGER;
ALTER TABLE Movie ADD COLUMN OpeningWeekendDomesticUSD INTEGER;
ALTER TABLE Movie ADD COLUMN DomesticGrossUSD          INTEGER;
ALTER TABLE Movie ADD COLUMN WorldwideGrossUSD         INTEGER;
ALTER TABLE Movie ADD COLUMN RTCriticsPct              INTEGER;
ALTER TABLE Movie ADD COLUMN RTAudiencePct             INTEGER;
ALTER TABLE Movie ADD COLUMN MetacriticScore           INTEGER;
ALTER TABLE Movie ADD COLUMN CinemaScore               TEXT;

CREATE TABLE Team (
  TeamID      INTEGER PRIMARY KEY,
  TeamName    TEXT NOT NULL UNIQUE,
  Description TEXT
);
CREATE TABLE CharacterTeam (   -- membership shown or established in the films (not TV-only)
  CharacterID INTEGER NOT NULL REFERENCES Character(CharacterID),
  TeamID      INTEGER NOT NULL REFERENCES Team(TeamID),
  PRIMARY KEY (CharacterID, TeamID)
);

CREATE TABLE DeathManner (
  DeathMannerID INTEGER PRIMARY KEY,
  MannerName    TEXT NOT NULL UNIQUE
);
ALTER TABLE Death ADD COLUMN KilledByCharacterID INTEGER REFERENCES Character(CharacterID);  -- NULL = no listed killer
ALTER TABLE Death ADD COLUMN DeathMannerID       INTEGER REFERENCES DeathManner(DeathMannerID);
ALTER TABLE Death ADD COLUMN Cause               TEXT;

------------------------------------------------------------------
-- 2. Corrections to the original data
------------------------------------------------------------------
UPDATE Movie SET Title = 'Thor: The Dark World' WHERE MovieID = 12;
UPDATE Movie SET Title = 'Guardians of the Galaxy' WHERE MovieID = 17;
UPDATE Movie SET Title = 'Guardians of the Galaxy Vol. 2' WHERE MovieID = 18;
UPDATE Character SET CharacterName = 'Star-Lord' WHERE CharacterID = 13;
UPDATE Character SET CharacterName = 'Rocket Raccoon' WHERE CharacterID = 17;
DELETE FROM Role WHERE CharacterID = 11 AND PersonID = 12 AND MovieID = 3;   -- Iron Man 2's masked boy was Max Favreau, not Tom Holland
DELETE FROM Role WHERE CharacterID = 12 AND PersonID = 13 AND MovieID = 4;   -- Thanos in The Avengers was Damion Poitier, not Josh Brolin
INSERT INTO MovieStone (MovieID, StoneID) VALUES
  (15, 1),   -- Thor: Tesseract in the post-credits scene
  (13, 2),   -- The Winter Soldier: Loki's scepter in the post-credits scene
  (7, 2),    -- Civil War: Mind Stone in Vision's forehead
  (16, 1);   -- Thor: Ragnarok: Loki takes the Tesseract from Odin's vault
-- Death and Resurrection are fully reloaded in section 9 (fixes: Steve Rogers and Thanos-in-Infinity-War deaths removed;
-- Thanos/Vision/Gamora Endgame resurrections removed; Groot's Endgame resurrection added; Snap victims logged in Infinity War).

------------------------------------------------------------------
-- 3. Lookup tables
------------------------------------------------------------------
UPDATE Phase SET Saga = 'The Infinity Saga' WHERE PhaseID IN (1, 2, 3);
INSERT INTO Phase (PhaseID, PhaseName, Saga) VALUES
  (4, 'Phase 4', 'The Multiverse Saga'),
  (5, 'Phase 5', 'The Multiverse Saga'),
  (6, 'Phase 6', 'The Multiverse Saga');
INSERT INTO Species (SpeciesID, SpeciesName) VALUES
  (1, 'Android'),
  (2, 'Artificial Intelligence'),
  (3, 'Asgardian'),
  (4, 'Celestial'),
  (5, 'Cosmic Being'),
  (6, 'Dark Elf'),
  (7, 'Enhanced Human'),
  (8, 'Eternal'),
  (9, 'Flora Colossus'),
  (10, 'Frost Giant'),
  (11, 'Genetically Engineered Raccoon'),
  (12, 'Human'),
  (13, 'Human/Celestial Hybrid'),
  (14, 'Human/Kree Hybrid'),
  (15, 'Insectoid/Celestial Hybrid'),
  (16, 'Kree'),
  (17, 'Kylosian'),
  (18, 'Luphomoid'),
  (19, 'Mutant'),
  (20, 'Titan'),
  (21, 'Zehoberei');
INSERT INTO CrewRole (CrewRoleID, CrewRoleName) VALUES
  (1, 'Director'),
  (2, 'Screenwriter'),
  (3, 'Composer'),
  (4, 'Producer');
INSERT INTO Distributor (DistributorID, DistributorName) VALUES
  (1, 'Paramount Pictures'),
  (2, 'Sony Pictures Releasing'),
  (3, 'Universal Pictures'),
  (4, 'Walt Disney Studios Motion Pictures');
INSERT INTO DeathManner (DeathMannerID, MannerName) VALUES
  (1, 'Accident'),
  (2, 'Combat'),
  (3, 'Curse'),
  (4, 'Execution'),
  (5, 'Illness'),
  (6, 'Murder'),
  (7, 'Sacrifice'),
  (8, 'Snap'),
  (9, 'Suicide');
INSERT INTO Team (TeamID, TeamName, Description) VALUES
  (1, 'Avengers', 'Earth''s team of superheroes, assembled by Nick Fury and later based at the Avengers Compound.'),
  (2, 'Guardians of the Galaxy', 'A band of spacefaring outlaws-turned-heroes led by Star-Lord, later by Rocket.'),
  (3, 'Fantastic Four', 'Retro-futuristic Earth-828 superhero family formed after a cosmic-ray accident.'),
  (4, 'Thunderbolts', 'Team of antiheroes assembled after surviving Valentina de Fontaine''s O.X.E. vault trap.'),
  (5, 'S.H.I.E.L.D.', 'International espionage and law-enforcement agency directed by Nick Fury.'),
  (6, 'Hydra', 'Nazi-born terrorist organization that secretly infiltrated S.H.I.E.L.D.'),
  (7, 'Dora Milaje', 'All-female special-forces bodyguard of Wakanda''s royal family.'),
  (8, 'Masters of the Mystic Arts', 'Order of sorcerers based at Kamar-Taj protecting Earth from mystical threats.'),
  (9, 'Red Room', 'Soviet-born program that trained girls as Black Widow assassins, run by Dreykov.'),
  (10, 'Ravagers', 'Interstellar band of space pirates and smugglers.'),
  (11, 'Starforce', 'Elite Kree military unit under Yon-Rogg.'),
  (12, 'Eternals', 'Immortal beings sent by the Celestial Arishem to protect Earth from Deviants.'),
  (13, 'X-Men', 'Team of mutant heroes.');

------------------------------------------------------------------
-- 4. Movies
------------------------------------------------------------------
UPDATE Movie SET ReleaseDate = '2008-05-02', RuntimeMinutes = 126, MPAARating = 'PG-13', IMDbID = 'tt0371746', DistributorID = 1, BudgetMinUSD = 150000000, BudgetMaxUSD = 150000000, OpeningWeekendDomesticUSD = 98618668, DomesticGrossUSD = 319034126, WorldwideGrossUSD = 585796247, RTCriticsPct = 94, RTAudiencePct = 91, MetacriticScore = 79, CinemaScore = 'A' WHERE MovieID = 1;
UPDATE Movie SET ReleaseDate = '2008-06-13', RuntimeMinutes = 112, MPAARating = 'PG-13', IMDbID = 'tt0800080', DistributorID = 3, BudgetMinUSD = 150000000, BudgetMaxUSD = 150000000, OpeningWeekendDomesticUSD = 55414050, DomesticGrossUSD = 134806913, WorldwideGrossUSD = 264770996, RTCriticsPct = 68, RTAudiencePct = 69, MetacriticScore = 61, CinemaScore = 'A-' WHERE MovieID = 2;
UPDATE Movie SET ReleaseDate = '2010-05-07', RuntimeMinutes = 125, MPAARating = 'PG-13', IMDbID = 'tt1228705', DistributorID = 1, BudgetMinUSD = 170000000, BudgetMaxUSD = 170000000, OpeningWeekendDomesticUSD = 128122480, DomesticGrossUSD = 312433331, WorldwideGrossUSD = 623933331, RTCriticsPct = 72, RTAudiencePct = 71, MetacriticScore = 57, CinemaScore = 'A' WHERE MovieID = 3;
UPDATE Movie SET ReleaseDate = '2012-05-04', RuntimeMinutes = 143, MPAARating = 'PG-13', IMDbID = 'tt0848228', DistributorID = 4, BudgetMinUSD = 220000000, BudgetMaxUSD = 225000000, OpeningWeekendDomesticUSD = 207438708, DomesticGrossUSD = 623357910, WorldwideGrossUSD = 1520538536, RTCriticsPct = 91, RTAudiencePct = 91, MetacriticScore = 69, CinemaScore = 'A+' WHERE MovieID = 4;
UPDATE Movie SET ReleaseDate = '2013-05-03', RuntimeMinutes = 130, MPAARating = 'PG-13', IMDbID = 'tt1300854', DistributorID = 4, BudgetMinUSD = 200000000, BudgetMaxUSD = 200000000, OpeningWeekendDomesticUSD = 174144585, DomesticGrossUSD = 409013994, WorldwideGrossUSD = 1215577205, RTCriticsPct = 79, RTAudiencePct = 78, MetacriticScore = 62, CinemaScore = 'A' WHERE MovieID = 5;
UPDATE Movie SET ReleaseDate = '2015-05-01', RuntimeMinutes = 141, MPAARating = 'PG-13', IMDbID = 'tt2395427', DistributorID = 4, BudgetMinUSD = 365000000, BudgetMaxUSD = 365000000, OpeningWeekendDomesticUSD = 191271109, DomesticGrossUSD = 459005868, WorldwideGrossUSD = 1405018048, RTCriticsPct = 75, RTAudiencePct = 82, MetacriticScore = 66, CinemaScore = 'A' WHERE MovieID = 6;
UPDATE Movie SET ReleaseDate = '2016-05-06', RuntimeMinutes = 147, MPAARating = 'PG-13', IMDbID = 'tt3498820', DistributorID = 4, BudgetMinUSD = 250000000, BudgetMaxUSD = 250000000, OpeningWeekendDomesticUSD = 179139142, DomesticGrossUSD = 408084349, WorldwideGrossUSD = 1155046416, RTCriticsPct = 90, RTAudiencePct = 89, MetacriticScore = 75, CinemaScore = 'A' WHERE MovieID = 7;
UPDATE Movie SET ReleaseDate = '2017-07-07', RuntimeMinutes = 133, MPAARating = 'PG-13', IMDbID = 'tt2250912', DistributorID = 2, BudgetMinUSD = 175000000, BudgetMaxUSD = 175000000, OpeningWeekendDomesticUSD = 117027503, DomesticGrossUSD = 334201140, WorldwideGrossUSD = 880167151, RTCriticsPct = 92, RTAudiencePct = 87, MetacriticScore = 73, CinemaScore = 'A' WHERE MovieID = 8;
UPDATE Movie SET ReleaseDate = '2018-04-27', RuntimeMinutes = 149, MPAARating = 'PG-13', IMDbID = 'tt4154756', DistributorID = 4, BudgetMinUSD = 325000000, BudgetMaxUSD = 400000000, OpeningWeekendDomesticUSD = 257698183, DomesticGrossUSD = 678815482, WorldwideGrossUSD = 2052415039, RTCriticsPct = 85, RTAudiencePct = 92, MetacriticScore = 68, CinemaScore = 'A' WHERE MovieID = 9;
UPDATE Movie SET ReleaseDate = '2019-04-26', RuntimeMinutes = 181, MPAARating = 'PG-13', IMDbID = 'tt4154796', DistributorID = 4, BudgetMinUSD = 356000000, BudgetMaxUSD = 400000000, OpeningWeekendDomesticUSD = 357115007, DomesticGrossUSD = 898471864, WorldwideGrossUSD = 2942522839, RTCriticsPct = 94, RTAudiencePct = 90, MetacriticScore = 78, CinemaScore = 'A+' WHERE MovieID = 10;
UPDATE Movie SET ReleaseDate = '2011-07-22', RuntimeMinutes = 124, MPAARating = 'PG-13', IMDbID = 'tt0458339', DistributorID = 1, BudgetMinUSD = 140000000, BudgetMaxUSD = 216700000, OpeningWeekendDomesticUSD = 65058524, DomesticGrossUSD = 176654505, WorldwideGrossUSD = 370569774, RTCriticsPct = 80, RTAudiencePct = 75, MetacriticScore = 66, CinemaScore = 'A-' WHERE MovieID = 11;
UPDATE Movie SET ReleaseDate = '2013-11-08', RuntimeMinutes = 112, MPAARating = 'PG-13', IMDbID = 'tt1981115', DistributorID = 4, BudgetMinUSD = 150000000, BudgetMaxUSD = 272100000, OpeningWeekendDomesticUSD = 85737841, DomesticGrossUSD = 206362140, WorldwideGrossUSD = 644783140, RTCriticsPct = 67, RTAudiencePct = 74, MetacriticScore = 54, CinemaScore = 'A-' WHERE MovieID = 12;
UPDATE Movie SET ReleaseDate = '2014-04-04', RuntimeMinutes = 136, MPAARating = 'PG-13', IMDbID = 'tt1843866', DistributorID = 4, BudgetMinUSD = 170000000, BudgetMaxUSD = 177000000, OpeningWeekendDomesticUSD = 95023721, DomesticGrossUSD = 259766572, WorldwideGrossUSD = 714421503, RTCriticsPct = 90, RTAudiencePct = 92, MetacriticScore = 70, CinemaScore = 'A' WHERE MovieID = 13;
UPDATE Movie SET ReleaseDate = '2019-03-08', RuntimeMinutes = 124, MPAARating = 'PG-13', IMDbID = 'tt4154664', DistributorID = 4, BudgetMinUSD = 152000000, BudgetMaxUSD = 175000000, OpeningWeekendDomesticUSD = 153433423, DomesticGrossUSD = 426829839, WorldwideGrossUSD = 1131416446, RTCriticsPct = 79, RTAudiencePct = 45, MetacriticScore = 64, CinemaScore = 'A' WHERE MovieID = 14;
UPDATE Movie SET ReleaseDate = '2011-05-06', RuntimeMinutes = 114, MPAARating = 'PG-13', IMDbID = 'tt0800369', DistributorID = 1, BudgetMinUSD = 150000000, BudgetMaxUSD = 150000000, OpeningWeekendDomesticUSD = 65723338, DomesticGrossUSD = 181030624, WorldwideGrossUSD = 449326618, RTCriticsPct = 77, RTAudiencePct = 76, MetacriticScore = 57, CinemaScore = 'B+' WHERE MovieID = 15;
UPDATE Movie SET ReleaseDate = '2017-11-03', RuntimeMinutes = 130, MPAARating = 'PG-13', IMDbID = 'tt3501632', DistributorID = 4, BudgetMinUSD = 180000000, BudgetMaxUSD = 180000000, OpeningWeekendDomesticUSD = 122744989, DomesticGrossUSD = 315058289, WorldwideGrossUSD = 855301806, RTCriticsPct = 93, RTAudiencePct = 87, MetacriticScore = 74, CinemaScore = 'A' WHERE MovieID = 16;
UPDATE Movie SET ReleaseDate = '2014-08-01', RuntimeMinutes = 122, MPAARating = 'PG-13', IMDbID = 'tt2015381', DistributorID = 4, BudgetMinUSD = 195900000, BudgetMaxUSD = 195900000, OpeningWeekendDomesticUSD = 94320883, DomesticGrossUSD = 333718600, WorldwideGrossUSD = 773350376, RTCriticsPct = 91, RTAudiencePct = 92, MetacriticScore = 76, CinemaScore = 'A' WHERE MovieID = 17;
UPDATE Movie SET ReleaseDate = '2017-05-05', RuntimeMinutes = 136, MPAARating = 'PG-13', IMDbID = 'tt3896198', DistributorID = 4, BudgetMinUSD = 200000000, BudgetMaxUSD = 200000000, OpeningWeekendDomesticUSD = 146510104, DomesticGrossUSD = 389813101, WorldwideGrossUSD = 863756903, RTCriticsPct = 85, RTAudiencePct = 87, MetacriticScore = 67, CinemaScore = 'A' WHERE MovieID = 18;
UPDATE Movie SET ReleaseDate = '2015-07-17', RuntimeMinutes = 117, MPAARating = 'PG-13', IMDbID = 'tt0478970', DistributorID = 4, BudgetMinUSD = 130000000, BudgetMaxUSD = 169300000, OpeningWeekendDomesticUSD = 57225526, DomesticGrossUSD = 180202163, WorldwideGrossUSD = 519311965, RTCriticsPct = 83, RTAudiencePct = 85, MetacriticScore = 64, CinemaScore = 'A' WHERE MovieID = 19;
UPDATE Movie SET ReleaseDate = '2018-07-06', RuntimeMinutes = 118, MPAARating = 'PG-13', IMDbID = 'tt5095030', DistributorID = 4, BudgetMinUSD = 130000000, BudgetMaxUSD = 195000000, OpeningWeekendDomesticUSD = 75812205, DomesticGrossUSD = 216648740, WorldwideGrossUSD = 622674139, RTCriticsPct = 87, RTAudiencePct = 78, MetacriticScore = 70, CinemaScore = 'A-' WHERE MovieID = 20;
UPDATE Movie SET ReleaseDate = '2016-11-04', RuntimeMinutes = 115, MPAARating = 'PG-13', IMDbID = 'tt1211837', DistributorID = 4, BudgetMinUSD = 165000000, BudgetMaxUSD = 236600000, OpeningWeekendDomesticUSD = 85058311, DomesticGrossUSD = 232641920, WorldwideGrossUSD = 677796833, RTCriticsPct = 89, RTAudiencePct = 86, MetacriticScore = 72, CinemaScore = 'A' WHERE MovieID = 21;
UPDATE Movie SET ReleaseDate = '2018-02-16', RuntimeMinutes = 134, MPAARating = 'PG-13', IMDbID = 'tt1825683', DistributorID = 4, BudgetMinUSD = 200000000, BudgetMaxUSD = 200000000, OpeningWeekendDomesticUSD = 202003951, DomesticGrossUSD = 700426566, WorldwideGrossUSD = 1349926083, RTCriticsPct = 96, RTAudiencePct = 79, MetacriticScore = 88, CinemaScore = 'A+' WHERE MovieID = 22;
-- Remove ReleaseYear by rebuilding Movie (ALTER TABLE ... DROP COLUMN needs SQLite 3.35+).
CREATE TABLE Movie_new (
  MovieID                   INTEGER PRIMARY KEY,
  Title                     TEXT    NOT NULL UNIQUE,
  UniverseYear              INTEGER,
  IMDBRating                REAL,
  PhaseID                   INTEGER NOT NULL REFERENCES Phase(PhaseID),
  ReleaseDate               TEXT,
  RuntimeMinutes            INTEGER,
  MPAARating                TEXT,
  IMDbID                    TEXT,
  DistributorID             INTEGER REFERENCES Distributor(DistributorID),
  BudgetMinUSD              INTEGER,
  BudgetMaxUSD              INTEGER,
  OpeningWeekendDomesticUSD INTEGER,
  DomesticGrossUSD          INTEGER,
  WorldwideGrossUSD         INTEGER,
  RTCriticsPct              INTEGER,
  RTAudiencePct             INTEGER,
  MetacriticScore           INTEGER,
  CinemaScore               TEXT
);
INSERT INTO Movie_new (MovieID, Title, UniverseYear, IMDBRating, PhaseID, ReleaseDate, RuntimeMinutes, MPAARating, IMDbID, DistributorID, BudgetMinUSD, BudgetMaxUSD, OpeningWeekendDomesticUSD, DomesticGrossUSD, WorldwideGrossUSD, RTCriticsPct, RTAudiencePct, MetacriticScore, CinemaScore)
  SELECT MovieID, Title, UniverseYear, IMDBRating, PhaseID, ReleaseDate, RuntimeMinutes, MPAARating, IMDbID, DistributorID, BudgetMinUSD, BudgetMaxUSD, OpeningWeekendDomesticUSD, DomesticGrossUSD, WorldwideGrossUSD, RTCriticsPct, RTAudiencePct, MetacriticScore, CinemaScore FROM Movie;
DROP TABLE Movie;
ALTER TABLE Movie_new RENAME TO Movie;
INSERT INTO Movie (MovieID, Title, UniverseYear, IMDBRating, PhaseID, ReleaseDate, RuntimeMinutes, MPAARating, IMDbID, DistributorID, BudgetMinUSD, BudgetMaxUSD, OpeningWeekendDomesticUSD, DomesticGrossUSD, WorldwideGrossUSD, RTCriticsPct, RTAudiencePct, MetacriticScore, CinemaScore) VALUES
  (23, 'Spider-Man: Far From Home', 2024, 7.3, 3, '2019-07-02', 129, 'PG-13', 'tt6320628', 2, 160000000, 160000000, 92579212, 391283774, 1132723226, 91, 95, 69, 'A'),
  (24, 'Black Widow', 2016, 6.6, 4, '2021-07-09', 134, 'PG-13', 'tt3480822', 4, 288500000, 288500000, 80366312, 183651655, 379751655, 79, 91, 68, 'A-'),
  (25, 'Shang-Chi and the Legend of the Ten Rings', 2024, 7.3, 4, '2021-09-03', 132, 'PG-13', 'tt9376612', 4, 150000000, 200000000, 75388688, 224543292, 432243292, 92, 98, 71, 'A'),
  (26, 'Eternals', 2024, 6.2, 4, '2021-11-05', 156, 'PG-13', 'tt9032400', 4, 236200000, 236200000, 71297219, 164870234, 402064899, 48, 77, 52, 'B'),
  (27, 'Spider-Man: No Way Home', 2024, 8.1, 4, '2021-12-17', 148, 'PG-13', 'tt10872600', 2, 200000000, 200000000, 260138569, 814866759, 1921426073, 93, 97, 71, 'A+'),
  (28, 'Doctor Strange in the Multiverse of Madness', 2024, 6.8, 4, '2022-05-06', 126, 'PG-13', 'tt9419884', 4, 350600000, 350600000, 187420998, 411331607, 955775804, 73, 85, 60, 'B+'),
  (29, 'Thor: Love and Thunder', 2025, 6.1, 4, '2022-07-08', 119, 'PG-13', 'tt10648342', 4, 250000000, 250000000, 144165107, 343256830, 760928081, 64, 76, 57, 'B+'),
  (30, 'Black Panther: Wakanda Forever', 2025, 6.6, 4, '2022-11-11', 161, 'PG-13', 'tt9114286', 4, 200000000, 250000000, 181339761, 453829060, 859208836, 84, 93, 67, 'A'),
  (31, 'Ant-Man and the Wasp: Quantumania', 2026, 6.0, 5, '2023-02-17', 124, 'PG-13', 'tt10954600', 4, 330100000, 330100000, 106109650, 214504909, 476071180, 46, 81, 48, 'B'),
  (32, 'Guardians of the Galaxy Vol. 3', 2026, 7.9, 5, '2023-05-05', 150, 'PG-13', 'tt6791350', 4, 250000000, 250000000, 118414021, 358995815, 845555777, 82, 94, 64, 'A'),
  (33, 'The Marvels', 2026, 5.4, 5, '2023-11-10', 105, 'PG-13', 'tt10676048', 4, 307300000, 307300000, 46110859, 84500223, 206136825, 63, 79, 50, 'B'),
  (34, 'Deadpool & Wolverine', 2024, 7.5, 5, '2024-07-26', 128, 'R', 'tt6263850', 4, 429000000, 429000000, 211435291, 636745858, 1338073645, 77, 94, 56, 'A'),
  (35, 'Captain America: Brave New World', 2027, 5.6, 5, '2025-02-14', 118, 'PG-13', 'tt14513804', 4, 180000000, 180000000, 88842603, 200500001, 415101577, 46, 75, 42, 'B-'),
  (36, 'Thunderbolts*', 2027, 7.1, 5, '2025-05-02', 127, 'PG-13', 'tt20969586', 4, 180000000, 180000000, 74300608, 190274328, 382436917, 88, 93, 68, 'A-'),
  (37, 'The Fantastic Four: First Steps', 1964, 6.8, 6, '2025-07-25', 114, 'PG-13', 'tt10676052', 4, 181000000, 181000000, 117644828, 274286610, 521858728, 86, 90, 65, 'A-'),
  (38, 'Spider-Man: Brand New Day', 2028, 7.9, 6, '2026-07-31', 145, 'PG-13', 'tt22084616', 2, 225000000, 225000000, 360091572, 958886996, 2521157572, 90, 97, 66, 'A');

------------------------------------------------------------------
-- 5. Characters
------------------------------------------------------------------
UPDATE Character SET RealName = 'Anthony Edward Stark', SpeciesID = 12, Description = 'Genius industrialist who builds a powered armor suit after being held captive, founding member of the Avengers who sacrifices himself to defeat Thanos.' WHERE CharacterID = 1;
UPDATE Character SET RealName = 'Steven Grant Rogers', SpeciesID = 7, Description = 'Super-soldier from World War II revived in the present day; leader of the Avengers who later passes the shield to Sam Wilson.' WHERE CharacterID = 2;
UPDATE Character SET RealName = 'Natalia Alianovna Romanova', SpeciesID = 12, Description = 'Former Red Room assassin turned S.H.I.E.L.D. agent and founding Avenger who gives her life on Vormir for the Soul Stone.' WHERE CharacterID = 3;
UPDATE Character SET RealName = 'Thor Odinson', SpeciesID = 3, Description = 'Asgardian god of thunder and prince, later king, of Asgard; founding member of the Avengers.' WHERE CharacterID = 4;
UPDATE Character SET RealName = 'Robert Bruce Banner', SpeciesID = 7, Description = 'Physicist whose gamma-radiation accident lets him transform into a powerful green giant; eventually merges his two personas.' WHERE CharacterID = 5;
UPDATE Character SET RealName = 'Clinton Francis Barton', SpeciesID = 12, Description = 'Expert archer and S.H.I.E.L.D. agent, founding member of the Avengers who briefly operates as the vigilante Ronin.' WHERE CharacterID = 6;
UPDATE Character SET RealName = 'Nicholas Joseph Fury', SpeciesID = 12, Description = 'Director of S.H.I.E.L.D. who initiates the Avengers Initiative and later works with the Skrulls in space.' WHERE CharacterID = 7;
UPDATE Character SET RealName = 'James Rupert Rhodes', SpeciesID = 12, Description = 'U.S. Air Force officer and Tony Stark''s best friend who pilots the War Machine armor.' WHERE CharacterID = 8;
UPDATE Character SET RealName = 'J.A.R.V.I.S. (Just A Rather Very Intelligent System)', SpeciesID = 2, Description = 'Tony Stark''s artificial-intelligence assistant whose code becomes part of Vision.' WHERE CharacterID = 9;
UPDATE Character SET RealName = 'Vision', SpeciesID = 1, Description = 'Synthetic being created from Ultron''s body, JARVIS''s code and the Mind Stone; member of the Avengers.' WHERE CharacterID = 10;
UPDATE Character SET RealName = 'Peter Benjamin Parker', SpeciesID = 7, Description = 'Teenager from Queens with spider-like abilities, mentored by Tony Stark; later erased from everyone''s memory by a spell.' WHERE CharacterID = 11;
UPDATE Character SET RealName = 'Thanos', SpeciesID = 20, Description = 'Titan warlord who gathers the Infinity Stones to wipe out half of all life in the universe.' WHERE CharacterID = 12;
UPDATE Character SET RealName = 'Peter Jason Quill', SpeciesID = 13, Description = 'Half-human, half-Celestial outlaw raised by Ravagers and leader of the Guardians of the Galaxy.' WHERE CharacterID = 13;
UPDATE Character SET RealName = 'Gamora', SpeciesID = 21, Description = 'Adopted daughter of Thanos and skilled assassin who joins the Guardians of the Galaxy; a 2014 variant survives Endgame.' WHERE CharacterID = 14;
UPDATE Character SET RealName = 'Drax', SpeciesID = 17, Description = 'Warrior seeking revenge on Ronan and Thanos for the murder of his family; member of the Guardians of the Galaxy.' WHERE CharacterID = 15;
UPDATE Character SET RealName = 'Groot', SpeciesID = 9, Description = 'Tree-like Flora colossus who can only say "I am Groot"; regrows from a twig after sacrificing himself.' WHERE CharacterID = 16;
UPDATE Character SET RealName = 'Rocket (89P13)', SpeciesID = 11, Description = 'Genetically and cybernetically altered raccoon, expert pilot and weapons engineer, later leader of the Guardians.' WHERE CharacterID = 17;
UPDATE Character SET RealName = 'Ultron', SpeciesID = 2, Description = 'Artificial intelligence created by Tony Stark and Bruce Banner that turns on humanity.' WHERE CharacterID = 18;
UPDATE Character SET RealName = 'Scott Edward Harris Lang', SpeciesID = 12, Description = 'Reformed thief who uses Hank Pym''s suit to shrink or grow; member of the Avengers.' WHERE CharacterID = 19;
UPDATE Character SET RealName = 'Stephen Vincent Strange', SpeciesID = 12, Description = 'Former neurosurgeon who becomes a master of the mystic arts and Sorcerer Supreme.' WHERE CharacterID = 20;
UPDATE Character SET RealName = 'T''Challa', SpeciesID = 12, Description = 'King of Wakanda who protects his nation with the powers of the Heart-Shaped Herb and a vibranium suit.' WHERE CharacterID = 21;
INSERT INTO Character (CharacterID, CharacterName, RealName, SpeciesID, Description) VALUES
  (22, 'Loki', 'Loki Laufeyson', 10, 'Asgardian god of mischief, adopted brother of Thor, who leads the Chitauri invasion of New York.'),
  (23, 'Scarlet Witch', 'Wanda Maximoff', 7, 'Sokovian with reality-warping chaos magic enhanced by the Mind Stone; member of the Avengers.'),
  (24, 'Falcon', 'Samuel Thomas Wilson', 12, 'Former pararescue airman who flies with a winged suit; succeeds Steve Rogers as Captain America.'),
  (25, 'Winter Soldier', 'James Buchanan Barnes', 7, 'Steve Rogers'' childhood friend, brainwashed by Hydra into an assassin, later reformed and a Thunderbolts member.'),
  (26, 'Captain Marvel', 'Carol Susan Jane Danvers', 14, 'Former U.S. Air Force pilot who gains cosmic powers from the Tesseract''s energy; one of the most powerful Avengers.'),
  (27, 'Wasp', 'Hope van Dyne', 12, 'Hank Pym''s daughter who fights alongside Ant-Man in a suit with wings and blasters.'),
  (28, 'Nebula', 'Nebula', 18, 'Adopted daughter of Thanos and cyborg warrior who reconciles with Gamora and joins the Guardians.'),
  (29, 'Mantis', 'Mantis', 15, 'Empath raised by Ego who can sense and manipulate emotions; member of the Guardians of the Galaxy.'),
  (30, 'Wong', 'Wong', 12, 'Master of the mystic arts and librarian of Kamar-Taj who becomes Sorcerer Supreme.'),
  (31, 'Shuri', 'Shuri', 12, 'Princess of Wakanda and its chief technologist who takes up the mantle of Black Panther.'),
  (32, 'Okoye', 'Okoye', 12, 'General of the Dora Milaje, the all-female special forces of Wakanda.'),
  (33, 'Valkyrie', 'Brunnhilde', 3, 'Last of Asgard''s elite female warriors who becomes king of New Asgard.'),
  (34, 'Jane Foster', 'Jane Foster', 12, 'Astrophysicist and Thor''s former partner who wields Mjolnir as the Mighty Thor.'),
  (35, 'Pepper Potts', 'Virginia Potts', 12, 'Tony Stark''s assistant, later CEO of Stark Industries and his wife, who fights in the Rescue armor.'),
  (36, 'Happy Hogan', 'Harold Joseph Hogan', 12, 'Tony Stark''s bodyguard and driver who later looks out for Peter Parker.'),
  (37, 'Hank Pym', 'Henry Pym', 12, 'Scientist who discovered the Pym particle and was the original Ant-Man.'),
  (38, 'Cassie Lang', 'Cassandra Lang', 12, 'Scott Lang''s daughter who grows up to build her own suit and fight beside him.'),
  (39, 'Yelena Belova', 'Yelena Belova', 12, 'Red Room-trained Black Widow raised as Natasha Romanoff''s sister; leader of the Thunderbolts.'),
  (40, 'Red Guardian', 'Alexei Shostakov', 7, 'Soviet super-soldier and Yelena''s adoptive father, a member of the Thunderbolts.'),
  (41, 'Ghost', 'Ava Starr', 7, 'Woman who can phase through matter after a quantum accident; later a Thunderbolts member.'),
  (42, 'U.S. Agent', 'John F. Walker', 7, 'Soldier briefly named the new Captain America who later joins the Thunderbolts.'),
  (43, 'Sentry', 'Robert Reynolds', 7, 'Bob Reynolds, a man given immense powers by an experiment, whose dark side manifests as the Void.'),
  (44, 'Shang-Chi', 'Xu Shang-Chi', 12, 'Martial artist and son of Wenwu who inherits the Ten Rings.'),
  (45, 'Sersi', 'Sersi', 8, 'Eternal with the power to transmute matter who leads her team to stop the Emergence.'),
  (46, 'Ms. Marvel', 'Kamala Khan', 19, 'Teenage Avengers fan from Jersey City whose ancestral bangle unlocks light-based powers.'),
  (47, 'Monica Rambeau', 'Monica Rambeau', 7, 'Daughter of Carol Danvers'' best friend who gains the ability to perceive and manipulate energy.'),
  (48, 'Deadpool', 'Wade Wilson', 19, 'Wisecracking mercenary with accelerated healing who wants to matter in the larger multiverse.'),
  (49, 'Wolverine', 'James Howlett (Logan)', 19, 'Mutant with retractable adamantium claws and a healing factor, recruited from another universe by Deadpool.'),
  (50, 'Thaddeus Ross', 'Thaddeus Ross', 7, 'U.S. Army general turned Secretary of State and later U.S. President who transforms into the Red Hulk.'),
  (51, 'Mister Fantastic', 'Reed Richards', 7, 'Scientist with a stretchable body and leader of the Fantastic Four.'),
  (52, 'Invisible Woman', 'Susan Storm', 7, 'Member of the Fantastic Four who can turn invisible and project force fields.'),
  (53, 'Human Torch', 'Jonathan Storm', 7, 'Member of the Fantastic Four who can engulf himself in flames and fly.'),
  (54, 'The Thing', 'Benjamin Grimm', 7, 'Member of the Fantastic Four transformed into a super-strong being made of orange rock.'),
  (55, 'MJ', 'Michelle Jones-Watson', 12, 'Peter Parker''s classmate and girlfriend who no longer remembers him after the spell in No Way Home.'),
  (56, 'Ned Leeds', 'Ned Leeds', 12, 'Peter Parker''s best friend who helps him behind the scenes.'),
  (57, 'Punisher', 'Frank Castle', 12, 'Vigilante former Marine who wages a lethal war on crime after the murder of his family.'),
  (58, 'Iron Monger', 'Obadiah Stane', 12, 'Tony Stark''s mentor and Stark Industries business partner who secretly sold weapons to terrorists and built the Iron Monger armor to kill Stark.'),
  (59, 'Abomination', 'Emil Blonsky', 7, 'A Russian-born British Royal Marines officer who took a super-soldier serum and Bruce Banner''s gamma-irradiated blood, transforming into the monstrous Abomination.'),
  (60, 'Whiplash', 'Ivan Vanko', 12, 'A Russian physicist and son of Anton Vanko who built his own arc reactor and electrified whips to take revenge on Tony Stark.'),
  (61, 'Red Skull', 'Johann Schmidt', 7, 'The head of HYDRA who took an early version of the super-soldier serum, was transported to Vormir by the Tesseract, and became the Stonekeeper of the Soul Stone.'),
  (62, 'Aldrich Killian', 'Aldrich Killian', 7, 'The founder of Advanced Idea Mechanics (A.I.M.) who used the Extremis virus on himself and others and invented ''the Mandarin'' as a front for his terrorist attacks.'),
  (63, 'Malekith', 'Malekith', 6, 'The ruler of the Dark Elves of Svartalfheim who sought to use the Aether to return the universe to darkness.'),
  (64, 'Alexander Pierce', 'Alexander Pierce', 12, 'A senior S.H.I.E.L.D. official and member of the World Security Council who was secretly a leader of HYDRA.'),
  (65, 'Ronan the Accuser', 'Ronan', 16, 'A Kree fanatic and Accuser who allied with Thanos to obtain the Orb (the Power Stone) and destroy Xandar.'),
  (66, 'Yellowjacket / M.O.D.O.K.', 'Darren Cross', 12, 'Hank Pym''s former protege who recreated the Pym Particle as the Yellowjacket suit and, after being lost in the Quantum Realm, was rebuilt by Kang as M.O.D.O.K.'),
  (67, 'Helmut Zemo', 'Helmut Zemo', 12, 'A Sokovian colonel and baron whose family died in the Battle of Sokovia and who manipulated events to turn the Avengers against each other.'),
  (68, 'Kaecilius', 'Kaecilius', 12, 'A former pupil of the Ancient One who led the Zealots in an effort to bring Dormammu and the Dark Dimension to Earth.'),
  (69, 'Ego', 'Ego', 4, 'A Celestial who took human form, fathered Peter Quill, and planned to remake the universe as an extension of himself.'),
  (70, 'Vulture', 'Adrian Toomes', 12, 'A salvage contractor who turned to selling weapons made from Chitauri technology and fought Spider-Man in a winged flight suit.'),
  (71, 'Hela', 'Hela', 3, 'Odin''s firstborn daughter and the former Goddess of Death and executioner of Asgard, who returned after Odin''s death to claim the throne.'),
  (72, 'Killmonger', 'N''Jadaka / Erik Stevens', 12, 'T''Challa''s cousin, the son of Prince N''Jobu, a former U.S. black-ops soldier who seized the throne of Wakanda.'),
  (73, 'Yon-Rogg', 'Yon-Rogg', 16, 'The commander of the Kree Starforce who trained Carol Danvers after her powers were taken by the Kree.'),
  (74, 'Mysterio', 'Quentin Beck', 12, 'A disgruntled former Stark Industries employee who used illusion technology to pose as a superhero from another Earth.'),
  (75, 'Dreykov', 'Dreykov', 12, 'A Russian general and the head of the Red Room who controlled the Widows through chemical mind control.'),
  (76, 'Taskmaster', 'Antonia Dreykov', 7, 'Dreykov''s daughter who, after being badly injured, was implanted with Red Room technology that gave her photographic reflexes and made her an assassin.'),
  (77, 'Wenwu', 'Xu Wenwu', 12, 'Shang-Chi''s father and the centuries-old leader of the Ten Rings organization, whose life was extended by the ten rings.'),
  (78, 'Ikaris', 'Ikaris', 8, 'An Eternal who stayed loyal to Arishem''s plan to let the Celestial Tiamut emerge from Earth, turning against his fellow Eternals.'),
  (79, 'Green Goblin', 'Norman Osborn', 7, 'An Oscorp scientist from another universe with a dangerous split personality, the Green Goblin, brought to the MCU''s Earth by a botched spell.'),
  (80, 'Gorr the God Butcher', 'Gorr', NULL, 'An alien whose daughter died after their god refused to help, and who wielded the Necrosword to kill gods.'),
  (81, 'Namor', 'K''uk''ulkan', 19, 'The mutant king of the underwater civilization of Talokan, who went to war against Wakanda to keep his kingdom hidden.'),
  (82, 'Kang the Conqueror', 'Kang', 12, 'An exiled variant of He Who Remains trapped in the Quantum Realm, who tried to escape to resume conquering the multiverse.'),
  (83, 'High Evolutionary', 'High Evolutionary', NULL, 'An alien cyborg scientist and the creator of Rocket, who experimented on animals and peoples to create a ''perfect'' society.'),
  (84, 'Dar-Benn', 'Dar-Benn', 16, 'The leader of the Kree Empire after the Supreme Intelligence, who used a Quantum Band to tear open jump points and steal other worlds'' resources.'),
  (85, 'Cassandra Nova', 'Cassandra Nova', 19, 'The powerful psionic twin sister of Charles Xavier, who ruled the Void at the end of time.'),
  (86, 'The Leader', 'Samuel Sterns', 7, 'A cell biologist whose exposure to Bruce Banner''s blood gave him super-intelligence, which he used to manipulate Thaddeus Ross.'),
  (87, 'Valentina Allegra de Fontaine', 'Valentina Allegra de Fontaine', 12, 'A contessa and later Director of the CIA who recruits super-powered operatives and assembles the Thunderbolts.'),
  (88, 'Galactus', 'Galactus', 5, 'A gigantic, ancient cosmic being who consumes the life force of planets and threatened to devour Earth in the Fantastic Four''s universe.'),
  (89, 'Jean Grey', 'Jean Grey', 19, 'A young telepathic mutant who searched for her sister Sara, who had been taken by the Department of Damage Control.'),
  (90, 'May Parker', 'May Parker', 12, 'Peter Parker''s aunt and guardian, who was killed by the Green Goblin.');

------------------------------------------------------------------
-- 6. People (actors and crew)
------------------------------------------------------------------
UPDATE Person SET BirthName = 'Robert John Downey Jr.', BirthDate = '1965-04-04', DeathDate = NULL, BirthPlace = 'New York City, New York, U.S.' WHERE PersonID = 1;
UPDATE Person SET BirthName = 'Christopher Robert Evans', BirthDate = '1981-06-13', DeathDate = NULL, BirthPlace = 'Boston, Massachusetts, U.S.' WHERE PersonID = 2;
UPDATE Person SET BirthName = 'Scarlett Ingrid Johansson', BirthDate = '1984-11-22', DeathDate = NULL, BirthPlace = 'New York City, New York, U.S.' WHERE PersonID = 3;
UPDATE Person SET BirthName = 'Christopher Hemsworth', BirthDate = '1983-08-11', DeathDate = NULL, BirthPlace = 'Melbourne, Victoria, Australia' WHERE PersonID = 4;
UPDATE Person SET BirthName = 'Mark Alan Ruffalo', BirthDate = '1967-11-22', DeathDate = NULL, BirthPlace = 'Kenosha, Wisconsin, U.S.' WHERE PersonID = 5;
UPDATE Person SET BirthName = 'Edward Harrison Norton', BirthDate = '1969-08-18', DeathDate = NULL, BirthPlace = 'Boston, Massachusetts, U.S.' WHERE PersonID = 6;
UPDATE Person SET BirthName = 'Jeremy Lee Renner', BirthDate = '1971-01-07', DeathDate = NULL, BirthPlace = 'Modesto, California, U.S.' WHERE PersonID = 7;
UPDATE Person SET BirthName = 'Samuel Leroy Jackson', BirthDate = '1948-12-21', DeathDate = NULL, BirthPlace = 'Washington, D.C., U.S.' WHERE PersonID = 8;
UPDATE Person SET BirthName = 'Terrence Dashon Howard', BirthDate = '1969-03-11', DeathDate = NULL, BirthPlace = 'Chicago, Illinois, U.S.' WHERE PersonID = 9;
UPDATE Person SET BirthName = 'Donald Frank Cheadle Jr.', BirthDate = '1964-11-29', DeathDate = NULL, BirthPlace = 'Kansas City, Missouri, U.S.' WHERE PersonID = 10;
UPDATE Person SET BirthName = 'Paul Bettany', BirthDate = '1971-05-27', DeathDate = NULL, BirthPlace = 'London, England, UK' WHERE PersonID = 11;
UPDATE Person SET BirthName = 'Thomas Stanley Holland', BirthDate = '1996-06-01', DeathDate = NULL, BirthPlace = 'London, England, UK' WHERE PersonID = 12;
UPDATE Person SET BirthName = 'Josh James Brolin', BirthDate = '1968-02-12', DeathDate = NULL, BirthPlace = 'Santa Monica, California, U.S.' WHERE PersonID = 13;
UPDATE Person SET BirthName = 'Christopher Michael Pratt', BirthDate = '1979-06-21', DeathDate = NULL, BirthPlace = 'Virginia, Minnesota, U.S.' WHERE PersonID = 14;
UPDATE Person SET BirthName = 'Zoë Yadira Saldaña Nazario', BirthDate = '1978-06-19', DeathDate = NULL, BirthPlace = 'Passaic, New Jersey, U.S.' WHERE PersonID = 15;
UPDATE Person SET BirthName = 'David Michael Bautista Jr.', BirthDate = '1969-01-18', DeathDate = NULL, BirthPlace = 'Washington, D.C., U.S.' WHERE PersonID = 16;
UPDATE Person SET BirthName = 'Mark Sinclair Vincent', BirthDate = '1967-07-18', DeathDate = NULL, BirthPlace = 'Alameda County, California, U.S.' WHERE PersonID = 17;
UPDATE Person SET BirthName = 'Bradley Charles Cooper', BirthDate = '1975-01-05', DeathDate = NULL, BirthPlace = 'Abington Township, Pennsylvania, U.S.' WHERE PersonID = 18;
UPDATE Person SET BirthName = 'James Todd Spader', BirthDate = '1960-02-07', DeathDate = NULL, BirthPlace = 'Boston, Massachusetts, U.S.' WHERE PersonID = 19;
UPDATE Person SET BirthName = 'Paul Stephen Rudd', BirthDate = '1969-04-06', DeathDate = NULL, BirthPlace = 'Passaic, New Jersey, U.S.' WHERE PersonID = 20;
UPDATE Person SET BirthName = 'Benedict Timothy Carlton Cumberbatch', BirthDate = '1976-07-19', DeathDate = NULL, BirthPlace = 'Hammersmith, London, England, UK' WHERE PersonID = 21;
UPDATE Person SET BirthName = 'Chadwick Aaron Boseman', BirthDate = '1976-11-29', DeathDate = '2020-08-28', BirthPlace = 'Anderson, South Carolina, U.S.' WHERE PersonID = 22;
-- 'Son Lux' (composer of Thunderbolts*) is a band credited as one entity, so it has no birth data.
INSERT INTO Person (PersonID, PersonName, BirthName, BirthDate, DeathDate, BirthPlace) VALUES
  (23, 'Tom Hiddleston', 'Thomas William Hiddleston', '1981-02-09', NULL, 'London, England, UK'),
  (24, 'Elizabeth Olsen', 'Elizabeth Chase Olsen', '1989-02-16', NULL, 'Los Angeles, California, U.S.'),
  (25, 'Anthony Mackie', 'Anthony Dwane Mackie', '1978-09-23', NULL, 'New Orleans, Louisiana, U.S.'),
  (26, 'Sebastian Stan', 'Sebastian Stan', '1982-08-13', NULL, 'Constanța, Romania'),
  (27, 'Brie Larson', 'Brianne Sidonie Desaulniers', '1989-10-01', NULL, 'Sacramento, California, U.S.'),
  (28, 'Evangeline Lilly', 'Nicole Evangeline Lilly', '1979-08-03', NULL, 'Fort Saskatchewan, Alberta, Canada'),
  (29, 'Karen Gillan', 'Karen Sheila Gillan', '1987-11-28', NULL, 'Inverness, Scotland, UK'),
  (30, 'Pom Klementieff', 'Pom Alexandra Klementieff', '1986-05-03', NULL, 'Quebec City, Quebec, Canada'),
  (31, 'Benedict Wong', 'Benedict Wong', '1971-07-03', NULL, 'Eccles, Lancashire, England, UK'),
  (32, 'Letitia Wright', 'Letitia Michelle Wright', '1993-10-31', NULL, 'Georgetown, Guyana'),
  (33, 'Danai Gurira', 'Danai Jekesai Gurira', '1978-02-14', NULL, 'Grinnell, Iowa, U.S.'),
  (34, 'Tessa Thompson', 'Tessa Lynne Thompson', '1983-10-03', NULL, 'Los Angeles, California, U.S.'),
  (35, 'Natalie Portman', 'Natalie Hershlag', '1981-06-09', NULL, 'Mount Scopus, Jerusalem, Israel'),
  (36, 'Gwyneth Paltrow', 'Gwyneth Kate Paltrow', '1972-09-27', NULL, 'Los Angeles, California, U.S.'),
  (37, 'Jon Favreau', 'Jonathan Kolia Favreau', '1966-10-19', NULL, 'New York City, New York, U.S.'),
  (38, 'Michael Douglas', 'Michael Kirk Douglas', '1944-09-25', NULL, 'New Brunswick, New Jersey, U.S.'),
  (39, 'Abby Ryder Fortson', 'Abby Ryder Fortson', '2008-03-14', NULL, 'Burbank, California, U.S.'),
  (40, 'Emma Fuhrmann', 'Emma Fuhrmann', '2001-09-15', NULL, 'Dallas, Texas, U.S.'),
  (41, 'Kathryn Newton', 'Kathryn Love Newton', '1997-02-08', NULL, 'Orlando, Florida, U.S.'),
  (42, 'Florence Pugh', 'Florence Pugh', '1996-01-03', NULL, 'Oxford, England, UK'),
  (43, 'David Harbour', 'David Kenneth Harbour', '1975-04-10', NULL, 'White Plains, New York, U.S.'),
  (44, 'Hannah John-Kamen', 'Hannah Dominique John-Kamen', '1989-09-07', NULL, 'Hull, East Yorkshire, England, UK'),
  (45, 'Wyatt Russell', 'Wyatt Hawn Russell', '1986-07-10', NULL, 'Los Angeles, California, U.S.'),
  (46, 'Lewis Pullman', 'Lewis James Pullman', '1993-01-29', NULL, 'Los Angeles, California, U.S.'),
  (47, 'Simu Liu', 'Simu Liu', '1989-04-19', NULL, 'Harbin, China'),
  (48, 'Gemma Chan', 'Gemma Chan', '1982-11-29', NULL, 'London, England, UK'),
  (49, 'Iman Vellani', 'Iman Vellani', '2002-08-12', NULL, 'Karachi, Sindh, Pakistan'),
  (50, 'Akira Akbar', 'Akira Jolie Akbar', '2006-10-02', NULL, 'U.S.'),
  (51, 'Teyonah Parris', 'Teyonah Parris', '1987-09-22', NULL, 'Hopkins, South Carolina, U.S.'),
  (52, 'Ryan Reynolds', 'Ryan Rodney Reynolds', '1976-10-23', NULL, 'Vancouver, British Columbia, Canada'),
  (53, 'Hugh Jackman', 'Hugh Michael Jackman', '1968-10-12', NULL, 'Sydney, New South Wales, Australia'),
  (54, 'Henry Cavill', 'Henry William Dalgliesh Cavill', '1983-05-05', NULL, 'St Helier, Jersey'),
  (55, 'William Hurt', 'William McChord Hurt', '1950-03-20', '2022-03-13', 'Washington, D.C., U.S.'),
  (56, 'Harrison Ford', 'Harrison Ford', '1942-07-13', NULL, 'Chicago, Illinois, U.S.'),
  (57, 'Pedro Pascal', 'José Pedro Balmaceda Pascal', '1975-04-02', NULL, 'Santiago, Chile'),
  (58, 'Vanessa Kirby', 'Vanessa Nuala Kirby', NULL, NULL, 'London, England, UK'),
  (59, 'Joseph Quinn', 'Joseph Quinn', '1994-01-26', NULL, 'London, England, UK'),
  (60, 'Ebon Moss-Bachrach', 'Ebon Che Moss-Bachrach', '1977-03-19', NULL, 'New York City, New York, U.S.'),
  (61, 'John Krasinski', 'John Burke Krasinski', '1979-10-20', NULL, 'Newton, Massachusetts, U.S.'),
  (62, 'Zendaya', 'Zendaya Maree Stoermer Coleman', '1996-09-01', NULL, 'Oakland, California, U.S.'),
  (63, 'Jacob Batalon', 'Jacob Andres Batalon', '1996-10-09', NULL, 'Honolulu, Hawaii, U.S.'),
  (64, 'Jon Bernthal', 'Jonathan Edward Bernthal', '1976-09-20', NULL, 'Washington, D.C., U.S.'),
  (65, 'Tobey Maguire', 'Tobias Vincent Maguire', '1975-06-27', NULL, 'Santa Monica, California, U.S.'),
  (66, 'Andrew Garfield', 'Andrew Russell Garfield', '1983-08-20', NULL, 'Los Angeles, California, U.S.'),
  (67, 'Jeff Bridges', 'Jeffrey Leon Bridges', '1949-12-04', NULL, 'Los Angeles, California, U.S.'),
  (68, 'Tim Roth', 'Timothy Simon Roth', '1961-05-14', NULL, 'London, England, UK'),
  (69, 'Mickey Rourke', 'Philip Andre Rourke Jr.', '1952-09-16', NULL, 'Schenectady, New York, U.S.'),
  (70, 'Hugo Weaving', 'Hugo Wallace Weaving', '1960-04-04', NULL, 'Ibadan, Oyo, Nigeria'),
  (71, 'Ross Marquand', 'Roscoe Wayne Marquand', '1981-08-22', NULL, 'Fort Collins, Colorado, U.S.'),
  (72, 'Guy Pearce', 'Guy Edward Pearce', '1967-10-05', NULL, 'Ely, England, UK'),
  (73, 'Christopher Eccleston', 'Christopher Eccleston', '1964-02-16', NULL, 'Salford, England, UK'),
  (74, 'Robert Redford', 'Charles Robert Redford Jr.', '1936-08-18', '2025-09-16', 'Santa Monica, California, U.S.'),
  (75, 'Lee Pace', 'Lee Grinner Pace', '1979-03-25', NULL, 'Chickasha, Oklahoma, U.S.'),
  (76, 'Corey Stoll', 'Corey Daniel Stoll', '1976-03-14', NULL, 'New York City, New York, U.S.'),
  (77, 'Daniel Brühl', 'Daniel César Martín Brühl González', '1978-06-16', NULL, 'Barcelona, Catalonia, Spain'),
  (78, 'Mads Mikkelsen', 'Mads Dittmann Mikkelsen', '1965-11-22', NULL, 'Copenhagen, Capital Region, Denmark'),
  (79, 'Kurt Russell', 'Kurt Vogel Russell', '1951-03-17', NULL, 'Springfield, Massachusetts, U.S.'),
  (80, 'Michael Keaton', 'Michael John Douglas', '1951-09-05', NULL, 'Kennedy Township, Pennsylvania, U.S.'),
  (81, 'Cate Blanchett', 'Catherine Élise Blanchett', '1969-05-14', NULL, 'Melbourne, Victoria, Australia'),
  (82, 'Michael B. Jordan', 'Michael Bakari Jordan', '1987-02-09', NULL, 'Santa Ana, California, U.S.'),
  (83, 'Jude Law', 'David Jude Heyworth Law', '1972-12-29', NULL, 'London, England, UK'),
  (84, 'Jake Gyllenhaal', 'Jacob Benjamin Gyllenhaal', '1980-12-19', NULL, 'Los Angeles, California, U.S.'),
  (85, 'Ray Winstone', 'Raymond Andrew Winstone', '1957-02-19', NULL, 'London, England, UK'),
  (86, 'Olga Kurylenko', 'Olga Kostyantynivna Kurylenko', '1979-11-14', NULL, 'Berdiansk, Zaporizhzhia Oblast, Ukraine'),
  (87, 'Tony Leung Chiu-wai', 'Leung Chiu-wai', '1962-06-27', NULL, 'Hong Kong, China'),
  (88, 'Richard Madden', 'Richard Madden', '1986-06-18', NULL, 'Elderslie, Scotland, UK'),
  (89, 'Willem Dafoe', 'William James Dafoe', '1955-07-22', NULL, 'Appleton, Wisconsin, U.S.'),
  (90, 'Christian Bale', 'Christian Charles Philip Bale', '1974-01-30', NULL, 'Haverfordwest, Wales, UK'),
  (91, 'Tenoch Huerta Mejía', 'Tenoch Huerta Mejía', '1981-01-29', NULL, 'Ecatepec, State of Mexico, Mexico'),
  (92, 'Jonathan Majors', 'Jonathan Michael Majors', '1989-09-07', NULL, 'Lompoc, California, U.S.'),
  (93, 'Chukwudi Iwuji', 'Chukwudi Iwuji', '1975-10-15', NULL, 'Nigeria'),
  (94, 'Zawe Ashton', 'Zawedde Emma Ashton', '1984-07-25', NULL, 'London, England, UK'),
  (95, 'Emma Corrin', 'Emma Louise Corrin', '1995-12-13', NULL, 'Royal Tunbridge Wells, England, UK'),
  (96, 'Tim Blake Nelson', 'Timothy Blake Nelson', '1964-05-11', NULL, 'Tulsa, Oklahoma, U.S.'),
  (97, 'Julia Louis-Dreyfus', 'Julia Scarlett Elizabeth Louis-Dreyfus', '1961-01-13', NULL, 'New York City, New York, U.S.'),
  (98, 'Ralph Ineson', 'Ralph Michael Ineson', '1969-12-15', NULL, 'Leeds, England, UK'),
  (99, 'Marisa Tomei', 'Marisa Tomei', '1964-12-04', NULL, 'Brooklyn, New York, U.S.'),
  (100, 'Sadie Sink', 'Sadie Elizabeth Sink', '2002-04-16', NULL, 'Brenham, Texas, U.S.'),
  (101, 'Kevin Feige', 'Kevin Feige', '1973-06-02', NULL, 'Boston, Massachusetts, U.S.'),
  (102, 'Avi Arad', 'Avi Arad', '1948-08-01', NULL, 'Ramat Gan, Tel Aviv District, Israel'),
  (103, 'Mark Fergus', 'Mark Fergus', NULL, NULL, NULL),
  (104, 'Hawk Ostby', 'Hawk Ostby', NULL, NULL, NULL),
  (105, 'Art Marcum', 'Art Marcum', NULL, NULL, NULL),
  (106, 'Matt Holloway', 'Matt Holloway', NULL, NULL, NULL),
  (107, 'Ramin Djawadi', 'Ramin Djawadi', '1974-07-19', NULL, 'Duisburg, North Rhine-Westphalia, West Germany'),
  (108, 'Louis Leterrier', 'Louis Leterrier', '1973-06-17', NULL, 'Paris, Île-de-France, France'),
  (109, 'Zak Penn', 'Zak Penn', '1968-03-23', NULL, 'New York City, New York, U.S.'),
  (110, 'Craig Armstrong', 'Craig Mackenzie Armstrong', '1959-04-29', NULL, 'Glasgow, Scotland, UK'),
  (111, 'Gale Anne Hurd', 'Gale Anne Hurd', '1955-10-25', NULL, 'Los Angeles, California, U.S.'),
  (112, 'Justin Theroux', 'Justin Paul Theroux', '1971-08-10', NULL, 'Washington, D.C., U.S.'),
  (113, 'John Debney', 'John Cardon Debney', '1956-08-18', NULL, 'Glendale, California, U.S.'),
  (114, 'Joss Whedon', 'Joseph Hill Whedon', '1964-06-23', NULL, 'New York City, New York, U.S.'),
  (115, 'Alan Silvestri', 'Alan Anthony Silvestri', '1950-03-26', NULL, 'New York City, New York, U.S.'),
  (116, 'Shane Black', 'Shane Black', '1961-12-16', NULL, 'Pittsburgh, Pennsylvania, U.S.'),
  (117, 'Drew Pearce', 'Drew Pearce', '1975-08-24', NULL, 'Fife, Scotland, UK'),
  (118, 'Brian Tyler', 'Brian Theodore Tyler', '1972-05-08', NULL, 'Orange County, California, U.S.'),
  (119, 'Danny Elfman', 'Daniel Robert Elfman', '1953-05-29', NULL, 'Los Angeles, California, U.S.'),
  (120, 'Anthony Russo', 'Anthony J. Russo', '1970-02-03', NULL, 'Cleveland, Ohio, U.S.'),
  (121, 'Joe Russo', 'Joseph Vincent Russo', '1971-07-18', NULL, 'Cleveland, Ohio, U.S.'),
  (122, 'Christopher Markus', 'Christopher Markus', '1969-10-16', NULL, 'Buffalo, New York, U.S.'),
  (123, 'Stephen McFeely', 'Stephen McFeely', '1970-02-24', NULL, 'Walnut Creek, California, U.S.'),
  (124, 'Henry Jackman', 'Henry Pryce Jackman', '1974-06-01', NULL, 'London, England, UK'),
  (125, 'Jon Watts', 'Jonathan Watts', '1981-06-28', NULL, 'Fountain, Colorado, U.S.'),
  (126, 'Jonathan Goldstein', 'Jonathan Michael Goldstein', '1968-09-02', NULL, 'New York City, New York, U.S.'),
  (127, 'John Francis Daley', 'John Francis Daley', '1985-07-20', NULL, 'Wheeling, Illinois, U.S.'),
  (128, 'Christopher Ford', 'Christopher D. Ford', NULL, NULL, NULL),
  (129, 'Chris McKenna', 'Chris McKenna', NULL, NULL, NULL),
  (130, 'Erik Sommers', 'Erik Sommers', '1976-12-16', NULL, 'Syracuse, New York, U.S.'),
  (131, 'Michael Giacchino', 'Michael Giacchino', '1967-10-10', NULL, 'Riverside Township, New Jersey, U.S.'),
  (132, 'Amy Pascal', 'Amy Pascal', '1958-03-25', NULL, 'Los Angeles, California, U.S.'),
  (133, 'Joe Johnston', 'Joseph Eggleston Johnston II', '1950-05-13', NULL, 'Austin, Texas, U.S.'),
  (134, 'Alan Taylor', 'Alan Taylor', '1959-01-13', NULL, 'Ann Arbor, Michigan, U.S.'),
  (135, 'Christopher L. Yost', 'Christopher Lee Yost', '1973-02-21', NULL, 'St. Louis, Missouri, U.S.'),
  (136, 'Anna Boden', 'Anna Boden', '1979-10-20', NULL, 'Newton, Massachusetts, U.S.'),
  (137, 'Ryan Fleck', 'Ryan K. Fleck', '1976-09-20', NULL, 'Berkeley, California, U.S.'),
  (138, 'Geneva Robertson-Dworet', 'Geneva Robertson-Dworet', '1985-05-08', NULL, 'Baltimore, Maryland, U.S.'),
  (139, 'Pinar Toprak', 'Pınar Toprak', '1980-10-18', NULL, 'Istanbul, Istanbul Province, Turkey'),
  (140, 'Kenneth Branagh', 'Kenneth Charles Branagh', '1960-12-10', NULL, 'Belfast, Northern Ireland, UK'),
  (141, 'Ashley Edward Miller', 'Ashley Edward Miller', '1971-03-16', NULL, 'Windber, Pennsylvania, U.S.'),
  (142, 'Zack Stentz', 'Zackary Lowell Stentz', NULL, NULL, 'Fort Bragg, California, U.S.'),
  (143, 'Don Payne', 'William Donald Payne', '1964-05-05', '2013-03-26', 'Wilmington, North Carolina, U.S.'),
  (144, 'Patrick Doyle', 'Patrick Doyle', '1953-04-06', NULL, 'Uddingston, Scotland, UK'),
  (145, 'Taika Waititi', 'Taika David Cohen', '1975-08-16', NULL, 'Wellington, Wellington Region, New Zealand'),
  (146, 'Eric Pearson', 'Eric Pearson', '1984-12-14', NULL, NULL),
  (147, 'Craig Kyle', 'Craig Paul Kyle', '1971-11-03', NULL, 'Houston, Texas, U.S.'),
  (148, 'Mark Mothersbaugh', 'Mark Allen Mothersbaugh', '1950-05-18', NULL, 'Akron, Ohio, U.S.'),
  (149, 'James Gunn', 'James Francis Gunn Jr.', '1966-08-05', NULL, 'St. Louis, Missouri, U.S.'),
  (150, 'Nicole Perlman', 'Nicole Perlman', '1981-12-10', NULL, 'Boulder, Colorado, U.S.'),
  (151, 'Tyler Bates', 'Tyler Bates', '1965-06-05', NULL, 'Los Angeles, California, U.S.'),
  (152, 'Peyton Reed', 'Peyton Tucker Reed', '1964-07-03', NULL, 'Raleigh, North Carolina, U.S.'),
  (153, 'Edgar Wright', 'Edgar Howard Wright', '1974-04-18', NULL, 'Poole, England, UK'),
  (154, 'Joe Cornish', 'Joseph Murray Cornish', '1968-12-20', NULL, 'London, England, UK'),
  (155, 'Adam McKay', 'Adam McKay', '1968-04-17', NULL, 'Denver, Colorado, U.S.'),
  (156, 'Christophe Beck', 'Jean-Christophe Beck', NULL, NULL, 'Montreal, Quebec, Canada'),
  (157, 'Scott Derrickson', 'Scott Derrickson', '1966-07-16', NULL, 'Denver, Colorado, U.S.'),
  (158, 'Ryan Coogler', 'Ryan Kyle Coogler', '1986-05-23', NULL, 'Oakland, California, U.S.'),
  (159, 'Cate Shortland', 'Catherine Shortland', '1968-08-10', NULL, 'Temora, New South Wales, Australia'),
  (160, 'Destin Daniel Cretton', 'Destin Yori Daniel Cretton', '1978-11-23', NULL, 'Haiku, Hawaii, U.S.'),
  (161, 'Chloé Zhao', 'Zhao Ting', '1982-03-31', NULL, 'Beijing, China'),
  (162, 'Sam Raimi', 'Samuel Marshall Raimi', '1959-10-23', NULL, 'Royal Oak, Michigan, U.S.'),
  (163, 'Nia DaCosta', 'Nia DaCosta', '1989-11-08', NULL, 'New York City, New York, U.S.'),
  (164, 'Shawn Levy', 'Shawn Adam Levy', '1968-07-23', NULL, 'Montreal, Quebec, Canada'),
  (165, 'Julius Onah', 'Julius Onah', '1983-02-10', NULL, 'Makurdi, Benue State, Nigeria'),
  (166, 'Jake Schreier', 'Jacob Stacey Schreier', '1981-09-29', NULL, 'Berkeley, California, U.S.'),
  (167, 'Matt Shakman', 'Matt Shakman', '1975-08-08', NULL, 'Ventura, California, U.S.'),
  (168, 'Andrew Barrer', NULL, NULL, NULL, NULL),
  (169, 'Gabriel Ferrari', NULL, NULL, NULL, NULL),
  (170, 'Jon Spaihts', 'Jon Spaihts', '1970-02-04', NULL, 'New York City, New York, U.S.'),
  (171, 'C. Robert Cargill', 'Christopher Robert Cargill', '1975-09-08', NULL, 'San Antonio, Texas, U.S.'),
  (172, 'Joe Robert Cole', 'Joe Robert Cole', '1980-01-01', NULL, 'San Francisco, California, U.S.'),
  (173, 'Dave Callaham', 'David Elias Callaham', '1977-10-24', NULL, 'Fresno, California, U.S.'),
  (174, 'Andrew Lanham', NULL, NULL, NULL, NULL),
  (175, 'Patrick Burleigh', NULL, NULL, NULL, 'New York City, New York, U.S.'),
  (176, 'Ryan Firpo', NULL, NULL, NULL, NULL),
  (177, 'Kaz Firpo', 'Matthew Kazuo Firpo', '1990-08-14', NULL, 'San Francisco, California, U.S.'),
  (178, 'Michael Waldron', 'Michael Waldron', '1987-04-23', NULL, NULL),
  (179, 'Jennifer Kaytin Robinson', 'Jennifer Kaytin Robinson', '1988-04-04', NULL, 'Miami, Florida, U.S.'),
  (180, 'Jeff Loveness', NULL, NULL, NULL, NULL),
  (181, 'Megan McDonnell', NULL, NULL, NULL, NULL),
  (182, 'Elissa Karasik', NULL, NULL, NULL, NULL),
  (183, 'Rhett Reese', NULL, NULL, NULL, NULL),
  (184, 'Paul Wernick', NULL, NULL, NULL, NULL),
  (185, 'Zeb Wells', 'Zeb Wells', '1977-04-28', NULL, 'Littleton, Colorado, U.S.'),
  (186, 'Rob Edwards', 'Rob Edwards', NULL, NULL, 'Detroit, Michigan, U.S.'),
  (187, 'Malcolm Spellman', NULL, NULL, NULL, NULL),
  (188, 'Dalan Musson', NULL, NULL, NULL, NULL),
  (189, 'Peter Glanz', 'Peter Glanz', '1983-01-28', NULL, 'Hartford, Connecticut, U.S.'),
  (190, 'Joanna Calo', NULL, NULL, NULL, 'San Francisco, California, U.S.'),
  (191, 'Josh Friedman', 'Joshua Friedman', '1967-02-14', NULL, NULL),
  (192, 'Jeff Kaplan', NULL, NULL, NULL, NULL),
  (193, 'Ian Springer', NULL, NULL, NULL, NULL),
  (194, 'Ludwig Göransson', 'Ludwig Emil Tomas Göransson', '1984-09-01', NULL, 'Linköping, Östergötland, Sweden'),
  (195, 'Lorne Balfe', 'Lorne Balfe', '1976-02-23', NULL, 'Inverness, Scotland, UK'),
  (196, 'Joel P. West', NULL, NULL, NULL, NULL),
  (197, 'Nami Melumad', 'Naama Melumad', '1988-12-05', NULL, 'Ramat Gan, Tel Aviv District, Israel'),
  (198, 'John Murphy', 'John Murphy', '1965-03-04', NULL, 'Liverpool, England, UK'),
  (199, 'Laura Karpman', 'Laura Anne Karpman', NULL, NULL, 'Los Angeles, California, U.S.'),
  (200, 'Rob Simonsen', NULL, NULL, NULL, 'St. Louis, Missouri, U.S.'),
  (201, 'Son Lux', NULL, NULL, NULL, NULL),
  (202, 'Lauren Shuler Donner', 'Lauren Diane Shuler', '1949-06-23', NULL, 'Cleveland, Ohio, U.S.'),
  (203, 'Stephen Broussard', NULL, NULL, NULL, NULL),
  (204, 'Brad Winderbaum', NULL, NULL, NULL, NULL),
  (205, 'Jonathan Schwartz', NULL, NULL, NULL, NULL),
  (206, 'Nate Moore', NULL, NULL, NULL, NULL),
  (207, 'Rachel O''Connor', NULL, NULL, NULL, NULL);

------------------------------------------------------------------
-- 7. Roles (new footage incl. cameos and multiverse variants; archive footage excluded)
------------------------------------------------------------------
INSERT INTO Role (CharacterID, PersonID, MovieID) VALUES
  (35, 36, 1),
  (36, 37, 1),
  (58, 67, 1),
  (50, 55, 2),
  (59, 68, 2),
  (86, 96, 2),
  (35, 36, 3),
  (36, 37, 3),
  (60, 69, 3),
  (22, 23, 4),
  (35, 36, 4),
  (35, 36, 5),
  (36, 37, 5),
  (62, 72, 5),
  (23, 24, 6),
  (24, 25, 6),
  (23, 24, 7),
  (24, 25, 7),
  (25, 26, 7),
  (50, 55, 7),
  (67, 77, 7),
  (90, 99, 7),
  (35, 36, 8),
  (36, 37, 8),
  (55, 62, 8),
  (56, 63, 8),
  (70, 80, 8),
  (90, 99, 8),
  (22, 23, 9),
  (23, 24, 9),
  (24, 25, 9),
  (25, 26, 9),
  (28, 29, 9),
  (29, 30, 9),
  (30, 31, 9),
  (31, 32, 9),
  (32, 33, 9),
  (35, 36, 9),
  (50, 55, 9),
  (56, 63, 9),
  (61, 71, 9),
  (22, 23, 10),
  (23, 24, 10),
  (24, 25, 10),
  (25, 26, 10),
  (26, 27, 10),
  (27, 28, 10),
  (28, 29, 10),
  (29, 30, 10),
  (30, 31, 10),
  (31, 32, 10),
  (32, 33, 10),
  (33, 34, 10),
  (35, 36, 10),
  (36, 37, 10),
  (37, 38, 10),
  (38, 40, 10),
  (50, 55, 10),
  (56, 63, 10),
  (61, 71, 10),
  (64, 74, 10),
  (90, 99, 10),
  (25, 26, 11),
  (61, 70, 11),
  (22, 23, 12),
  (34, 35, 12),
  (63, 73, 12),
  (23, 24, 13),
  (24, 25, 13),
  (25, 26, 13),
  (64, 74, 13),
  (26, 27, 14),
  (47, 50, 14),
  (65, 75, 14),
  (73, 83, 14),
  (22, 23, 15),
  (34, 35, 15),
  (22, 23, 16),
  (33, 34, 16),
  (71, 81, 16),
  (28, 29, 17),
  (65, 75, 17),
  (28, 29, 18),
  (29, 30, 18),
  (69, 79, 18),
  (24, 25, 19),
  (25, 26, 19),
  (27, 28, 19),
  (37, 38, 19),
  (38, 39, 19),
  (66, 76, 19),
  (27, 28, 20),
  (37, 38, 20),
  (38, 39, 20),
  (41, 44, 20),
  (30, 31, 21),
  (68, 78, 21),
  (25, 26, 22),
  (31, 32, 22),
  (32, 33, 22),
  (72, 82, 22),
  (7, 8, 23),
  (11, 12, 23),
  (36, 37, 23),
  (55, 62, 23),
  (56, 63, 23),
  (74, 84, 23),
  (90, 99, 23),
  (3, 3, 24),
  (6, 7, 24),
  (39, 42, 24),
  (40, 43, 24),
  (50, 55, 24),
  (75, 85, 24),
  (76, 86, 24),
  (87, 97, 24),
  (5, 5, 25),
  (26, 27, 25),
  (30, 31, 25),
  (44, 47, 25),
  (59, 68, 25),
  (77, 87, 25),
  (45, 48, 26),
  (78, 88, 26),
  (11, 12, 27),
  (11, 65, 27),
  (11, 66, 27),
  (20, 21, 27),
  (30, 31, 27),
  (36, 37, 27),
  (55, 62, 27),
  (56, 63, 27),
  (79, 89, 27),
  (90, 99, 27),
  (20, 21, 28),
  (23, 24, 28),
  (30, 31, 28),
  (51, 61, 28),
  (4, 4, 29),
  (13, 14, 29),
  (15, 16, 29),
  (16, 17, 29),
  (17, 18, 29),
  (28, 29, 29),
  (29, 30, 29),
  (33, 34, 29),
  (34, 35, 29),
  (80, 90, 29),
  (31, 32, 30),
  (32, 33, 30),
  (72, 82, 30),
  (81, 91, 30),
  (87, 97, 30),
  (19, 20, 31),
  (22, 23, 31),
  (27, 28, 31),
  (37, 38, 31),
  (38, 41, 31),
  (66, 76, 31),
  (82, 92, 31),
  (13, 14, 32),
  (14, 15, 32),
  (15, 16, 32),
  (16, 17, 32),
  (17, 18, 32),
  (28, 29, 32),
  (29, 30, 32),
  (83, 93, 32),
  (7, 8, 33),
  (26, 27, 33),
  (33, 34, 33),
  (46, 49, 33),
  (47, 51, 33),
  (84, 94, 33),
  (36, 37, 34),
  (48, 52, 34),
  (49, 53, 34),
  (49, 54, 34),
  (53, 2, 34),
  (85, 95, 34),
  (24, 25, 35),
  (25, 26, 35),
  (50, 56, 35),
  (86, 96, 35),
  (25, 26, 36),
  (39, 42, 36),
  (40, 43, 36),
  (41, 44, 36),
  (42, 45, 36),
  (43, 46, 36),
  (76, 86, 36),
  (87, 97, 36),
  (51, 57, 37),
  (52, 58, 37),
  (53, 59, 37),
  (54, 60, 37),
  (88, 98, 37),
  (5, 5, 38),
  (11, 12, 38),
  (39, 42, 38),
  (55, 62, 38),
  (56, 63, 38),
  (57, 64, 38),
  (89, 100, 38),
  (90, 99, 38);

------------------------------------------------------------------
-- 8. Crew (Director, Screenwriter = screenplay/written-by credit, Composer, Producer; no executive producers)
------------------------------------------------------------------
INSERT INTO MovieCrew (MovieID, PersonID, CrewRoleID) VALUES
  (1, 37, 1),
  (1, 101, 4),
  (1, 102, 4),
  (1, 103, 2),
  (1, 104, 2),
  (1, 105, 2),
  (1, 106, 2),
  (1, 107, 3),
  (2, 101, 4),
  (2, 102, 4),
  (2, 108, 1),
  (2, 109, 2),
  (2, 110, 3),
  (2, 111, 4),
  (3, 37, 1),
  (3, 101, 4),
  (3, 112, 2),
  (3, 113, 3),
  (4, 101, 4),
  (4, 114, 1),
  (4, 114, 2),
  (4, 115, 3),
  (5, 101, 4),
  (5, 116, 1),
  (5, 116, 2),
  (5, 117, 2),
  (5, 118, 3),
  (6, 101, 4),
  (6, 114, 1),
  (6, 114, 2),
  (6, 118, 3),
  (6, 119, 3),
  (7, 101, 4),
  (7, 120, 1),
  (7, 121, 1),
  (7, 122, 2),
  (7, 123, 2),
  (7, 124, 3),
  (8, 101, 4),
  (8, 125, 1),
  (8, 125, 2),
  (8, 126, 2),
  (8, 127, 2),
  (8, 128, 2),
  (8, 129, 2),
  (8, 130, 2),
  (8, 131, 3),
  (8, 132, 4),
  (9, 101, 4),
  (9, 115, 3),
  (9, 120, 1),
  (9, 121, 1),
  (9, 122, 2),
  (9, 123, 2),
  (10, 101, 4),
  (10, 115, 3),
  (10, 120, 1),
  (10, 121, 1),
  (10, 122, 2),
  (10, 123, 2),
  (11, 101, 4),
  (11, 115, 3),
  (11, 122, 2),
  (11, 123, 2),
  (11, 133, 1),
  (12, 101, 4),
  (12, 118, 3),
  (12, 122, 2),
  (12, 123, 2),
  (12, 134, 1),
  (12, 135, 2),
  (13, 101, 4),
  (13, 120, 1),
  (13, 121, 1),
  (13, 122, 2),
  (13, 123, 2),
  (13, 124, 3),
  (14, 101, 4),
  (14, 136, 1),
  (14, 136, 2),
  (14, 137, 1),
  (14, 137, 2),
  (14, 138, 2),
  (14, 139, 3),
  (15, 101, 4),
  (15, 140, 1),
  (15, 141, 2),
  (15, 142, 2),
  (15, 143, 2),
  (15, 144, 3),
  (16, 101, 4),
  (16, 135, 2),
  (16, 145, 1),
  (16, 146, 2),
  (16, 147, 2),
  (16, 148, 3),
  (17, 101, 4),
  (17, 149, 1),
  (17, 149, 2),
  (17, 150, 2),
  (17, 151, 3),
  (18, 101, 4),
  (18, 149, 1),
  (18, 149, 2),
  (18, 151, 3),
  (19, 20, 2),
  (19, 101, 4),
  (19, 152, 1),
  (19, 153, 2),
  (19, 154, 2),
  (19, 155, 2),
  (19, 156, 3),
  (20, 20, 2),
  (20, 101, 4),
  (20, 129, 2),
  (20, 130, 2),
  (20, 152, 1),
  (20, 156, 3),
  (20, 168, 2),
  (20, 169, 2),
  (20, 203, 4),
  (21, 101, 4),
  (21, 131, 3),
  (21, 157, 1),
  (21, 157, 2),
  (21, 170, 2),
  (21, 171, 2),
  (22, 101, 4),
  (22, 158, 1),
  (22, 158, 2),
  (22, 172, 2),
  (22, 194, 3),
  (23, 101, 4),
  (23, 125, 1),
  (23, 129, 2),
  (23, 130, 2),
  (23, 131, 3),
  (23, 132, 4),
  (24, 101, 4),
  (24, 146, 2),
  (24, 159, 1),
  (24, 195, 3),
  (25, 101, 4),
  (25, 160, 1),
  (25, 160, 2),
  (25, 173, 2),
  (25, 174, 2),
  (25, 196, 3),
  (25, 205, 4),
  (26, 101, 4),
  (26, 107, 3),
  (26, 161, 1),
  (26, 161, 2),
  (26, 175, 2),
  (26, 176, 2),
  (26, 177, 2),
  (26, 206, 4),
  (27, 101, 4),
  (27, 125, 1),
  (27, 129, 2),
  (27, 130, 2),
  (27, 131, 3),
  (27, 132, 4),
  (28, 101, 4),
  (28, 119, 3),
  (28, 162, 1),
  (28, 178, 2),
  (29, 101, 4),
  (29, 131, 3),
  (29, 145, 1),
  (29, 145, 2),
  (29, 179, 2),
  (29, 197, 3),
  (29, 204, 4),
  (30, 101, 4),
  (30, 158, 1),
  (30, 158, 2),
  (30, 172, 2),
  (30, 194, 3),
  (30, 206, 4),
  (31, 101, 4),
  (31, 152, 1),
  (31, 156, 3),
  (31, 180, 2),
  (31, 203, 4),
  (32, 101, 4),
  (32, 149, 1),
  (32, 149, 2),
  (32, 198, 3),
  (33, 101, 4),
  (33, 163, 1),
  (33, 163, 2),
  (33, 181, 2),
  (33, 182, 2),
  (33, 199, 3),
  (34, 52, 2),
  (34, 52, 4),
  (34, 101, 4),
  (34, 164, 1),
  (34, 164, 2),
  (34, 164, 4),
  (34, 183, 2),
  (34, 184, 2),
  (34, 185, 2),
  (34, 200, 3),
  (34, 202, 4),
  (35, 101, 4),
  (35, 165, 1),
  (35, 165, 2),
  (35, 186, 2),
  (35, 187, 2),
  (35, 188, 2),
  (35, 189, 2),
  (35, 199, 3),
  (35, 206, 4),
  (36, 101, 4),
  (36, 146, 2),
  (36, 166, 1),
  (36, 190, 2),
  (36, 201, 3),
  (37, 101, 4),
  (37, 131, 3),
  (37, 146, 2),
  (37, 167, 1),
  (37, 191, 2),
  (37, 192, 2),
  (37, 193, 2),
  (38, 101, 4),
  (38, 102, 4),
  (38, 129, 2),
  (38, 130, 2),
  (38, 131, 3),
  (38, 132, 4),
  (38, 160, 1),
  (38, 207, 4);

------------------------------------------------------------------
-- 9. Deaths and resurrections (main-continuity characters; Snap victims logged in Infinity War)
------------------------------------------------------------------
DELETE FROM Death;
DELETE FROM Resurrection;
INSERT INTO Death (CharacterID, MovieID, KilledByCharacterID, DeathMannerID, Cause) VALUES
  (58, 1, 35, 2, 'Fell into overloaded arc reactor Pepper triggered on Tony''s order'),
  (60, 3, NULL, 9, 'Self-destructed his suit after defeat by Iron Man and War Machine'),
  (62, 5, 35, 2, 'Killed by Extremis-powered Pepper Potts to save Tony'),
  (9, 6, 18, 2, 'Eliminated by Ultron; remnants later uploaded into Vision'),
  (18, 6, 10, 2, 'Last remaining Ultron drone destroyed by Vision in Sokovia'),
  (7, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (10, 9, 12, 2, 'Mind Stone ripped from his forehead by Thanos in Wakanda'),
  (11, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (13, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (14, 9, 12, 6, 'Thrown off the Vormir cliff by Thanos for the Soul Stone'),
  (15, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (16, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (20, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (21, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (22, 9, 12, 2, 'Strangled by Thanos aboard the Statesman'),
  (23, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (24, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (25, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (27, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (29, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (31, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (37, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (55, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (56, 9, 12, 8, 'Disintegrated in Thanos''s Snap'),
  (1, 10, NULL, 7, 'Died after using the Infinity Stones to snap away Thanos'),
  (3, 10, NULL, 7, 'Sacrificed herself on Vormir so Barton could get Soul Stone'),
  (12, 10, 4, 4, 'Decapitated by Thor on the Garden planet'),
  (63, 12, 4, 2, 'Crushed by his own ship on Svartalfheim after battling Thor'),
  (64, 13, 7, 2, 'Shot by Nick Fury in the Triskelion'),
  (4, 15, 22, 2, 'Struck down by the Destroyer sent by Loki; revived by Mjolnir'),
  (71, 16, NULL, 2, 'Killed when Surtur destroyed Asgard'),
  (16, 17, NULL, 7, 'Shielded the group as the Dark Aster crashed on Xandar'),
  (65, 17, 13, 2, 'Vaporized by Power Stone wielded by Quill, Gamora, Drax, Rocket'),
  (69, 18, 16, 2, 'Rocket''s bomb, planted on his brain by Groot, destroyed him'),
  (72, 22, 21, 2, 'Stabbed by T''Challa; refused healing and died watching sunset'),
  (74, 23, NULL, 1, 'Hit by a misfired gunshot from one of his own drones'),
  (75, 24, 39, 2, 'Killed when Yelena blew up his escape aircraft'),
  (77, 25, NULL, 2, 'Killed by the Dweller-in-Darkness after saving Shang-Chi'),
  (78, 26, NULL, 9, 'Flew into the Sun, guilt-ridden after Tiamut''s emergence was stopped'),
  (90, 27, 79, 2, 'Fatally wounded by the Green Goblin at F.E.A.S.T. building'),
  (23, 28, NULL, 7, 'Brought down Mount Wundagore on herself, destroying the Darkhold'),
  (34, 29, NULL, 5, 'Succumbed to cancer, worsened by wielding Mjolnir, in Thor''s arms'),
  (80, 29, NULL, 3, 'Died from the Necrosword''s curse after wishing Love back to life'),
  (21, 30, NULL, 5, 'Died off-screen of an illness before the film''s events'),
  (66, 31, NULL, 7, 'Turned on Kang at Cassie''s urging and sacrificed his life'),
  (82, 31, 27, 2, 'Thrown into his power core by Hope and Scott'),
  (84, 33, NULL, 1, 'Destroyed by attempting to wield both Quantum Bands'),
  (85, 34, 48, 2, 'Killed when Deadpool and Wolverine destroyed the Time Ripper'),
  (76, 36, 41, 2, 'Killed by Ghost during the fight in the O.X.E. vault'),
  (52, 37, NULL, 7, 'Died pushing Galactus into the portal; revived by Franklin');
INSERT INTO Resurrection (CharacterID, MovieID) VALUES
  (4, 15),
  (7, 10),
  (11, 10),
  (13, 10),
  (15, 10),
  (16, 10),
  (16, 17),
  (20, 10),
  (21, 10),
  (23, 10),
  (24, 10),
  (25, 10),
  (27, 10),
  (29, 10),
  (31, 10),
  (37, 10),
  (52, 37),
  (55, 10),
  (56, 10);

------------------------------------------------------------------
-- 10. Heroes and team membership
------------------------------------------------------------------
INSERT INTO Hero (CharacterID) VALUES
  (23),
  (24),
  (25),
  (26),
  (27),
  (28),
  (29),
  (30),
  (31),
  (32),
  (33),
  (34),
  (35),
  (36),
  (37),
  (38),
  (39),
  (40),
  (41),
  (42),
  (43),
  (44),
  (45),
  (46),
  (47),
  (48),
  (49),
  (51),
  (52),
  (53),
  (54),
  (55),
  (56),
  (57),
  (90);
INSERT INTO CharacterTeam (CharacterID, TeamID) VALUES
  (1, 1),
  (2, 1),
  (2, 5),
  (3, 1),
  (3, 5),
  (3, 9),
  (4, 1),
  (4, 2),
  (5, 1),
  (6, 1),
  (6, 5),
  (7, 5),
  (8, 1),
  (10, 1),
  (11, 1),
  (13, 2),
  (13, 10),
  (14, 2),
  (14, 10),
  (15, 2),
  (16, 2),
  (17, 1),
  (17, 2),
  (19, 1),
  (20, 8),
  (23, 1),
  (24, 1),
  (25, 4),
  (25, 6),
  (26, 1),
  (26, 11),
  (28, 1),
  (28, 2),
  (29, 2),
  (30, 8),
  (32, 7),
  (37, 5),
  (39, 4),
  (39, 9),
  (40, 4),
  (40, 9),
  (41, 4),
  (42, 4),
  (43, 4),
  (45, 12),
  (49, 13),
  (51, 3),
  (52, 3),
  (53, 3),
  (54, 3),
  (61, 6),
  (64, 5),
  (64, 6),
  (68, 8),
  (73, 11),
  (75, 9),
  (76, 9),
  (78, 12);

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
