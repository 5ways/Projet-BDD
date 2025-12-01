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
    age number(2), /*inutile*/
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
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    gain number(8)
);

CREATE TABLE Organisateur(
    organisateurid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    discipline varchar(20)NOT NULL,
    tresorerie number(8) NOT NULL
);

CREATE TABLE Course(
    courseid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    date_c date NOT NULL,
    discipline varchar(20) NOT NULL,
    sousdiscipline varchar(20) NOT NULL,
    distance number(5) NOT NULL,
    groupe number(1),
    cashprize number(8) NOT NULL,
    lieu varchar(50) NOT NULL,
    organisateurid number(2),
    CONSTRAINT organisateurid FOREIGN KEY (organisateurid) REFERENCES Organisateur(organisateurid)
);

CREATE TABLE SocieteDeParis(
    sdpid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    tresorerie number(8) NOT NULL
);

CREATE TABLE Parieur(
    parieurid number(2) PRIMARY KEY,
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    datenaiss date NOT NULL,
    solde number(8) NOT NULL
);

CREATE TABLE Paris(
    parisid number(2) PRIMARY KEY,
    typeparis varchar(20) NOT NULL,
    montant number(4)NOT NULL,
    statut varchar(20) NOT NULL
);

CREATE TABLE Participation(
    participationid number(3) PRIMARY KEY,
    courseid number(2),
    resultat varchar(20), /*sous quelle forme ?*/
    statut varchar(20) NOT NULL,
    CONSTRAINT courseid FOREIGN KEY (courseid) REFERENCES Course(courseid)
);

CREATE TABLE Forme(
    formeid number(3) PRIMARY KEY,
    jockeyid number(2),
    chevalid number(2),
    CONSTRAINT jockeyid FOREIGN KEY (jockeyid) REFERENCES Jockey(jockeyid),
    CONSTRAINT chevalid FOREIGN KEY (chevalid) REFERENCES Cheval(chevalid)
);

CREATE TABLE Duo(
    duoid number(3) PRIMARY KEY, 
    formeid number(3),
    entraineurid number(2),
    discipline varchar(20),
    CONSTRAINT unq_duo UNIQUE (formeid, entraineurid), 
    CONSTRAINT fk_duo_entraineur FOREIGN KEY (entraineurid) REFERENCES Entraineur(entraineurid),
    CONSTRAINT fk_duo_forme FOREIGN KEY (formeid) REFERENCES Forme(formeid)
);
CREATE TABLE Duo(
    formeid number(3) PRIMARY KEY,
    entraineurid number(2) PRIMARY KEY,
    discipline varchar(20),
    CONSTRAINT entraineurid FOREIGN KEY (entraineurid) REFERENCES Entraineur(entraineurid)
);

CREATE TABLE Parier(
    parisid number(2) PRIMARY KEY,
    parieurid number(2) PRIMARY KEY,
    CONSTRAINT parisid FOREIGN KEY (parisid) REFERENCES Paris(parisid),
    CONSTRAINT parieurid FOREIGN KEY (parieurid) REFERENCES Parieur(parieurid)
);

CREATE TABLE Mise(
    parisid number(2) PRIMARY KEY,
    participationid number(3) PRIMARY KEY,
    CONSTRAINT parisid FOREIGN KEY (parisid) REFERENCES Paris(parisid),
    CONSTRAINT participationid FOREIGN KEY (participationid) REFERENCES Participation(participationid)
);

CREATE TABLE Inscription(
    inscriptionid number(3) PRIMARY KEY,
    participationid number(3),
    duoid number(3), 
    statut varchar(20) NOT NULL,
    CONSTRAINT participationid FOREIGN KEY (participationid) REFERENCES Participation(participationid),
    CONSTRAINT parieurid FOREIGN KEY (parieurid) REFERENCES Parieur(parieurid)
);

CREATE TABLE Appartient(
    proprietaireid number(3) PRIMARY KEY,
    chevalid number(2) PRIMARY KEY,
    part number(3),
    CONSTRAINT proprietaireid FOREIGN KEY (proprietaireid) REFERENCES Propietaire(proprietaireid),
    CONSTRAINT chevalid FOREIGN KEY (chevalid) REFERENCES Cheval(chevalid)
);
