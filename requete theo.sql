-- Liste des chevaux pesant plus de 450 kg et ayant 2 victoires cette année.
SELECT c.nom 
FROM Cheval c, Duo d, Inscription i, Participation p, Course co
WHERE c.chevalid = d.chevalid 
    AND d.duoid = i.duoid 
    AND i.participationid = p.participationid 
    AND p.courseid = co.courseid 
    AND c.poids >= 450 
    AND co.date_c LIKE '2025%' 
    AND p.resultat=1 
GROUP BY c.nom 
HAVING count(c.nom)>=2;

--Les jockeys ayant gagné dans tous les hippodromes sauf un. 
SELECT j.nom, COUNT(DISTINCT c.lieu) AS nb_win_lieu
FROM Jockey j, Duo d, Inscription i, Participation p, Course c
WHERE j.jockeyid = d.jockeyid
    AND d.duoid = i.duoid 
    AND i.participationid = p.participationid  
    AND p.courseid = c.courseid 
    AND p.resultat =1
GROUP BY j.nom
HAVING COUNT(DISTINCT c.lieu) = (SELECT COUNT(DISTINCT c.lieu) AS nb_hippo
                                 FROM Course c) - 1;

--  Le plus gros parieur de la journée : le parieur ayant gagné le plus de paris durant la journée choisie.
SELECT COUNT(p.parieurid) AS nb_paris, p.nom, p.prenom
FROM Parieur p, Paris b, Participation pa, Course c
WHERE p.parieurid = b.parieurid 
    AND b.participationid = pa.participationid 
    AND pa.courseid = c.courseid 
    AND b.statut = 'Gagné' 
    AND c.date_c LIKE '2025-10-05%'
GROUP BY p.parieurid, p.nom, p.prenom
ORDER BY nb_paris DESC
LIMIT 1;

-- OU
-- Permet de ne pas avoir de problème sur les égalités 
SELECT COUNT(p.parieurid) as nb_paris, p.nom, p.prenom
FROM Parieur p, Paris b, Participation pa, Course c
WHERE p.parieurid = b.parieurid
  AND b.participationid = pa.participationid
  AND pa.courseid = c.courseid
  AND b.statut = 'Gagné'
  AND c.date_c LIKE '2025-10-05%'
GROUP BY p.parieurid, p.nom, p.prenom
HAVING nb_paris = (SELECT COUNT(p.parieurid) AS nb_paris
                   FROM Parieur p, Paris b, Participation pa, Course c 
                   WHERE p.parieurid = b.parieurid
                        AND b.participationid = pa.participationid
                        AND pa.courseid = c.courseid
                        AND b.statut = 'Gagné'
                   AND c.date_c LIKE '2025-10-05%'
                   GROUP BY p.parieurid 
                   ORDER BY nb_paris DESC
                   LIMIT 1);


-- Meilleure nationalité de Jockey : TOP 3 des pays ayant formé le plus de jockey avec une victoire en grand prix.
SELECT COUNT(DISTINCT j.jockeyid) as nb_win, j.nationalite
FROM Jockey j, Duo d, Inscription i, Participation p, Course c
WHERE j.jockeyid = d.jockeyid
    AND d.duoid = i.duoid
    AND i.participationid = p.participationid
    AND p.courseid = c.courseid
    AND p.resultat =1
    AND c.nom LIKE 'Grand Prix%'
GROUP BY  j.nationalite
ORDER BY nb_win DESC
LIMIT 3;

-- L’entraîneur le plus productif : celui qui entraîne le plus de duos.
SELECT e.nom, e.prenom, COUNT(*) AS nb_occu
FROM Entraineur e, Duo d
WHERE e.entraineurid = d.entraineurid
GROUP BY e.nom, e.prenom
ORDER BY nb_occu DESC
LIMIT 1;

-- Le lieu emblématique du monde hippique: le lieu accueillant le plus de Grand Prix.
SELECT lieu
FROM Course
WHERE nom LIKE 'Grand Prix%'
GROUP BY lieu
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Liste des chevaux éligibles au Critérium des 4 ans; le Critérium est une course de trot attelé réservée aux chevaux de 4 ans ayant gagné au moins 32 000€.
SELECT nom
FROM Cheval
WHERE gain >= 32000 
    AND YEAR(datenaiss) = 2021 
    AND discipline = 'Trot';