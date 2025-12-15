--Un jockey ne peut pas participer à plusieurs courses situées dans des endroits différents le même jour.
CREATE TRIGGER not_allowed_to_sign_in
BEFORE INSERT ON Inscription
DECLARE
    new_date date;
    new_place varchar(50);
    number_of_conflict number;
BEGIN
    -- Recover the date and place of race
    SELECT c1.date_c, c1.lieu INTO new_date, new_place
    FROM Participation p1, Course c1
    WHERE p1.courseid = c1.courseid AND
    :new.participationid = p1.participationid;

    -- Searching Races where runners are already signed in at the same date but at a different place 
    SELECT COUNT(*) INTO number_of_conflict
    FROM Inscription i, Participation p, Course c
    WHERE i.participationid = p.participationid AND
    p.courseid = c.courseid AND
    i.duoid = :new.duoid AND -- Same Duo
    c.date_c = new_date AND -- Same Date
    c.lieu != new_place AND -- Different place
    i.statut != 'Refusée'; -- Sign in accepted or waiting for validation

    IF number_of_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001, 
            'The Duo is already registered for another race (' || v_conflict_count || ' conflict(s)) on the date ' || TO_CHAR(v_new_date, 'YYYY-MM-DD') || '.'
        );
    END IF;
END
\;