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
    nom_utilisateur VARCHAR(25) UNIQUE NOT NULL UNIQUE CHECK (trim(nom_utilisateur) <> '' ),
    email           VARCHAR(50) UNIQUE NOT NULL CHECK (email SIMILAR TO '%@([[:alnum:]]+[.-])*[[:alnum:]]+.[a-zA-Z]{2,4}' AND trim(email) NOT LIKE '@%'),
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
CREATE OR REPLACE FUNCTION gestion_evenements.inscrireClient(_nom_utilisateur VARCHAR(25), _email VARCHAR(50), _mot_de_passe VARCHAR(60))
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

-- reservation festival
CREATE OR REPLACE FUNCTION gestion_evenements.reserverFestival(_id_festival INTEGER, _id_client INTEGER, _nb_places INTEGER)
    RETURNS VOID AS $$
DECLARE
    _evenement RECORD;
BEGIN
    FOR _evenement IN
    SELECT e.date_evenement, e.salle FROM gestion_evenements.evenements e
    WHERE e.festival = _id_festival
    LOOP
        PERFORM gestion_evenements.ajouterReservation(_evenement.salle, _evenement.date_evenement,
                                                      _nb_places, _id_client);
    END LOOP;
END
$$ LANGUAGE plpgsql;

--view festivals pour client
CREATE OR REPLACE VIEW gestion_evenements.festivalView AS
SELECT f.id_festival, f.nom, MIN(e.date_evenement), MAX(e.date_evenement), SUM(e.prix) AS "prix_total"
FROM gestion_evenements.evenements e, gestion_evenements.festivals f
WHERE e.festival = f.id_festival
GROUP BY f.id_festival, f.nom
HAVING MAX(e.date_evenement) >= CURRENT_DATE
ORDER BY 3;

--view reservations-clients
CREATE OR REPLACE VIEW gestion_evenements.reservationsClients AS
SELECT e.nom, e.date_evenement, r.num_reservation, r.client, r.nb_tickets
FROM gestion_evenements.evenements e, gestion_evenements.reservations r, gestion_evenements.salles s
WHERE r.date_evenement = e.date_evenement
  AND r.salle = e.salle
  AND r.salle = s.id_salle;

--view evenements-salle
CREATE OR REPLACE VIEW gestion_evenements.evenementsParSalle AS
SELECT e.nom AS "nom_event", e.date_evenement AS "date_event", s.id_salle AS "id_salle_event",
       s.nom AS "nom_salle_event", STRING_AGG(a.nom, ',') AS "artistes",
       e.prix, e.nb_places_restantes = 0 AS "complet"
FROM gestion_evenements.salles s, gestion_evenements.evenements e
    LEFT JOIN gestion_evenements.concerts co ON e.date_evenement = co.date_evenement AND e.salle = co.salle
    LEFT JOIN gestion_evenements.artistes a ON a.id_artiste = co.artiste
WHERE e.salle = s.id_salle
GROUP BY e.nom, e.date_evenement, s.id_salle, s.nom, e.prix, e.nb_places_restantes;

--view evenement-artiste
CREATE OR REPLACE VIEW gestion_evenements.evenementsParArtiste AS
SELECT e.nom AS "nom_event", e.date_evenement AS "date_event", s.id_salle AS "id_salle_event",
       s.nom AS "nom_salle_event", STRING_AGG(a.nom, ',') AS "artistes",
       e.prix, e.nb_places_restantes = 0 AS "complet", a.id_artiste
FROM gestion_evenements.salles s, gestion_evenements.evenements e
    LEFT JOIN gestion_evenements.concerts co ON e.date_evenement = co.date_evenement AND e.salle = co.salle
    LEFT JOIN gestion_evenements.artistes a ON a.id_artiste = co.artiste
WHERE e.salle = s.id_salle
GROUP BY e.nom, e.date_evenement, s.id_salle, s.nom, e.prix, e.nb_places_restantes, a.id_artiste;

-------------------------------------------- FONCTIONS CONNEXION CLIENT BCRYPT --------------------------------------------
CREATE OR REPLACE FUNCTION gestion_evenements.recupMDPCrypte(_email VARCHAR(50))
    RETURNS VARCHAR(60) as $$
DECLARE
    _mot_de_passe VARCHAR(60);
BEGIN

    IF NOT EXISTS (SELECT * FROM gestion_evenements.clients cl WHERE cl.email = _email) THEN
        RAISE 'Veuillez vous inscrire. Nom d''utilisateur et mot de passe introuvable';
    END IF;
    SELECT cl.mot_de_passe FROM gestion_evenements.clients cl WHERE cl.email = _email INTO _mot_de_passe;

    RETURN _mot_de_passe;
END
$$ LANGUAGE plpgsql;

