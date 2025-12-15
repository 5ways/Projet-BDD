-- Un cheval doit avoir ses parts de propriété qui atteignent exactement 100%.
CREATE OR REPLACE TRIGGER part_total
AFTER INSERT OR UPDATE ON Appartient FOR EACH ROW
DECLARE
    v_somme number(3);
BEGIN
    SELECT SUM(a.part) INTO v_somme
    FROM Appartient a
    WHERE :NEW.chevalid = chevalid;

    IF v_somme > 100 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Erreur : Le total des parts dépasse 100%');
    END IF;
END;
/

-- Vérifie si une sous discipline est bien liée à la bonne discipline
CREATE OR REPLACE TRIGGER sous_disc_coherente 
BEFORE INSERT OR UPDATE ON Course FOR EACH ROW
BEGIN
    IF :NEW.discipline = 'Trot' AND :NEW.sousdiscipline NOT IN ('Attelé', 'Monté') THEN
        RAISE_APPLICATION_ERROR(-20102, 'Erreur : sous discipline non cohérente.');
    ELSIF :NEW.discipline = 'Galop' AND :NEW.sousdiscipline NOT IN ('Plat', 'Obstacle') THEN
        RAISE_APPLICATION_ERROR(-20102, 'Erreur : sous discipline non cohérente.');
    END IF;
END;
/

-- Vérifie si l'organisateur peut payer le cashprize
CREATE OR REPLACE TRIGGER cashprize_payable
BEFORE INSERT OR UPDATE ON Course FOR EACH ROW
DECLARE
    v_treso number (8);
BEGIN
    SELECT o.tresorerie INTO v_treso
    FROM Organisateur o
    WHERE :NEW.organisateurid = o.organisateurid;

    IF v_treso + NVL(:OLD.cashprize, 0) < :NEW.cashprize THEN
        RAISE_APPLICATION_ERROR(-20103, 'Erreur : Le cashprize est supérieur à la trésorerie');
    END IF;

    UPDATE Organisateur SET tresorerie = tresorerie - :NEW.cashprize + NVL(:OLD.cashprize, 0) WHERE :NEW.organisateurid = Organisateur.organisateurid;
END;
/

-- Répartion du cashprize 
CREATE OR REPLACE TRIGGER repartition_gain
AFTER INSERT OR UPDATE ON Participation FOR EACH ROW
WHEN (NEW.resultat BETWEEN 1 AND 5)
DECLARE
    v_cashprize Course.cashprize%TYPE;
    v_gain Cheval.gain%TYPE;
    v_duo Duo.duoid%TYPE;
    v_jock Duo.jockeyid%TYPE;
    v_chev Duo.chevalid%TYPE;
    v_train Duo.entraineurid%TYPE;
    v_part_jock Jockey.gain%TYPE;
    v_part_train Entraineur.gain%TYPE;
    v_part_proprio Proprietaire.gain%TYPE;

BEGIN
    SELECT c.cashprize INTO v_cashprize
    FROM Course c
    WHERE c.courseid = :NEW.courseid;

    IF :NEW.resultat = 1 THEN
        v_gain := v_cashprize * 0.5;
    ELSIF :NEW.resultat = 2 THEN
        v_gain := v_cashprize * 0.2;
    ELSIF :NEW.resultat = 3 THEN
        v_gain := v_cashprize * 0.15; 
    ELSIF :NEW.resultat = 4 THEN
        v_gain := v_cashprize * 0.1;
    ELSIF :NEW.resultat = 5 THEN
        v_gain := v_cashprize * 0.05;
    END IF;

    SELECT d.jockeyid, d.chevalid, d.entraineurid INTO v_jock,  v_chev, v_train
    FROM Duo d, Inscription i
    WHERE d.duoid = i.duoid AND i.participationid = :NEW.participationid;

    v_part_jock := v_gain * 0.1;
    v_part_train := v_gain * 0.15;
    v_part_proprio := v_gain * 0.75;

    FOR r_proprio IN (SELECT a.proprietaireid, a.part FROM Appartient a WHERE a.chevalid = v_chev) 
    LOOP
        UPDATE Proprietaire SET gain = NVL(gain, 0) + v_part_proprio * (r_proprio.part/100) WHERE proprietaireid = r_proprio.proprietaireid;
    END LOOP;

    UPDATE Jockey SET gain = NVL(gain, 0) + v_part_jock  WHERE jockeyid= v_jock; 
    UPDATE Entraineur SET gain = NVL(gain, 0) + v_part_train WHERE entraineurid = v_train;
    UPDATE Cheval SET gain = NVL(gain, 0) + v_gain WHERE chevalid= v_chev;

