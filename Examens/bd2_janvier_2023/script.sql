DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen;

CREATE TABLE examen.examens (
    code                    CHAR(8)     PRIMARY KEY CHECK ( code SIMILAR TO 'BINV[0-9]{4}'),
    nom_exam                VARCHAR(50) NOT NULL CHECK ( trim(nom_exam) != '' ),
    bloc                    INTEGER     NOT NULL CHECK ( bloc BETWEEN 1 AND 3 ),
    date_exam               DATE        NOT NULL,
    nbre_inscrits           INTEGER     NOT NULL CHECK ( nbre_inscrits > 0 ),
    completement_reserve    BOOLEAN     NOT NULL DEFAULT FALSE,
    machine                 BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE TABLE examen.locaux (
    id              SERIAL      PRIMARY KEY,
    nom_local       VARCHAR(50) NOT NULL CHECK ( trim(nom_local) != '' ),
    nbre_places     INTEGER     NOT NULL CHECK ( nbre_places > 0 ),
    machine_dispo   BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE TABLE examen.reservations (
    examen          CHAR(8)     NOT NULL,
    local           INTEGER     NOT NULL,

    PRIMARY KEY (examen, local),
    FOREIGN KEY (examen)    REFERENCES examen.examens(code),
    FOREIGN KEY (local)     REFERENCES examen.locaux(id)
);

CREATE OR REPLACE FUNCTION examen.insertionReservation_trigger() RETURNS TRIGGER AS $$
DECLARE
    _machine_exam BOOLEAN;
    _machine_local BOOLEAN;
    _complet BOOLEAN;
    _date DATE;
    _places_local INTEGER;
    _nbre_inscrits INTEGER;
    _total_places INTEGER;

BEGIN
    SELECT e.machine, e.completement_reserve, e.date_exam, e.nbre_inscrits INTO _machine_exam, _complet, _date, _nbre_inscrits FROM examen.examens e WHERE e.code = NEW.examen;

    IF (_machine_exam = TRUE) THEN
        SELECT l.machine_dispo FROM examen.locaux l WHERE l.id = NEW.local INTO _machine_local;
        IF (_machine_local != TRUE) THEN
            RAISE EXCEPTION 'L’examen se déroule sur machine et il n’y a pas de machine disponible dans ce local';
        END IF;
    END IF;

    IF (_complet = TRUE) THEN
        RAISE EXCEPTION 'L’examen est complètement réservé';
    END IF;

    IF (EXISTS(SELECT 1
               FROM examen.reservations r, examen.examens e
               WHERE r.examen != NEW.examen
                 AND e.code = r.examen
                 AND e.date_exam = _date
                 AND r.local = NEW.local)) THEN
        RAISE EXCEPTION 'Il existe déjà une réservation pour un autre examen dans le local le même jour';
    END IF;

    -- Calcul du nombre total de places disponibles dans les locaux réservés pour l'examen
    SELECT COALESCE(SUM(l.nbre_places), 0) INTO _total_places
    FROM examen.locaux l
    JOIN examen.reservations r ON l.id = r.local
    WHERE r.examen = NEW.examen;

    -- Ajout des places du nouveau local réservé
    SELECT l.nbre_places INTO _places_local
    FROM examen.locaux l WHERE l.id = NEW.local;
    _total_places := _total_places + _places_local;

    -- Vérifier si le nombre de places est suffisant pour accueillir tous les étudiants inscrits
    IF (_total_places >= _nbre_inscrits) THEN
        UPDATE examen.examens SET completement_reserve = TRUE WHERE code = NEW.examen;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER insertionReservation_trigger BEFORE INSERT OR UPDATE ON examen.reservations
FOR EACH ROW EXECUTE FUNCTION examen.insertionReservation_trigger();

CREATE OR REPLACE FUNCTION examen.insererReservation(_nom_local VARCHAR(50), _code_exam CHAR(8)) RETURNS INTEGER AS $$
DECLARE
    _toReturn INTEGER;
    _id_local INTEGER;
BEGIN
    _id_local := (SELECT l.id FROM examen.locaux l WHERE l.nom_local = _nom_local);
    INSERT INTO examen.reservations (local, examen) VALUES (_id_local, _code_exam);

    SELECT COUNT(*) INTO _toReturn
    FROM examen.examens e
    WHERE e.completement_reserve = TRUE
      AND e.code IN (SELECT r.examen
                     FROM examen.reservations r
                     WHERE r.local = _id_local);

    RETURN _toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW examen.vue AS
SELECT e.bloc, e.code, e.nom_exam, e.date_exam, COALESCE(COUNT(r.local), 0) AS "nbre_locaux"
FROM examen.examens e
    LEFT OUTER JOIN examen.reservations r ON e.code = r.examen
GROUP BY e.code, e.bloc, e.nom_exam, e.date_exam;

