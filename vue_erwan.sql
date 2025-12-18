-- Programme Officiel des Courses
CREATE OR REPLACE VIEW programmation_courses AS
SELECT c.nom as Titre_Course, c.date_c as Date_Course, c.lieu as Lieu_Course, ch.nom as Cheval, j.nom as Jockey_Nom, j.prenom as Jockey_Prénom, i.cote as Côte_Duo
FROM Course c, Participation p, Inscription i, Duo d, Cheval ch, Jockey j
WHERE c.courseid = p.courseid AND
p.participationid = i.participationid AND
i.duoid = d.duoid AND
d.chevalid = ch.chevalid AND
d.jockeyid = j.jockeyid AND
i.statut = 'Validé'
ORDER BY c.date_c;