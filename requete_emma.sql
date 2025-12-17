-- Liste des jockey novices, ceux qui n’ont jamais participé à une course.
SELECT j.jockeyid FROM Jockey j
MINUS
SELECT DISTINCT d.jockeyid 
FROM Duo d
JOIN Inscription i on d.duoid = i.duoid
JOIN participation p on i.participationid = p.participationid
WHERE p.statut = 'Terminé';


-- TOP 3 duos avec le + de victoires en 2024

SELECT *
FROM (
    SELECT i.duoid, COUNT(*) AS nombre_victoire
    FROM Inscription i
    JOIN Participation p on i.participationid = p.participationid
    JOIN Course c ON p.courseid = c.courseid
    WHERE p.resultat = 1 AND c.date_c BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
    GROUP BY i.duoid
    ORDER BY COUNT(*) DESC
)WHERE ROWNUM <= 3;



--La chance du débutant : la plus grosse somme gagnée par un parieur ayant parié une 
--seule fois dans sa vie.

SELECT MAX(premier_paris.gain) AS somme_max
FROM (
    SELECT p.parieurid, p.montant * i.cote AS gain
    FROM Paris p
    JOIN Inscription i on i.participationid = p.participationid
    WHERE p.statut = 'Gagné'
    GROUP BY p.parieurid, p.montant, i.cote
    HAVING COUNT(*) = 1
) premier_paris;


-- Le gain maximal ainsi que le gain moyen total des parieurs. 
SELECT max(gain_pari.gain) as gain_maximal, avg(gain_pari.gain) as gain_moyen 
FROM ( 
  SELECT (p.montant * i.cote) AS gain FROM Paris p 
  JOIN Inscription i ON i.participationid = p.participationid 
  WHERE p.statut = 'Gagné' 
  GROUP BY p.montant, i.cote 
  ) gain_pari;


--  Le poids idéal pour un jockey : la moyenne des poids des jockeys arrivés en 1ere place.
SELECT AVG(j.poids) AS poids_ideal
FROM participation p
JOIN inscription i on i.participationid = p.participationid
JOIN duo d on d.duoid = i.duoid
JOIN jockey j on j.jockeyid = d.jockeyid
WHERE p.resultat = 1 AND j.poids IS NOT NULL;

--Meilleurs investisseurs : TOP 3 des propriétaires possédant la plus grande part sur 
--des chevaux ayant gagné plus d’une fois un grand prix.

WITH 
    cheval_gp AS (
    SELECT DISTINCT d.chevalid
    FROM duo d
    JOIN inscription i on i.duoid = d.duoid
    JOIN participation p ON i.participationid = p.participationid
    JOIN course c ON p.courseid = c.courseid
    WHERE p.resultat = 1 and c.nom LIKE 'Grand Prix%'),
    
parts_total AS (
    SELECT a.proprietaireid, SUM(a.part) AS somme_part
    FROM Appartient a
    JOIN cheval_gp cg ON a.chevalid = cg.chevalid
    GROUP BY a.proprietaireid)
SELECT *
FROM (
    SELECT pt.proprietaireid,pr.nom,pt.somme_part
    FROM parts_total pt
    JOIN Proprietaire pr ON pt.proprietaireid = pr.proprietaireid
    ORDER BY pt.somme_part DESC
)
WHERE ROWNUM <= 3;
