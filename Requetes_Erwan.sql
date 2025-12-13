-- Liste des chevaux maiden, ceux qui n’ont jamais remporté une course.
SELECT *
FROM Cheval c
WHERE c.chevalid NOT IN (
    SELECT d.chevalid -- Select the ID of horses that have won
    FROM Participation p, Inscription i, Duo d
    WHERE i.duoid = d.duoid AND
    p.participationid = i.participationid AND 
    p.resultat = '1' -- Filter for winning participations
);
-- Liste des chevaux de plus de 5 ans n’ayant pas gagné durant les 12 derniers mois.
SELECT *
FROM Cheval c
WHERE c.DateNaiss <= ADD_MONTHS(SYSDATE, -60) -- Horses 5 years (60 months) or older
AND c.chevalid NOT IN (
    SELECT d.chevalid -- Select the ID of horses that HAVE won recently
    FROM Participation p, Inscription i, Duo d, Course co
    WHERE p.courseid = co.courseid AND 
    i.duoid = d.duoid AND
    p.participationid = i.participationid AND 
    p.resultat = '1' AND 
    co.date >= ADD_MONTHS(SYSDATE, -12) -- Race was in the last 12 months
);

-- Le TOP 5 des chevaux les plus populaires, ceux qui ont suscité le plus grand nombre de paris.
-- Les chevaux n'ayant pas de paris assignés ne seront pas inclus dans le résultat de la requête
SELECT c.nom, count(m.parisid) as number_of_bet
FROM Cheval c, Mise m, Inscription i, Duo d, Participation p
WHERE c.chevalid = d.chevalid AND
d.duoid = i.duoid AND
i.participationid = p.participationid AND
p.participationid = m.participationid
GROUP BY c.nom
ORDER BY number_of_bet DESC
LIMIT 5;

--Le TOP 5 des duos jockeys/chevaux ayant le plus de 1ère places, qui courent toujours en 2025.
SELECT d.jockeyid, d.chevalid, count(p.résultat) as number_of_wins
FROM Duo d, Inscription i, Participation p
WHERE d.duoid = i.duoid AND
i.participationid = p.participationid AND
p.resultat = '1' AND
i.duoid in ( -- verify if the duo is actually in the list of 2025 runners
    SELECT *
    FROM Course co, Participation p2, Inscription i2
    WHERE i2.participationid = p2.participationid AND
    p2.courseid = co.courseid AND
    co.date >= TO_DATE('2025-01-01')
)
GROUP BY f.jockeyid, f.chevalid
ORDER BY number_of_wins DESC
LIMIT 5;