----------------------------------------------- INSERTS -----------------------------------------------
-- Inserting data into salles table
INSERT INTO gestion_evenements.salles (nom, ville, capacite) VALUES
('Salle Pleyel', 'Paris', 1200),
('Zenith', 'Paris', 6200),
('Forest National', 'Bruxelles', 8800),
('Olympia', 'Paris', 2000),
('Ancienne Belgique', 'Bruxelles', 2000);

-- Inserting data into festivals table
INSERT INTO gestion_evenements.festivals (nom) VALUES
('Rock en Seine'),
('Tomorrowland'),
('Glastonbury Festival'),
('Coachella Valley Music and Arts Festival'),
('Fuji Rock Festival');

-- Inserting data into evenements table with future dates
INSERT INTO gestion_evenements.evenements (salle, date_evenement, nom, prix, nb_places_restantes, festival) VALUES
(1, '2025-07-15', 'Rock Night', 50.00::MONEY, 200, 1),
(2, '2025-08-20', 'Summer Beats', 100.00::MONEY, 500, 2),
(3, '2025-06-10', 'Jazz Evening', 75.00::MONEY, 300, NULL),
(4, '2025-09-05', 'Classical Music Gala', 60.00::MONEY, 150, 3),
(5, '2025-07-22', 'Indie Fest', 45.00::MONEY, 250, 4);

-- Inserting data into artistes table
INSERT INTO gestion_evenements.artistes (nom, nationalite) VALUES
('Coldplay', 'GBR'),
('Beyoncé', 'USA'),
('Daft Punk', 'FRA'),
('Ed Sheeran', 'GBR'),
('Stromae', 'BEL'),
('Eminem', 'USA');

-- Inserting data into clients table
INSERT INTO gestion_evenements.clients (nom_utilisateur, email, mot_de_passe) VALUES
('alice123', 'alice@example.com', '$2a$12$cGL8MCaSyr.76212UdQE9OxI1ljEwkXKeGZUwl4ltXoE1CEM85UnO'),
('bob456', 'bob@example.com', '$2a$12$z0CrVN3FBpumdAPOaFtl0OBIIS4t7qgX3fjer19hinacYfUjdeQbi'),
('charlie789', 'charlie@example.com', '$2a$12$Vf/yObefQn1sdWegHm73Yewozia1zQ.XSPbYy880gbiFXiGUjI7.G'),
('diana010', 'diana@example.com', '$2a$12$AHwe2YTzB0JewXpawg/0eeHa8bwy45L20/QvJ7DuAYc/gtM3hUeZi'),
('eve202', 'eve@example.com', '$2a$12$mjxFOwVQfCzuUgFuaBOB8uIPogGii1lcoCY6XvK7MnhX3j10wGlky'),
('frank303', 'frank@example.com', '$2a$12$bH5NxyCJXRS23YoOhUTCJ.3HpD01xc9ctGv08c9m1IVKqFSjrwEbO');

----------------------------------------------- TESTS --------------------------------------------
SELECT gestion_evenements.ajouterSalle('Palais 12', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('La Madeleine', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('Cirque Royal', 'Bruxelles', 15000);
SELECT gestion_evenements.ajouterSalle('Sportpaleis Antwerpen', 'Anvers', 15000);

SELECT gestion_evenements.ajouterFestival('Les Ardentes');
SELECT gestion_evenements.ajouterFestival('Lolapalooza');
SELECT gestion_evenements.ajouterFestival('Afronation');

SELECT gestion_evenements.ajouterArtiste('Beyoncé', 'USA');

SELECT gestion_evenements.inscrireClient('user007', 'user007@live.be', '***********');
--SELECT gestion_evenements.inscrireClient('user007', 'user007@.be', '***ok********'); --Test: PK
SELECT gestion_evenements.inscrireClient('user1203', 'user1203@live.be', '***********');
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement1', 600.00::MONEY, 1); --TEST KO: date passée
SELECT gestion_evenements.ajouterEvenement(1, '2025-05-20', 'Evenement1', 600.00::MONEY, 1);
SELECT gestion_evenements.ajouterEvenement(2, '2025-05-01', 'Evenement2', 10.00::MONEY, 2);
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement2', 600.00::MONEY, 1); --Test: PK
--SELECT gestion_evenements.ajouterEvenement(1, '2024-09-21', 'Evenement1', 600.00::MONEY, 1); --Test: date antérieure
SELECT gestion_evenements.ajouterConcert(1, '2025-05-20', '20:00', 1);
--SELECT gestion_evenements.ajouterConcert(1, '2025-05-20', '10:00', 1); --Test: tentative artiste 2 concerts au même festival

SELECT gestion_evenements.ajouterReservation(1, '2025-05-20', 2, 1);

SELECT * FROM gestion_evenements.festivalView;

SELECT * FROM gestion_evenements.reservationsClients;

SELECT * FROM gestion_evenements.evenementsParSalle WHERE id_salle_event = 2;
SELECT * FROM gestion_evenements.evenementsParArtiste WHERE artistes LIKE '%Beyoncé%';

SELECT * FROM gestion_evenements.clients WHERE id_client = 1;
