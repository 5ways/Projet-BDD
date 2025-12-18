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

-- Fiche de Propriété
CREATE OR REPLACE VIEW fiche_proprietes AS
SELECT p.prenom as Prenom_Propriétaire, p.nom as Nom_Propriétaire, c.nom as Nom_Cheval, a.part part_de_propriété
FROM Proprietaire p, Cheval c, Appartient a
WHERE a.proprietaireid = p.proprietaireid AND
a.chevalid = c.chevalid
ORDER BY Nom_Cheval;

-- Statistiques de Paris par Parieur
CREATE OR REPLACE VIEW statistiques_parieurs AS
SELECT p.nom as nom_parieur, p.prenom as prenom_parieur, p.solde as solde_parieur, SUM(b.montant) as mise_total, COUNT(b.statut) as paris_gagné
FROM Parieur p, Paris b
WHERE p.parieurid = b.parieurid AND
b.statut = 'Gagné'
GROUP BY nom_parieur, prenom_parieur, solde_parieur;
