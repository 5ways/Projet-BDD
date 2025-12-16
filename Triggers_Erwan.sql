--Un jockey ne peut pas participer à plusieurs courses situées dans des endroits différents le même jour.
CREATE OR REPLACE TRIGGER not_allowed_to_sign_in
FOR INSERT OR UPDATE ON Inscription
COMPOUND TRIGGER

  TYPE t_row IS RECORD (
    jockeyid Jockey.jockeyid%TYPE,
    date_c   Course.date_c%TYPE,
    lieu     Course.lieu%TYPE,
    duoid    Inscription.duoid%TYPE,
    participationid Inscription.participationid%TYPE
  );

  TYPE t_tab IS TABLE OF t_row INDEX BY PLS_INTEGER;
  g_rows t_tab;
  g_idx  PLS_INTEGER := 0;

  BEFORE EACH ROW IS
  BEGIN
    g_idx := g_idx + 1;

    SELECT d.jockeyid, c.date_c, c.lieu
    INTO g_rows(g_idx).jockeyid,
         g_rows(g_idx).date_c,
         g_rows(g_idx).lieu
    FROM Duo d, Participation p, Course c
    WHERE d.duoid = :NEW.duoid AND 
    p.participationid = :NEW.participationid AND
     c.courseid = p.courseid;

    g_rows(g_idx).duoid := :NEW.duoid;
    g_rows(g_idx).participationid := :NEW.participationid;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
    v_conflicts NUMBER;
  BEGIN
    FOR i IN 1 .. g_idx LOOP
      SELECT COUNT(*)
      INTO v_conflicts
      FROM Inscription i2, Duo d2, Participation p2, Course c2 
      WHERE i2.duoid = d2.duoid
        AND i2.participationid = p2.participationid
        AND c2.courseid = p2.courseid
        AND d2.jockeyid = g_rows(i).jockeyid
        AND c2.date_c = g_rows(i).date_c
        AND c2.lieu != g_rows(i).lieu
        AND i2.statut != 'Refusée'
        AND NOT (
              i2.duoid = g_rows(i).duoid
          AND i2.participationid = g_rows(i).participationid
        );

      IF v_conflicts > 0 THEN
        RAISE_APPLICATION_ERROR(
          -20001,
          'The jockey is already registered for another race on '
          || TO_CHAR(g_rows(i).date_c, 'YYYY-MM-DD')
        );
      END IF;
    END LOOP;
  END AFTER STATEMENT;

END not_allowed_to_sign_in;
/

-- Un cheval doit avoir au minimum 3 ans pour participer à une course.
CREATE OR REPLACE TRIGGER age_restriction
BEFORE INSERT OR UPDATE ON Inscription 
FOR EACH ROW
DECLARE
    date_of_birth date;
    must_be_born date := ADD_MONTHS(SYSDATE, -36); -- must be born at least 3 years (36 months) ago from sign in date
BEGIN
    SELECT c.datenaiss INTO date_of_birth
    FROM Cheval c, Duo d
    WHERE d.duoid = :new.duoid AND -- Finding the duo that want to sign in
    d.chevalid = c.chevalid; -- retrieve horse

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(
            -20002, 
            'Cannot retrieve the duo that want to sign in'
        );
    END IF;

    IF date_of_birth > must_be_born THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Horse is too young to sign in'
        );
    END IF;
END;
/

-- Les individus de moins de 18 ans ne peuvent pas être des parieurs..
CREATE OR REPLACE TRIGGER trg_check_parieur_age
BEFORE INSERT OR UPDATE ON Parieur
FOR EACH ROW
BEGIN
    IF :NEW.datenaiss > ADD_MONTHS(SYSDATE, -216) THEN -- the user must be born 18years (216 months) ago
        RAISE_APPLICATION_ERROR(
          -20004,
          'Le parieur doit être majeur (18 ans minimum).'
        );
    END IF;
END;
/