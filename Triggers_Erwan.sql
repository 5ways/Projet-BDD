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
          -20201,
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
            -20202, 
            'Cannot retrieve the duo that want to sign in'
        );
    END IF;

    IF date_of_birth > must_be_born THEN
        RAISE_APPLICATION_ERROR(
            -20203,
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
    IF :new.datenaiss > ADD_MONTHS(SYSDATE, -216) THEN -- the user must be born 18years (216 months) ago
        RAISE_APPLICATION_ERROR(
          -20204,
          'Le parieur doit être majeur (18 ans minimum).'
        );
    END IF;
END;
/

-- On peut annuler un pari uniquement si la course n’a pas encore été courue.
CREATE OR REPLACE TRIGGER trg_manage_bet_status
BEFORE INSERT OR UPDATE ON Paris
FOR EACH ROW
DECLARE
  date_course Course.date_c%TYPE;
BEGIN
  -- Retrieve the date of the race the user bet on
  SELECT c.date_c into date_course
  FROM Course c, Paris pa, Participation p
  WHERE :new.parisid = pa.parisid AND
  pa.participationid = p.participationid AND
  p.courseid = c.courseid;

  IF date_course <= SYSDATE THEN
    RAISE_APPLICATION_ERROR(
      -20205,
      'La course est en cours ou a déjà eu lieu'
    );
  END IF;
END;
/

-- On ne peut pas parier sur un duo jockey/cheval et une course si le duo ne participe pas à la course.
CREATE OR REPLACE TRIGGER trg_bet_possible
BEFORE INSERT OR UPDATE ON Paris
FOR EACH ROW
DECLARE
  register_status Participation.statut%TYPE;
BEGIN
  -- Recover the status of the participation that user bet on
  SELECT p.statut INTO register_status
  FROM Participation p
  WHERE p.participationid = :new.participationid;

  IF register_status = 'Annulé' THEN
    RAISE_APPLICATION_ERROR(
      -20206,
      'La participation sur laquelle le parieur souhaite parier à été annulé'
    );
  END IF;
END;
/

-- Un parieur ne peut pas parier un montant supérieur à celui de son solde.
CREATE OR REPLACE TRIGGER trg_bet_not_enough_money
BEFORE INSERT OR UPDATE ON Paris
FOR EACH ROW
DECLARE
  user_balance Parieur.solde%TYPE;
BEGIN
  -- Retrieve User balance
  SELECT p.solde INTO user_balance
  FROM Parieur p
  WHERE p.parieurid = :new.parieurid;

  IF user_balance < :new.montant THEN
    RAISE_APPLICATION_ERROR(
      -20207,
      'Solde du compte du Parieur insuffisant'
    );
  END IF;
END;
/

-- L’organisateur ne peut pas dépenser plus que sa trésorerie.
CREATE OR REPLACE TRIGGER trg_org_not_enough_money
FOR INSERT OR UPDATE ON Course
COMPOUND TRIGGER

  -- 1. Declare a collection to store affected Organizer IDs
  TYPE t_org_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_org_list t_org_ids;

  AFTER EACH ROW IS
  BEGIN
    -- 2. Store the ID of the organizer being modified
    v_org_list(:new.organisateurid) := :new.organisateurid;
    
    -- If updating and changing the organizer, track the old one too
    IF UPDATING AND :old.organisateurid IS NOT NULL THEN
        v_org_list(:old.organisateurid) := :old.organisateurid;
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_sum_cashprize NUMBER;
    v_org_balance   NUMBER;
    v_idx           PLS_INTEGER;
  BEGIN
    -- 3. Loop through all organizers that were affected by the DML
    v_idx := v_org_list.FIRST;
    WHILE v_idx IS NOT NULL LOOP
      
      -- Get total cashprizes for this specific organizer
      SELECT SUM(cashprize) INTO v_sum_cashprize
      FROM Course
      WHERE organisateurid = v_idx;

      -- Get the balance
      SELECT tresorerie INTO v_org_balance
      FROM Organisateur
      WHERE organisateurid = v_idx;

      IF v_sum_cashprize > v_org_balance THEN
        RAISE_APPLICATION_ERROR(-20208, 'Trésorerie insuffisante pour l''organisateur ID: ' || v_idx);
      END IF;

      v_idx := v_org_list.NEXT(v_idx);
    END LOOP;
  END AFTER STATEMENT;

END trg_org_not_enough_money;
/