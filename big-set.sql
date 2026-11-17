-- SELECT THE FIRST 5 ROWS OF EACH TABLE IN THE DATABASE
-- SELECT name 
-- FROM sqlite_master 
-- WHERE type = 'table';

-- SELECT * FROM Phase LIMIT 5;
-- SELECT * FROM Stone LIMIT 5;
-- SELECT * FROM Character LIMIT 5;
-- SELECT * FROM Person LIMIT 5;
-- SELECT * FROM MovieStone LIMIT 5;
-- SELECT * FROM Death LIMIT 5;
-- SELECT * FROM Resurrection LIMIT 5;
-- SELECT * FROM Hero LIMIT 5;
-- SELECT * FROM Role LIMIT 5;
-- SELECT * FROM CrewRole LIMIT 5;
-- SELECT * FROM MovieCrew LIMIT 5;
-- SELECT * FROM Species LIMIT 5;
-- SELECT * FROM Distributor LIMIT 5;
-- SELECT * FROM Team LIMIT 5;
-- SELECT * FROM CharacterTeam LIMIT 5;
-- SELECT * FROM DeathManner LIMIT 5;
-- SELECT * FROM Movie LIMIT 5;

-- What characters belong to which team
-- SELECT * FROM Team
-- INNER JOIN CharacterTeam ON Team.TeamID = CharacterTeam.TeamID
-- INNER JOIN Character ON CharacterTeam.CharacterID = Character.CharacterID
-- WHERE TeamName = 'Guardians of the Galaxy';

-- What characters have more than one team?
-- SELECT CharacterName, Count() as NumTeams FROM Character
-- INNER JOIN CharacterTeam 
-- ON CharacterTeam.CharacterID = Character.CharacterID
-- GROUP BY CharacterName
-- HAVING NumTeams > 1;

-- What teams is Thor a member of?
-- SELECT CharacterName, TeamName FROM Character
-- INNER JOIN CharacterTeam 
-- ON CharacterTeam.CharacterID = Character.CharacterID
-- INNER JOIN Team
-- ON Team.TeamID = CharacterTeam.TeamID
-- WHERE CharacterName = "Thor";

-- What teams is Thor NOT a member of?
SELECT TeamName FROM Team
WHERE TeamID NOT IN (
    SELECT TeamID FROM Character
    INNER JOIN CharacterTeam
    ON CharacterTeam.CharacterID = Character.CharacterID
    WHERE CharacterName IN ("Black Widow", 'Thor')
);

-- select teamname from team
-- where teamid not in (1, 2)

SELECT TeamName FROM Team
WHERE TeamID NOT IN (1, 2);