DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen;

CREATE TABLE examen.formations (
    id_formation              SERIAL       PRIMARY KEY,
    niveau                    INTEGER      NOT NULL CHECK ( niveau BETWEEN 1 AND 5 ),
    date_formation            DATE         NOT NULL,
    nombre_max_participants   INTEGER      NOT NULL CHECK ( nombre_max_participants > 0 ),
    cloturee                  BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE examen.participants (
    id_participant  SERIAL      PRIMARY KEY,
    nom             VARCHAR(50) NOT NULL CHECK (trim(nom) != ''),
    prenom          VARCHAR(50) NOT NULL CHECK (trim(prenom) != ''),
    nationalite     VARCHAR(50) NOT NULL CHECK (trim(nationalite) != '')
);

CREATE TABLE examen.inscriptions (
    participant INTEGER NOT NULL,
    formation   INTEGER NOT NULL,

    PRIMARY KEY (participant, formation),
    FOREIGN KEY (participant) REFERENCES examen.participants(id_participant),
    FOREIGN KEY (formation) REFERENCES examen.formations(id_formation)
);

--procédure stockée
CREATE OR REPLACE FUNCTION examen.inscrire(_participant INTEGER, _formation INTEGER) RETURNS INTEGER AS $$
DECLARE
    _toReturn INTEGER;
    _niveau INTEGER;
BEGIN
    INSERT INTO examen.inscriptions(participant, formation) VALUES (_participant, _formation);

    SELECT f.niveau FROM examen.formations f WHERE f.id_formation = _formation INTO _niveau;

    SELECT COUNT(DISTINCT i.participant)
    FROM examen.formations f, examen.inscriptions i
    WHERE f.id_formation = i.formation
      AND f.niveau = _niveau
    INTO _toReturn;

    RETURN _toReturn;
END;
$$ LANGUAGE plpgsql;

--trigger
CREATE OR REPLACE FUNCTION examen.inscriptionTrigger() RETURNS TRIGGER AS $$
DECLARE
    _cloturee BOOLEAN;
    _date DATE;
    _niveauFormation INTEGER;
    _niveauParticipant INTEGER;
    _nbreParticipants INTEGER;
    _nbreInscriptions INTEGER;
BEGIN
    SELECT f.cloturee, f.date_formation, f.niveau, f.nombre_max_participants FROM examen.formations f WHERE f.id_formation = NEW.formation
    INTO _cloturee, _date, _niveauFormation, _nbreParticipants;

    IF (_date < CURRENT_DATE) THEN
        RAISE EXCEPTION 'La date de formation est passée.';
    END IF;

    IF (_cloturee = TRUE) THEN
        RAISE EXCEPTION 'Les inscriptions sont cloturées.';
    END IF;

    IF (_niveauFormation > 1) THEN
        SELECT MAX(f.niveau)
        FROM examen.inscriptions i, examen.formations f
        WHERE i.participant = NEW.participant
          AND f.id_formation = i.formation AND f.date_formation < _date
        INTO _niveauParticipant;

        IF (_niveauParticipant < _niveauFormation-1 OR _niveauParticipant IS NULL) THEN
            RAISE EXCEPTION 'Le participant n''a pas d''inscription à une formation de niveau strictement inférieur avant cette formation.';
        END IF;
    END IF;

    SELECT COUNT(*) FROM examen.inscriptions i WHERE i.formation = NEW.formation INTO _nbreInscriptions;

    IF (_nbreInscriptions + 1 = _nbreParticipants) THEN
        UPDATE examen.formations SET cloturee = TRUE WHERE id_formation = NEW.formation;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inscriptionTrigger BEFORE INSERT ON examen.inscriptions
FOR EACH ROW EXECUTE PROCEDURE examen.inscriptionTrigger();

--view
CREATE OR REPLACE VIEW examen.vue AS
SELECT p.id_participant, p.nom, p.prenom, COALESCE(MAX(f.niveau), 0) AS niveau, p.nationalite
FROM examen.participants p
    LEFT OUTER JOIN examen.inscriptions i ON p.id_participant = i.participant
    LEFT OUTER JOIN examen.formations f ON f.id_formation = i.formation AND f.date_formation <= CURRENT_DATE
GROUP BY p.id_participant, p.nom, p.prenom, p.nationalite;

-- SELECT * FROM examen.vue WHERE nationalite = 'Belge' ORDER BY nom, prenom;
