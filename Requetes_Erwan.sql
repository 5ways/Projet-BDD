-- Liste des chevaux maiden, ceux qui n’ont jamais remporté une course.
SELECT c.id
FROM Cheval c
WHERE c.chevalid NOT IN (
    SELECT d.chevalid -- Select the ID of horses that have won
    FROM Participation p
    JOIN Inscription i ON p.participationid = i.participationid
    JOIN Duo d ON i.duoid = d.duoid
    WHERE p.resultat = '1' -- Filter for winning participations
);
-- Liste des chevaux de plus de 5 ans n’ayant pas gagné durant les 12 derniers mois.
SELECT c.id
FROM Cheval c
WHERE c.DateNaiss <= ADD_MONTHS(SYSDATE, -60) -- Horses 5 years (60 months) or older
AND c.chevalid NOT IN (
    SELECT d.chevalid -- Select the ID of horses that HAVE won recently
    FROM Participation p
    JOIN Inscription i ON p.participationid = i.participationid
    JOIN Duo d ON i.duoid = d.duoid
    JOIN Course co ON p.courseid = co.courseid -- Assuming this link exists
    WHERE p.resultat = '1'
    AND co.date >= ADD_MONTHS(SYSDATE, -12) -- Race was in the last 12 months
);

-- Le TOP 5 des chevaux les plus populaires, ceux qui ont suscité le plus grand nombre de paris.

