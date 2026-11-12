-- ********************************************************************************
-- Select all characters who were resurrected in the same movie they died. (3 rows)
-- ********************************************************************************
-- SELECT 
--     Character.CharacterID,
--     Character.CharacterName,
--     Resurrection.MovieID AS ResurrectedIn,
--     Death.MovieID AS DiedIn
-- FROM Character
-- INNER JOIN Resurrection ON Character.CharacterID = Resurrection.CharacterID
-- INNER JOIN Death ON Character.CharacterID = Death.CharacterID
-- WHERE Resurrection.MovieID = Death.MovieID;


-- ********************************************************************************
-- Select all actors who have appeared in exactly one movie. (3 rows)
-- ********************************************************************************
-- SELECT 
--     Actor.ActorID, 
--     Actor.ActorName, 
--     Count(Actor.ActorID) as NumAppearances
-- FROM Actor
-- INNER JOIN Role ON Actor.ActorID = Role.ActorID
-- GROUP BY Actor.ActorID, Actor.ActorName
-- HAVING NumAppearances = 1;


-- ********************************************************************************
-- Find the average IMDB rating of every movie an actor was in. (21 rows)
-- ********************************************************************************
SELECT 
    Movie.Title,
    ActorName,
    Avg(IMDBRating) as AvgIMDBRating
FROM Movie
INNER JOIN Role ON Role.MovieID = Movie.MovieID
INNER JOIN Actor ON Actor.ActorID = Role.ActorID
GROUP BY Title, ActorName;


-- ********************************************************************************
-- Find a list of all distinct actors who had roles in phase 1. Ensure each actor
-- only appears once per phase. (13 rows)
-- ********************************************************************************



-- ********************************************************************************
-- Find the names and number of times each actor has appeared in a movie with 
-- Chris Evans. Order by Number of Appearances descending.
-- HINT: this will require a subquery. First find all movies Evans was in,
-- then use it to filter a second query. (19 Rows, Samuel L. Jackson has 7 appearances)
-- ********************************************************************************
