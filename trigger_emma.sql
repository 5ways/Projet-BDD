--Un cheval peut participer à une course par jour.
CREATE OR REPLACE TRIGGER cheval_max
BEFORE INSERT OR UPDATE ON Inscription
FOR EACH ROW
DECLARE
    date_course DATE;
    nb_particip NUMBER;
    cheval_id NUMBER;
BEGIN
    SELECT chevalid INTO cheval_id
    FROM Duo
    WHERE duoid = :NEW.duoid;

    SELECT c.date_c INTO date_course
    FROM Course c
    JOIN Participation p ON c.courseid = p.courseid
    WHERE p.participationid = :NEW.participationid;

    SELECT COUNT(*)
    INTO nb_particip
    FROM Inscription i
    JOIN Duo d ON i.duoid = d.duoid
    JOIN Participation p on i.participationid = p.participationid
    JOIN Course c ON p.courseid = c.courseid
    WHERE d.chevalid = cheval_id AND c.date_c = date_course;

    IF nb_particip> 0 THEN
        RAISE_APPLICATION_ERROR(-20306, 'Le cheval a une limite de 1 course/jour');
    END IF;
END;
/

-- Une course doit avoir de 4 à 20 participants.
CREATE OR REPLACE TRIGGER nb_participants
AFTER INSERT OR DELETE OR UPDATE
ON Inscription
FOR EACH ROW
DECLARE
    nb_particip NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO nb_particip
      FROM Inscription i
      JOIN Participation p ON i.participationid = p.participationid
     WHERE p.courseid = (
         SELECT courseid
         FROM Participation
         WHERE participationid = NVL(:NEW.participationid, :OLD.participationid));

    IF nb_particip < 4 OR nb_particip > 20 THEN
        RAISE_APPLICATION_ERROR(-20300,'Une course doit avoir entre 4 et 20 participants.');
    END IF;
END;
/


--L’organisateur ne peut organiser que des courses de sa discipline. 
--( Trot, Galop, les deux “Mixte”) ainsi que dans un hippodrome de la discipline
CREATE OR REPLACE TRIGGER discipline_organisateur
BEFORE INSERT OR UPDATE
ON course
FOR EACH ROW
DECLARE
    discipline_org VARCHAR2(20);
BEGIN
    SELECT discipline
      INTO discipline_org
      FROM organisateur
     WHERE organisateurid = :NEW.organisateurid;

    IF NOT (:NEW.discipline = discipline_org OR discipline_org = 'Mixte') THEN
        RAISE_APPLICATION_ERROR(-20301,'Ce n''est pas la discipline de l''organisateur');
    END IF;
END;
/

-- On ne peut pas payer un pari perdant, annulé, déjà payé ou si la course n’a pas eu lieu.
--les différents status sont : en cours, gagné, payé, annulé, perdu

CREATE OR REPLACE TRIGGER paiement_pari
BEFORE UPDATE OF statut
ON paris
FOR EACH ROW
DECLARE
    course_date DATE;
BEGIN
    IF :NEW.statut = 'Payé' THEN
        SELECT c.date_c
        INTO course_date
        FROM course c
        JOIN participation p
            ON p.courseid = c.courseid
        WHERE p.participationid = :NEW.participationid;
        IF course_date > SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20305, 'La course n''a pas encore eu lieu.');
        END IF;
        IF :OLD.statut = 'Payé' THEN
            RAISE_APPLICATION_ERROR(-20302, 'Ce pari est déjà payé.');
        END IF;
        IF :OLD.statut = 'Annulé' THEN
            RAISE_APPLICATION_ERROR(-20303, 'Ce pari est annulé.');
        END IF;
        IF :OLD.statut = 'Perdu' THEN
            RAISE_APPLICATION_ERROR(-20304, 'Un pari perdu ne peut pas être payé.');
        END IF;
    END IF;
END;
/