END;
/

-- Vérifie que le cheval est en règle pour l'inscription évite problème de répartition
CREATE OR REPLACE TRIGGER refus_inscrip
BEFORE INSERT OR UPDATE ON Inscription FOR EACH ROW
DECLARE 
    v_chev Duo.chevalid%TYPE;
    v_part Appartient.part%TYPE;

BEGIN 
    SELECT d.chevalid INTO v_chev
    FROM Duo d
    WHERE :NEW.duoid = d.duoid;

    SELECT NVL(SUM(a.part), 0) INTO v_part
    FROM Appartient a 
    WHERE v_chev = a.chevalid;

    IF v_part != 100 THEN
        RAISE_APPLICATION_ERROR(-20104, 'Erreur : Le cheval n''a pas ses parts égalent à 100%');
    END IF;
END;
/

-- Un duo jockey/cheval doit avoir la même discipline.
CREATE OR REPLACE TRIGGER discipline_duo 
BEFORE INSERT OR UPDATE ON Duo FOR EACH ROW
DECLARE 
    v_dis_chev Cheval.discipline%TYPE;
    v_dis_jock Jockey.discipline%TYPE;

BEGIN 
    SELECT c.discipline INTO v_dis_chev
    FROM Cheval c
    WHERE :NEW.chevalid = c.chevalid;

    SELECT j.discipline INTO v_dis_jock
    FROM Jockey j
    WHERE :NEW.jockeyid = j.jockeyid;

    IF v_dis_jock != v_dis_chev OR v_dis_jock != :NEW.discipline OR v_dis_chev != :NEW.discipline THEN
        RAISE_APPLICATION_ERROR(-20105, 'Erreur : Problème de cohérence sur les disciplines');
    END IF;
END;
/

-- Un duo jockey/cheval ne peut participer qu’aux courses de sa discipline.
CREATE OR REPLACE TRIGGER discipline_course 
BEFORE INSERT OR UPDATE ON Inscription FOR EACH ROW
DECLARE 
    v_dis_duo Duo.discipline%TYPE;
    v_dis_course Course.discipline%Type;

BEGIN 
    SELECT d.discipline INTO v_dis_duo
    FROM Duo d
    WHERE d.duoid = :NEW.duoid;

    SELECT c.discipline INTO v_dis_course
    FROM Course c, Participation p
    WHERE :New.participationid = p.participationid AND p.courseid = c.courseid;

    IF v_dis_duo != v_dis_course THEN
        RAISE_APPLICATION_ERROR(-20106, 'Erreur : Problème de cohérence sur les disciplines');
    END IF;
END;
/

-- Un duo jockey/cheval peut participer une seule fois à la même course.
CREATE OR REPLACE TRIGGER une_fois_par_course
BEFORE INSERT OR UPDATE ON Inscription FOR EACH ROW
DECLARE 
    v_course Course.courseid%TYPE;
    v_jock Duo.jockeyid%TYPE;
    v_chev Duo.chevalid%TYPE;
    present number(1);

