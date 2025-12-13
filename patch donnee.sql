-- Pour la requête "Critérium 4 ans" : Victoire de Liza Josselyn (Trot, 4 ans)
INSERT INTO Inscription (participationid, duoid, statut, frais_inscrip) VALUES (196, 77, 'Validé', 2000);

-- Pour la requête "Top victoires 2024" : Victoire de Cualificar
INSERT INTO Inscription (participationid, duoid, statut, frais_inscrip) VALUES (56, 13, 'Validé', 5000);

-- Pour la requête "Légende / 3 Grands Prix" : 3ème victoire pour Idao de Tillard
INSERT INTO Inscription (participationid, duoid, statut, frais_inscrip) VALUES (11, 51, 'Validé', 3000);

-- Pour la requête "Meilleurs Investisseurs" : 2èmes victoires de prestige
INSERT INTO Inscription (participationid, duoid, statut, frais_inscrip) VALUES (166, 15, 'Validé', 8000); -- Croix du Nord
INSERT INTO Inscription (participationid, duoid, statut, frais_inscrip) VALUES (171, 17, 'Validé', 8000); -- Minnie Hauk

-- Pour la requête "Chance du débutant" : Parieur unique
INSERT INTO Parieur (parieurid, nom, prenom, datenaiss, solde) VALUES (31, 'Luke', 'Lucky', '1990-01-01', 0);
INSERT INTO Paris (parisid, parieurid, participationid, typeparis, montant, statut) VALUES (74, 31, 1, 'Simple Gagnant', 500, 'Gagné');