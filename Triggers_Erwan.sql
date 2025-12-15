--Un jockey ne peut pas participer à plusieurs courses situées dans des endroits différents le même jour.
CREATE TRIGGER not_allowed_to_sign_in
BEFORE INSERT OR UPDATE ON Inscription
DECLARE
    jockey_wants_to Jockey.jockeyid%TYPE;
    new_date Course.date%TYPE;
    new_place Course.lieu%TYPE;
    number_of_conflict number;
BEGIN
    -- Recover the Jockey that wants to sign in
    SELECT d1.jockeyid INTO jockey_wants_to
    FROM Duo d1
    WHERE d1.duoid = :new.duoid;

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Cannot retrieve the jockey that wants to sign in'
        );
    END IF;

    -- Recover the date and place of race
    SELECT c1.date_c, c1.lieu INTO new_date, new_place
    FROM Participation p1, Course c1
    WHERE p1.courseid = c1.courseid AND
    :new.participationid = p1.participationid;

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Cannot retrieve date and/or place of race'
        );
    END if;

    -- Searching Races where runners are already signed in at the same date but at a different place 
    SELECT COUNT(*) INTO number_of_conflict
    FROM Inscription i, Participation p, Course c, Duo d
    WHERE i.participationid = p.participationid AND
    p.courseid = c.courseid AND
    i.duoid = d.duoid AND
    d.jockeyid = jockey_wants_to -- Same Jockey
    c.date_c = new_date AND -- Same Date
    c.lieu != new_place AND -- Different place
    i.statut != 'Refusée'; -- Sign in accepted or waiting for validation

    IF number_of_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001, 
            'The Jockey is already registered for another race (' || v_conflict_count || ' conflict(s)) on the date ' || TO_CHAR(v_new_date, 'YYYY-MM-DD') || '.'
        );
    END IF;
END;
/

-- Un cheval doit avoir au minimum 3 ans pour participer à une course.
CREATE TRIGGER age_restriction
BEFORE INSERT OR UPDATE ON Inscription
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