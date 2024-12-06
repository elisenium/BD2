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

-- ajout salle
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterSalle(_nom VARCHAR(50), _ville VARCHAR(30), _capacite INTEGER) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.salles(nom, ville, capacite) VALUES (_nom, _ville, _capacite)
    RETURNING id_salle INTO toReturn;
    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

-- ajout festival
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterFestival(_nom VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.festivals(nom) VALUES (_nom)
    RETURNING id_festival INTO toReturn;
    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

-- ajout artiste
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterArtiste(_nom VARCHAR(100), _nationalite CHAR(3)) RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.artistes(nom, nationalite) VALUES (_nom, _nationalite)
    RETURNING id_artiste INTO toReturn;
    RETURN toReturn;
END;
$$ LANGUAGE plpgsql;

-- ajout client
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterClient(_nom_utilisateur VARCHAR(25), _email VARCHAR(50), _mot_de_passe VARCHAR(60))
    RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.clients(nom_utilisateur, email, mot_de_passe) VALUES (_nom_utilisateur, _email, _mot_de_passe)
    RETURNING id_client INTO toReturn;
    RETURN toReturn;
END
$$ LANGUAGE plpgsql;

-- ajout évènement
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterEvenement(_salle INTEGER, _date_evenement DATE, _nom VARCHAR(100), _prix MONEY, _festival INTEGER) RETURNS VOID AS $$
DECLARE
    _nb_places_restantes INTEGER;
BEGIN
    INSERT INTO gestion_evenements.evenements(salle, date_evenement, nom, prix, festival, nb_places_restantes)
    VALUES (_salle, _date_evenement, _nom, _prix, _festival, _nb_places_restantes);
END
$$ LANGUAGE plpgsql;

-- trigger ajout évènement
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterEvenementTrigger() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.date_evenement <= CURRENT_DATE) THEN
        RAISE EXCEPTION 'la date de l''événement ajoutée est antérieure à la date actuelle';
    END IF;
    NEW.nb_places_restantes = (SELECT s.capacite FROM gestion_evenements.salles s WHERE s.id_salle = NEW.salle);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouterEvenementTrigger BEFORE INSERT ON gestion_evenements.evenements
FOR EACH ROW EXECUTE PROCEDURE gestion_evenements.ajouterEvenementTrigger();

-- ajout concert
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterConcert(_artiste INTEGER, _date_evenement DATE, _heure_debut TIME, _salle INTEGER)
    RETURNS VOID AS $$
BEGIN
    INSERT INTO gestion_evenements.concerts(artiste, date_evenement, heure_debut, salle)
    VALUES (_artiste, _date_evenement, _heure_debut, _salle);
END
$$ LANGUAGE plpgsql;
-- trigger concert
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterConcertTrigger() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.date_evenement < CURRENT_DATE) THEN
        RAISE EXCEPTION 'La date de l''événement ajoutée est antérieure à la date actuelle';
    END IF;

    IF (EXISTS(SELECT 1
               FROM gestion_evenements.concerts c, gestion_evenements.evenements e
               WHERE c.salle = e.salle
                 AND c.date_evenement = e.date_evenement
                 AND c.artiste = NEW.artiste
                 AND e.salle = NEW.salle
                 AND e.festival IS NOT NULL)) THEN
        RAISE EXCEPTION 'Un artiste ne peut pas avoir deux concerts pour le même festival';
    END IF;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouterConcertTrigger BEFORE INSERT ON gestion_evenements.concerts
FOR EACH ROW EXECUTE PROCEDURE gestion_evenements.ajouterConcertTrigger();

-- ajout réservation
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterReservation(_id_salle INTEGER, _date_evenement DATE, _nb_tickets INTEGER, _id_client INTEGER)
    RETURNS INTEGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    INSERT INTO gestion_evenements.reservations(salle, date_evenement, nb_tickets, client)
    VALUES (_id_salle, _date_evenement, _nb_tickets, _id_client)
    RETURNING num_reservation INTO toReturn;
    RETURN toReturn;