BEGIN 
    SELECT p.courseid INTO v_course
    FROM Participation p
    WHERE :NEW.participationid = p.participationid;

    SELECT d.jockeyid, chevalid INTO v_jock, v_chev
    FROM Duo d
    WHERE :NEW.duoid = d.duoid;

    SELECT COUNT(*) INTO present
    FROM Participation p, Duo d
    WHERE :NEW.participationid = p.participationid 
    AND :NEW.duoid = d.duoid
    AND p.courseid = v_course 
    AND (d.jockeyid = v_jock OR d.chevalid = v_chev);

    IF present != 0 THEN
        RAISE_APPLICATION_ERROR(-20107, 'Erreur : Duo déjà inscrit à cette course');
    END IF;
END;
/

-- Gestion de toutes les opérations sur les paris 
CREATE OR REPLACE TRIGGER gestion_paris
BEFORE INSERT OR UPDATE OR DELETE ON Paris FOR EACH ROW
DECLARE
    v_cote Inscription.cote%TYPE;
    v_org Organisateur.organisateurid%TYPE;
    v_solde_actuel Parieur.solde%TYPE;
    v_partid Participation.participationid%TYPE;

BEGIN
    v_partid := NVL(:NEW.participationid, :OLD.participationid);

    SELECT i.cote INTO v_cote
    FROM Inscription i 
    WHERE v_partid = i.participationid;

    SELECT o.organisateurid INTO v_org
    FROM Organisateur o, Course c, Participation p
    WHERE o.nom = 'Pari Mutuel Urbain' AND o.organisateurid = c.organisateurid AND c.courseid = p.courseid AND p.participationid = v_partid;

    IF INSERTING THEN
        SELECT p.solde INTO v_solde_actuel
        FROM Parieur
        WHERE :NEW.parieurid = p.parieurid;

        IF (v_solde_actuel - :NEW.montant) < 0 THEN
            RAISE_APPLICATION_ERROR(-20108, 'Erreur : solde insuffisant');
        END IF;

        UPDATE Parieur SET solde = NVL(solde, 0) - :NEW.montant WHERE :NEW.parieurid = Parieur.parieurid;
        UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) + :NEW.montant WHERE v_org = organisateurid;

    ELSIF UPDATING THEN
        IF :NEW.statut = 'Gagné' AND :OLD.statut != 'Payé' THEN
            IF :NEW.typeparis = 'Simple Gagnant' THEN
                UPDATE Parieur SET solde = NVL(solde, 0) + v_cote * :NEW.montant WHERE :NEW.parieurid = Parieur.parieurid;
                UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) - v_cote * :NEW.montant WHERE v_org = organisateurid; 
            ELSIF :NEW.typeparis = 'Simple Placé' THEN
                IF v_cote < 10 THEN
                    UPDATE Parieur SET solde = NVL(solde, 0) + GREATEST((v_cote * :NEW.montant) / 3, 1.1 * :NEW.montant) WHERE :NEW.parieurid = Parieur.parieurid;
                    UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) - GREATEST((v_cote * :NEW.montant) / 3, 1.1 * :NEW.montant) WHERE v_org = organisateurid; 
                ELSIF v_cote BETWEEN 10 AND 20 THEN
                    UPDATE Parieur SET solde = NVL(solde, 0) + (v_cote * :NEW.montant) / 3.5 WHERE :NEW.parieurid = Parieur.parieurid;
                    UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) - (v_cote * :NEW.montant) / 3.5 WHERE v_org = organisateurid;
                ELSIF v_cote > 20 THEN
                    UPDATE Parieur SET solde = NVL(solde, 0) + (v_cote * :NEW.montant) / 6 WHERE :NEW.parieurid = Parieur.parieurid;
                    UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) - (v_cote * :NEW.montant) / 6 WHERE v_org = organisateurid;
                END IF;
            END IF;
            :NEW.statut := 'Payé';
        END IF;

    ELSIF DELETING THEN
        UPDATE Parieur SET solde = NVL(solde, 0) + :OLD.montant WHERE :OLD.parieurid = Parieur.parieurid;
        UPDATE Organisateur SET tresorerie = NVL(tresorerie, 0) - :OLD.montant WHERE v_org = organisateurid;

    END IF;
END;
/