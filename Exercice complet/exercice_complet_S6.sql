DROP SCHEMA IF EXISTS exercice_complet CASCADE;

CREATE SCHEMA exercice_complet;

CREATE TABLE exercice_complet.festivals (
    id_festival     SERIAL      PRIMARY KEY,

    nom     VARCHAR(50) NOT NULL CHECK ( nom != '' )
);

CREATE TABLE exercice_complet.salles (
    id_salle    SERIAL          PRIMARY KEY,

    nom         VARCHAR(50)     NOT NULL CHECK ( nom != '' ),
    ville       VARCHAR(50)     NOT NULL CHECK ( ville != '' ),
    capacite    INTEGER         NOT NULL CHECK ( capacite > 0 )
);

CREATE TABLE exercice_complet.artistes (
    id_artiste   SERIAL          PRIMARY KEY,

    nom          VARCHAR(50)     NOT NULL CHECK ( nom != '' ),
    nationalite  CHAR(3)         CHECK ( nationalite SIMILAR TO '[A-Z]{3}' )
);

CREATE TABLE exercice_complet.clients (
    id_client   SERIAL  PRIMARY KEY,

    nom_utilisateur VARCHAR(50) NOT NULL UNIQUE CHECK ( nom_utilisateur != '' ),
    email           VARCHAR(50) NOT NULL CHECK ( email SIMILAR TO '%@%.%' ),
    mot_de_passe    VARCHAR(50) NOT NULL CHECK ( mot_de_passe != '' )
);

CREATE TABLE exercice_complet.evenements (
    salle            INTEGER     NOT NULL,
    date_evenement   DATE        NOT NULL,

    nom                 VARCHAR(50)    NOT NULL CHECK ( nom != '' ),
    prix                INTEGER        NOT NULL CHECK ( prix > 0 ),
    nb_places_restantes INTEGER        NOT NULL CHECK ( nb_places_restantes > 0 ),
    festival            INTEGER        NOT NULL,

    FOREIGN KEY (salle) REFERENCES exercice_complet.salles(id_salle),
    FOREIGN KEY (festival) REFERENCES exercice_complet.festivals(id_festival),
    PRIMARY KEY (salle, date_evenement)
);

CREATE TABLE exercice_complet.concerts (
    artiste          INTEGER     NOT NULL,
    date_evenement   DATE        NOT NULL,

    heure_debut      TIME        NOT NULL,
    salle            INTEGER     NOT NULL,

    FOREIGN KEY (artiste) REFERENCES exercice_complet.artistes(id_artiste),
    FOREIGN KEY (salle, date_evenement) REFERENCES exercice_complet.evenements(salle, date_evenement),
    PRIMARY KEY (artiste, date_evenement),
    UNIQUE (salle, date_evenement, heure_debut)
);

CREATE TABLE exercice_complet.reservations (
    salle           INTEGER     NOT NULL,
    date_evenement  DATE        NOT NULL,
    num_reservation SERIAL      NOT NULL,

    nb_tickets      INTEGER     NOT NULL CHECK ( nb_tickets > 0),
    client          INTEGER     NOT NULL,

    FOREIGN KEY (client) REFERENCES exercice_complet.clients(id_client),
    FOREIGN KEY (salle, date_evenement) REFERENCES exercice_complet.evenements(salle, date_evenement),
    PRIMARY KEY (salle, date_evenement, num_reservation)

);

CREATE OR REPLACE FUNCTION exercice_complet.ajouterSalle(_nom VARCHAR(50), _ville VARCHAR(50), _capacite INTEGER) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO exercice_complet.salles(nom, ville, capacite) VALUES (_nom, _ville, _capacite);

    SELECT s.id_salle INTO toReturn
    FROM exercice_complet.salles s
    WHERE s.nom = _nom
      AND s.ville = _ville
      AND s.capacite = _capacite;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exercice_complet.ajouterFestival(_nom VARCHAR(50)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO exercice_complet.festivals(nom) VALUES (_nom);

    SELECT f.id_festival INTO toReturn
    FROM exercice_complet.festivals f
    WHERE f.nom = _nom;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exercice_complet.ajouterArtiste(_nom VARCHAR(50), _nationalite CHAR(3)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO exercice_complet.artistes(nom, nationalite) VALUES (_nom, _nationalite);

    SELECT a.id_artiste INTO toReturn
    FROM exercice_complet.artistes a
    WHERE a.nom = _nom
      AND a.nationalite = _nationalite;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exercice_complet.ajouterArtiste(_nom VARCHAR(50)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO exercice_complet.artistes(nom) VALUES (_nom);

    SELECT a.id_artiste INTO toReturn
    FROM exercice_complet.artistes a
    WHERE a.nom = _nom;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exercice_complet.ajouterClient(_nom_utilisateur VARCHAR(50), _email VARCHAR(50), _mot_de_passe VARCHAR(50))
    RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO exercice_complet.clients(nom_utilisateur, email, mot_de_passe) VALUES (_nom_utilisateur, _email, _mot_de_passe);

    SELECT c.id_client INTO toReturn
    FROM exercice_complet.clients c
    WHERE c.nom_utilisateur = _nom_utilisateur
      AND c.email = _email
      AND c.mot_de_passe = _mot_de_passe;

    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

/* TESTS */
SELECT exercice_complet.ajouterSalle('Palais 12', 'Bruxelles', 15000);
SELECT exercice_complet.ajouterSalle('La Madeleine', 'Bruxelles', 15000);
SELECT exercice_complet.ajouterSalle('Cirque Royal', 'Bruxelles', 15000);
SELECT exercice_complet.ajouterSalle('Sportpaleis Antwerpen', 'Anvers', 15000);

SELECT exercice_complet.ajouterFestival('Les Ardentes');
SELECT exercice_complet.ajouterFestival('Lolapalooza');
SELECT exercice_complet.ajouterFestival('Afronation');

SELECT exercice_complet.ajouterArtiste('Beyoncé', 'USA');
SELECT exercice_complet.ajouterArtiste('Eminem');

SELECT exercice_complet.ajouterClient('user007', 'user007@live.be', '***********');
--SELECT exercice_complet.ajouterClient('user007', 'user007@.be', '***ok********');
SELECT exercice_complet.ajouterClient('user1203', 'user007@live.be', '***********');
