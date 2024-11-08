DROP SCHEMA IF EXISTS gestion_evenements CASCADE;

CREATE SCHEMA gestion_evenements;

CREATE TABLE gestion_evenements.salles(
    id_salle    SERIAL      PRIMARY KEY,
    nom         VARCHAR(50) NOT NULL CHECK (trim(nom) <> ''),
    ville       VARCHAR(30) NOT NULL CHECK (trim(ville) <> ''),
    capacite    INTEGER NOT NULL CHECK (capacite > 0)
);

CREATE TABLE gestion_evenements.festivals (
    id_festival SERIAL          PRIMARY KEY,
    nom         VARCHAR(100)    NOT NULL CHECK (trim(nom) <> '')
);

CREATE TABLE gestion_evenements.evenements (
    salle               INTEGER         NOT NULL REFERENCES gestion_evenements.salles(id_salle),
    date_evenement      DATE            NOT NULL,
    nom                 VARCHAR(100)    NOT NULL CHECK (trim(nom) <> ''),
    prix                MONEY           NOT NULL CHECK (prix >= 0 :: MONEY),
    nb_places_restantes INTEGER         NOT NULL CHECK (nb_places_restantes >= 0),
    festival            INTEGER         REFERENCES gestion_evenements.festivals(id_festival),
    PRIMARY KEY (salle,date_evenement)
);

CREATE TABLE gestion_evenements.artistes(
    id_artiste  SERIAL          PRIMARY KEY,
    nom         VARCHAR(100)    NOT NULL CHECK (trim(nom) <> ''),
    nationalite CHAR(3)         NULL CHECK (trim(nationalite) SIMILAR TO '[A-Z]{3}')
);

CREATE TABLE gestion_evenements.concerts(
    artiste         INTEGER NOT NULL REFERENCES gestion_evenements.artistes(id_artiste),
    salle           INTEGER NOT NULL,
    date_evenement  DATE    NOT NULL,
    heure_debut     TIME    NOT NULL,

    PRIMARY KEY(artiste,date_evenement),
    UNIQUE(salle,date_evenement,heure_debut),
    FOREIGN KEY (salle,date_evenement) REFERENCES gestion_evenements.evenements(salle,date_evenement)
);

CREATE TABLE gestion_evenements.clients (
    id_client       SERIAL      PRIMARY KEY,
    nom_utilisateur VARCHAR(25) NOT NULL UNIQUE CHECK (trim(nom_utilisateur) <> '' ),
    email           VARCHAR(50) NOT NULL CHECK (email SIMILAR TO '%@([[:alnum:]]+[.-])*[[:alnum:]]+.[a-zA-Z]{2,4}' AND trim(email) NOT LIKE '@%'),
    mot_de_passe    CHAR(60)    NOT NULL
);

CREATE TABLE gestion_evenements.reservations(
    salle           INTEGER NOT NULL,
    date_evenement  DATE    NOT NULL,
    num_reservation INTEGER NOT NULL, --pas de check car sera géré automatiquement
    nb_tickets      INTEGER CHECK (nb_tickets BETWEEN 1 AND 4),
    client          INTEGER NOT NULL REFERENCES gestion_evenements.clients(id_client),

    PRIMARY KEY(salle,date_evenement,num_reservation),
    FOREIGN KEY (salle,date_evenement) REFERENCES gestion_evenements.evenements(salle,date_evenement)
);

CREATE OR REPLACE FUNCTION gestion_evenements.ajouterSalle(_nom VARCHAR(50), _ville VARCHAR(30), _capacite INTEGER) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.salles(nom, ville, capacite) VALUES (_nom, _ville, _capacite);

    SELECT s.id_salle INTO toReturn
    FROM gestion_evenements.salles s
    WHERE s.nom = _nom
      AND s.ville = _ville
      AND s.capacite = _capacite;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gestion_evenements.ajouterFestival(_nom VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.festivals(nom) VALUES (_nom);

    SELECT f.id_festival INTO toReturn
    FROM gestion_evenements.festivals f
    WHERE f.nom = _nom;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gestion_evenements.ajouterArtiste(_nom VARCHAR(100), _nationalite CHAR(3)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.artistes(nom, nationalite) VALUES (_nom, _nationalite);

    SELECT a.id_artiste INTO toReturn
    FROM gestion_evenements.artistes a
    WHERE a.nom = _nom
      AND a.nationalite = _nationalite;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gestion_evenements.ajouterArtiste(_nom VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.artistes(nom) VALUES (_nom);

    SELECT a.id_artiste INTO toReturn
    FROM gestion_evenements.artistes a
    WHERE a.nom = _nom;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gestion_evenements.ajouterClient(_nom_utilisateur VARCHAR(25), _email VARCHAR(50), _mot_de_passe VARCHAR(60))
    RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.clients(nom_utilisateur, email, mot_de_passe) VALUES (_nom_utilisateur, _email, _mot_de_passe);

    SELECT c.id_client INTO toReturn
    FROM gestion_evenements.clients c
    WHERE c.nom_utilisateur = _nom_utilisateur
      AND c.email = _email
      AND c.mot_de_passe = _mot_de_passe;

    RETURN toReturn;
END
$$ LANGUAGE plpgsql;