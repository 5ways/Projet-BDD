    CREATE TABLE Jockey(
    jockeyid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    nationalite varchar(20),
    poids number(4,2),
    discipline varchar(20) NOT NULL,
    gain number(8)
);

CREATE TABLE Cheval(
    chevalid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    datenaiss date NOT NULL,
    race varchar(20),
    sexe varchar(10) NOT NULL,
    poids number(5,2),
    discipline varchar(20) NOT NULL,
    gain number(8)
);

CREATE TABLE Entraineur(
    entraineurid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    nationalite varchar(20),
    gain number(8)
);

CREATE TABLE Propietaire(
    proprietaireid number(3) PRIMARY KEY,
    ecurie varchar(50),   
    nom varchar(30),          
    prenom varchar(30),      
    nationalite varchar(20),   
    gain number(8) DEFAULT 0, 
   
    CONSTRAINT check_identite CHECK (ecurie IS NOT NULL OR nom IS NOT NULL)
);

CREATE TABLE Organisateur(
    organisateurid number(2) PRIMARY KEY,
    nom varchar(40) NOT NULL,
    discipline varchar(20)NOT NULL,
    tresorerie number(8) NOT NULL
);

CREATE TABLE Course(
    courseid number(3) PRIMARY KEY,
    nom varchar(60) NOT NULL,
    date_c date NOT NULL,
    discipline varchar(20) NOT NULL,
    sousdiscipline varchar(20) NOT NULL,
    distance number(5) NOT NULL,
    groupe number(1),
    cashprize number(8) NOT NULL,
    lieu varchar(50) NOT NULL,
    organisateurid number(2),
    CONSTRAINT fk_course_organisateur FOREIGN KEY (organisateurid) REFERENCES Organisateur(organisateurid)
);


CREATE TABLE Parieur(
    parieurid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    datenaiss date NOT NULL,
    solde number(10,2) NOT NULL
);


CREATE TABLE Participation(
    participationid number(3) PRIMARY KEY,
    courseid number(2),
    resultat varchar(20), /*ou number 1 */
    statut varchar(20) NOT NULL,
    CONSTRAINT fk_part_course FOREIGN KEY (courseid) REFERENCES Course(courseid)
);


CREATE TABLE Duo(
    duoid number(3) PRIMARY KEY, 
    jockeyid number(2),
    chevalid number(2),
    entraineurid number(2),
    discipline varchar(20),
    CONSTRAINT fk_duo_jockey FOREIGN KEY (jockeyid) REFERENCES Jockey(jockeyid),
    CONSTRAINT fk_duo_cheval FOREIGN KEY (chevalid) REFERENCES Cheval(chevalid),
    CONSTRAINT fk_duo_entraineur FOREIGN KEY (entraineurid) REFERENCES Entraineur(entraineurid),
    CONSTRAINT unq_team UNIQUE (chevalid, jockeyid, entraineurid)
);


CREATE TABLE Inscription(
    participationid number(3),
    duoid number(3), 
    statut varchar(20) NOT NULL,
    PRIMARY KEY (participationid, duoid),
    CONSTRAINT fk_inscrip_participation FOREIGN KEY (participationid) REFERENCES Participation(participationid),
    CONSTRAINT fk_inscrip_duo FOREIGN KEY (duoid) REFERENCES Duo(duoid)
);

CREATE TABLE Appartient(
    proprietaireid number(3),
    chevalid number(2),
    part number(3),
    PRIMARY KEY (proprietaireid, chevalid),
    CONSTRAINT fk_app_proprietaire FOREIGN KEY (proprietaireid) REFERENCES Propietaire(proprietaireid),
    CONSTRAINT fk_app_cheval FOREIGN KEY (chevalid) REFERENCES Cheval(chevalid)
);

CREATE TABLE Paris(
    parisid number(3) PRIMARY KEY,
    parieurid number(2),
    participationid number(3),
    typeparis varchar(20) NOT NULL,
    montant number(4)NOT NULL,
    statut varchar(20) NOT NULL,
    CONSTRAINT fk_paris_participation FOREIGN KEY (participationid) REFERENCES Participation(participationid),
    CONSTRAINT fk_paris_parieur FOREIGN KEY (parieurid) REFERENCES Parieur(parieurid)
);