END
$$ LANGUAGE plpgsql;

--trigger réservation
CREATE OR REPLACE FUNCTION gestion_evenements.ajouterReservationTrigger() RETURNS TRIGGER AS $$
DECLARE
    toReturn INTEGER;
BEGIN
    -- si la date de l'événement est déjà passée
    IF (NEW.date_evenement < CURRENT_DATE) THEN
        RAISE EXCEPTION 'La date de l''événement est déjà passée';
    END IF;

    -- l’événement n’a pas de concert
    IF (NOT EXISTS(SELECT * FROM gestion_evenements.concerts c WHERE c.date_evenement = NEW.date_evenement AND c.salle = NEW.salle)) THEN
        RAISE EXCEPTION 'L’événement n’a pas de concert';
    END IF;

    -- le client réserve trop de places pour l'événement
    IF (NEW.nb_tickets + (SELECT COALESCE(SUM(r.nb_tickets),0)
                          FROM gestion_evenements.reservations r
                          WHERE r.salle = NEW.salle
                            AND r.date_evenement = NEW.date_evenement
                            AND r.client = NEW.client)) > 4 THEN
        RAISE EXCEPTION 'Ce client réserve trop de places pour l''événement (4 maximum)';
    END IF;

    -- Le client a déjà une réservation pour un autre événement à la même date
    IF (EXISTS(SELECT *
               FROM gestion_evenements.reservations r
               WHERE r.client = NEW.client
                 AND r.date_evenement = NEW.date_evenement
                 AND r.salle != NEW.salle)) THEN
        RAISE EXCEPTION 'Ce client a déjà une réservation pour un autre événement à la même date';
    END IF;

    -- update des places restantes
    UPDATE gestion_evenements.evenements e SET nb_places_restantes = nb_places_restantes - NEW.nb_tickets
    WHERE e.date_evenement = NEW.date_evenement AND e.salle = NEW.salle;

    -- initialisation du numéro de réservation
    SELECT COUNT(*) + 1
    FROM gestion_evenements.reservations r
    WHERE r.date_evenement = NEW.date_evenement
      AND r.salle = NEW.salle
    INTO NEW.num_reservation;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouterReservationTrigger BEFORE INSERT ON gestion_evenements.reservations
FOR EACH ROW EXECUTE PROCEDURE gestion_evenements.ajouterReservationTrigger();


/* TESTS */
SELECT gestion_evenements.ajouterSalle('Palais 12', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('La Madeleine', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('Cirque Royal', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('Sportpaleis Antwerpen', 'Anvers', 15000);

SELECT gestion_evenements.ajouterFestival('Les Ardentes');
SELECT gestion_evenements.ajouterFestival('Lolapalooza');
SELECT gestion_evenements.ajouterFestival('Afronation');

SELECT gestion_evenements.ajouterArtiste('Beyoncé', 'USA');

SELECT gestion_evenements.ajouterClient('user007', 'user007@live.be', '***********');
--SELECT gestion_evenements.ajouterClient('user007', 'user007@.be', '***ok********'); --Test: PK
SELECT gestion_evenements.ajouterClient('user1203', 'user007@live.be', '***********');
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement1', 600.00::MONEY, 1); --TEST KO: date passée
SELECT gestion_evenements.ajouterEvenement(1, '2025-05-20', 'Evenement1', 600.00::MONEY, 1);
SELECT gestion_evenements.ajouterEvenement(2, '2025-05-01', 'Evenement2', 10.00::MONEY, 2);
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement2', 600.00::MONEY, 1); --Test: PK
--SELECT gestion_evenements.ajouterEvenement(1, '2024-09-21', 'Evenement1', 600.00::MONEY, 1); --Test: date antérieure
SELECT gestion_evenements.ajouterConcert(1, '2025-05-20', '20:00', 1);
--SELECT gestion_evenements.ajouterConcert(1, '2025-05-20', '10:00', 1); --Test: tentative artiste 2 concerts au même festival

SELECT gestion_evenements.ajouterReservation(1, '2025-05-20', 2, 1);