DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen;

CREATE TABLE examen.concerts (
    id_concert      SERIAL          PRIMARY KEY,
    date_concert    DATE            NOT NULL,
    artiste         VARCHAR(100)    NOT NULL CHECK ( artiste <> '' ),
    salle           VARCHAR(100)    NOT NULL CHECK ( salle <> '' ),
    nbr_places      INTEGER         NOT NULL CHECK ( nbr_places > 0 ),
    complet         BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE TABLE examen.clients (
    id_client   SERIAL          PRIMARY KEY,
    nom         VARCHAR(100)    NOT NULL CHECK ( nom <> '' ),
    prenom      VARCHAR(100)    NOT NULL CHECK ( prenom <> '' ),
    sexe        CHAR(1)         NOT NULL CHECK ( sexe IN ('M', 'F') )
);

CREATE TABLE examen.reservations (
    num_reservation     INTEGER         NOT NULL,
    concert             INTEGER         NOT NULL,
    client              INTEGER         NOT NULL,
    nbr_tickets         INTEGER         NOT NULL CHECK ( nbr_tickets > 0 ),

    PRIMARY KEY (num_reservation, concert),
    FOREIGN KEY (concert) REFERENCES examen.concerts(id_concert),
    FOREIGN KEY (client) REFERENCES examen.clients(id_client)
);

CREATE OR REPLACE FUNCTION examen.reserver_tickets(_client INTEGER, _concert INTEGER, _nbr_places INTEGER) RETURNS BOOLEAN AS $$
DECLARE
    _num_reservation INTEGER;
BEGIN
    SELECT COUNT(*) FROM examen.reservations WHERE concert = _concert INTO _num_reservation;

    INSERT INTO examen.reservations VALUES (_num_reservation+1, _concert, _client, _nbr_places);
    RETURN (SELECT complet FROM examen.concerts WHERE id_concert = _concert);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION examen.verifier_reservation() RETURNS TRIGGER AS $$
DECLARE
    _nbr_places INTEGER;
    _date_concert DATE;
BEGIN
    _date_concert := (SELECT c.date_concert FROM examen.concerts c WHERE c.id_concert = NEW.concert);
    _nbr_places := (SELECT c.nbr_places FROM examen.concerts c WHERE c.id_concert = NEW.concert);
    IF ((SELECT SUM(nbr_tickets) FROM examen.reservations r WHERE r.concert = NEW.concert AND r.client = NEW.client) + NEW.nbr_tickets > 4) THEN
        RAISE EXCEPTION 'Max 4 tickets par réservation.';
    END IF;

    IF (EXISTS (SELECT * FROM examen.reservations r,examen.concerts c WHERE r.client = NEW.client AND r.concert = c.id_concert AND c.date_concert = _date_concert AND c.id_concert != NEW.concert)) THEN
        RAISE EXCEPTION 'Déjà un autre concert ce même soir';
    END IF;

    IF ((SELECT SUM(nbr_tickets) FROM examen.reservations r WHERE r.concert = NEW.concert) + NEW.nbr_tickets > _nbr_places) THEN
        RAISE EXCEPTION 'Il ne reste plus assez de tickets pour votre demande.';
    END IF;

    IF ((SELECT SUM(nbr_tickets) FROM examen.reservations r WHERE r.concert = NEW.concert) + NEW.nbr_tickets = _nbr_places) THEN
        UPDATE examen.concerts SET complet = TRUE WHERE id_concert = NEW.concert;
    END IF;
    
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER verifier_reservation BEFORE INSERT ON examen.reservations
    FOR EACH ROW EXECUTE FUNCTION examen.verifier_reservation();


CREATE OR REPLACE VIEW examen.voir_concerts_artiste AS
SELECT c.date_concert, c.salle, COALESCE(SUM(r.nbr_tickets), 0) AS "nbr_tickets_reserves", c.artiste
FROM examen.concerts c
    LEFT OUTER JOIN examen.reservations r ON c.id_concert = r.concert
GROUP BY c.date_concert, c.salle, c.artiste
ORDER BY c.date_concert;