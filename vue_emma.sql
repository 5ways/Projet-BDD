--Le classement des jockey par nombre de participations
CREATE VIEW jockey_participation AS
SELECT j.jockeyid, j.nom, j.prenom, count(*) AS nombre_participations
FROM jockey j
JOIN duo d on d.jockeyid = j.jockeyid
JOIN inscription i ON d.duoid = i.duoid
JOIN Participation p on i.participationid = p.participationid
GROUP BY j.jockeyid, j.nom, j.prenom
ORDER BY COUNT(*) DESC;


--La liste des chevaux expérimentés : cheval de + de 4 ans avec au moins 3 victoires à son actif
CREATE VIEW cheval_experimente AS
SELECT chevalid FROM Cheval
WHERE TRUNC((SYSDATE - datenaiss) / 365) > 4
INTERSECT
SELECT d.chevalid FROM duo d
JOIN Inscription i on d.duoid = i.duoid
JOIN Participation p on i.participationid = p.participationid
WHERE p.resultat = 1
GROUP BY d.chevalid
HAVING COUNT(*) >= 3;



