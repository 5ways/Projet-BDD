-- Liste des chevaux maiden, ceux qui n’ont jamais remporté une course.
SELECT c.id
FROM Cheval c
WHERE c.chevalid NOT IN (
    SELECT f.chevalid -- Select the ID of horses that have won
    FROM Participation p, Inscription i, Duo d, Forme f
    WHERE i.duoid = d.duoid AND 
    d.formeid = f.formeid AND 
    p.participationid = i.participationid AND 
    p.resultat = '1' -- Filter for winning participations
);
-- Liste des chevaux de plus de 5 ans n’ayant pas gagné durant les 12 derniers mois.
SELECT c.id
FROM Cheval c
WHERE c.DateNaiss <= ADD_MONTHS(SYSDATE, -60) -- Horses 5 years (60 months) or older
AND c.chevalid NOT IN (
    SELECT f.chevalid -- Select the ID of horses that HAVE won recently
    FROM Participation p, Inscription i, Duo d, Forme f, Course co
    WHERE p.courseid = co.courseid AND 
    i.duoid = d.duoid AND
    d.formeid = f.formeid AND 
    p.participationid = i.participationid AND 
    p.resultat = '1' AND 
    co.date >= ADD_MONTHS(SYSDATE, -12) -- Race was in the last 12 months
);

-- Le TOP 5 des chevaux les plus populaires, ceux qui ont suscité le plus grand nombre de paris.
-- Les chevaux n'ayant pas de paris assignés ne seront pas inclus dans le résultat de la requête
SELECT c.id, count(m.parisid) as number_of_bet
FROM Cheval c, Mise m, Inscription i, Forme f, Duo d, Participation p
WHERE c.chevalid = f.chevalid AND
f.duoid = d.duoid AND
d.duoid = i.duoid AND
i.participationid = p.participationid AND
p.participationid = m.participationid
GROUP BY c.id
ORDER BY number_of_bet DESC;
