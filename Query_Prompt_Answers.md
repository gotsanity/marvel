### 1. Select all characters who were resurrected in the same movie they died. (2 rows)

sql

```sql
SELECT c.CharacterName
FROM Character c
JOIN Death d ON c.CharacterID = d.CharacterID
JOIN Resurrection r
    ON d.CharacterID = r.CharacterID
    AND d.MovieID = r.MovieID;
```

### 2. Select all actors who have appeared in exactly one movie. (2 rows)

sql

```sql
SELECT a.ActorName
FROM Actor a
JOIN Role r ON a.ActorID = r.ActorID
GROUP BY a.ActorID, a.ActorName
HAVING COUNT(DISTINCT r.MovieID) = 1;
```

### 3. Find the names and number of times each actor has appeared in a movie with Chris Evans. Order by number of appearances descending. (19 rows)

sql

```sql
SELECT
    a.ActorName,
    COUNT(DISTINCT r.MovieID) AS NumberOfAppearances
FROM Actor a
JOIN Role r ON a.ActorID = r.ActorID
WHERE r.MovieID IN (
    SELECT r2.MovieID
    FROM Role r2
    JOIN Actor a2 ON r2.ActorID = a2.ActorID
    WHERE a2.ActorName = 'Chris Evans'
)
AND a.ActorName <> 'Chris Evans'
GROUP BY a.ActorID, a.ActorName
ORDER BY NumberOfAppearances DESC;
```

### 4. Find the average IMDB rating of every movie an actor was in. (21 rows)

sql

```sql
SELECT
    a.ActorName,
    AVG(m.IMDBRating) AS AverageIMDBRating
FROM Actor a
JOIN Role r ON a.ActorID = r.ActorID
JOIN Movie m ON r.MovieID = m.MovieID
GROUP BY a.ActorID, a.ActorName
ORDER BY a.ActorName;
```

### 5. Find a list of all distinct actors who had roles in phase 1. Ensure each actor only appears once per phase. (13 rows)

sql

```sql
SELECT DISTINCT
    a.ActorName,
    p.PhaseName
FROM Actor a
JOIN Role r ON a.ActorID = r.ActorID
JOIN Movie m ON r.MovieID = m.MovieID
JOIN Phase p ON m.PhaseID = p.PhaseID
WHERE p.PhaseID = 1
ORDER BY a.ActorName;
```

Note: The `DISTINCT` keyword ensures that an actor who appeared in multiple Phase 1 movies is listed only once.