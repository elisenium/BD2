DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen

CREATE TABLE examen.enfants (
    id_enfant       SERIAL      PRIMARY KEY,
    nom             VARCHAR(50) NOT NULL CHECK ( trim(nom) != '' ),
    prenom          VARCHAR(50) NOT NULL CHECK ( trim(prenom) != '' ),
    sexe            CHAR(1)     NOT NULL CHECK ( sexe IN ('M', 'F') ),
    nbre_stages     INTEGER     NOT NULL CHECK ( nbre_stages >= 0 ) DEFAULT 0
);

CREATE TABLE examen.stages (
    id_stage                SERIAL          PRIMARY KEY,
    intitule                VARCHAR(50)     NOT NULL CHECK ( trim(intitule) != '' ),
    sport                   VARCHAR(50)     NOT NULL CHECK ( trim(sport) != '' ),
    num_semaine             INTEGER         NOT NULL CHECK ( num_semaine BETWEEN 1 AND 7 ),
    nbre_max_participants   INTEGER         NOT NULL CHECK ( nbre_max_participants > 0 ),
    sexe                    CHAR(1)         NOT NULL CHECK ( sexe IN ('M', 'F') )
);

CREATE TABLE examen.inscriptions (
    enfant          INTEGER     NOT NULL REFERENCES examen.enfants(id_enfant),
    stage           INTEGER     NOT NULL REFERENCES examen.stages(id_stage),

    PRIMARY KEY (enfant, stage)
);

--trigger
CREATE OR REPLACE FUNCTION examen.inscrireEnfant_trigger() RETURNS TRIGGER AS $$
DECLARE
    _sexe_enfant CHAR(1);
    _sexe_stage CHAR(1);
    _semaine_stage INTEGER;
    _nbre_inscriptions INTEGER;
    _nbre_inscriptions_max INTEGER;
BEGIN
    SELECT e.sexe INTO _sexe_enfant FROM examen.enfants e WHERE e.id_enfant = NEW.enfant;
    SELECT s.sexe, s.num_semaine, s.nbre_max_participants INTO _sexe_stage, _semaine_stage, _nbre_inscriptions_max FROM examen.stages s WHERE s.id_stage = NEW.stage;

    -- Lorsqu'un garçon (resp. une fille) veut s'inscrire à un stage réservé aux filles (resp. aux garçons)
    IF (_sexe_stage != _sexe_enfant) THEN
        RAISE EXCEPTION 'Ce stage n''est pas destiné au sexe de l''enfant.';
    END IF;

    -- Lorsque l'enfant est déjà inscrit à un autre stage la même semaine
    IF (EXISTS(SELECT 1
               FROM examen.stages s, examen.inscriptions i
               WHERE s.id_stage = i.stage
                 AND i.enfant = NEW.enfant
                 AND s.num_semaine = _semaine_stage)) THEN
        RAISE EXCEPTION 'L''enfant est déjà inscrit à un autre stage la même semaine.';
    END IF;

    _nbre_inscriptions := (SELECT COUNT(*) FROM examen.inscriptions i WHERE i.stage = NEW.stage);

    -- Lorsque le stage est complet
    IF (_nbre_inscriptions + 1 > _nbre_inscriptions_max) THEN
         RAISE EXCEPTION 'Le stage est complet.';
     END IF;

    UPDATE examen.enfants SET nbre_stages = nbre_stages + 1 WHERE id_enfant = NEW.enfant;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER inscrireEnfant_trigger BEFORE INSERT ON examen.inscriptions
FOR EACH ROW EXECUTE PROCEDURE examen.inscrireEnfant_trigger();

--procédure stockée
CREATE OR REPLACE FUNCTION examen.inscrireEnfant(_id_enfant INTEGER, _id_stage INTEGER) RETURNS INTEGER AS $$
DECLARE
    _num_semaine INTEGER;
    _toReturn INTEGER;

BEGIN
    INSERT INTO examen.inscriptions(enfant, stage) VALUES (_id_enfant, _id_stage);

    SELECT s.num_semaine INTO _num_semaine FROM examen.stages s WHERE s.id_stage = _id_stage;

    -- Le nombre total d'inscriptions se déroulant lors de la semaine du stage en paramètre
    SELECT COALESCE(COUNT(i.enfant), 0)
    FROM examen.stages s
        LEFT OUTER JOIN examen.inscriptions i ON s.id_stage = i.stage
    WHERE s.num_semaine = _num_semaine
    GROUP BY i.stage
    INTO _toReturn;

    RETURN _toReturn;
END;
$$ LANGUAGE plpgsql;

--view
CREATE OR REPLACE VIEW examen.vue AS
SELECT s.id_stage, s.intitule, s.num_semaine, COALESCE(COUNT(i.enfant), 0) AS nbre_inscrits, s.sport
FROM examen.stages s
    LEFT OUTER JOIN examen.inscriptions i ON s.id_stage = i.stage
GROUP BY s.id_stage, s.intitule, s.num_semaine, s.sport
--ORDER BY s.num_semaine -- /!\ ORDER BY mis dans la partie Java
;

--inserts
-- INSERT INTO examen.enfants (id_enfant, nom, prenom, sexe, nbre_stages) VALUES (1, 'Paul', 'Jean', 'M', 0);
-- INSERT INTO examen.enfants (id_enfant, nom, prenom, sexe, nbre_stages) VALUES (2, 'Marie', 'Lola', 'F', 0);
-- INSERT INTO examen.enfants (id_enfant, nom, prenom, sexe, nbre_stages) VALUES (3, 'Dupont', 'Luc', 'M', 0);
-- INSERT INTO examen.enfants (id_enfant, nom, prenom, sexe, nbre_stages) VALUES (4, 'Burt', 'Tom', 'M', 0);
--
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (1, 'stage de perfectionnement de foot', 'football', 1, 2, 'M');
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (2, 'stage de tennis', 'tennis', 2, 2, 'F');
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (3, 'stage de danse', 'danse', 3, 2, 'F');
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (4, 'stage de karate', 'karate', 1, 2, 'M');
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (5, 'stage de gymnastique', 'gymnastique', 2, 2, 'M');
-- INSERT INTO examen.stages (id_stage, intitule, sport, num_semaine, nbre_max_participants, sexe) VALUES (6, 'stage de karate', 'karate', 2, 2, 'F');
--
-- SELECT * FROM examen.inscrireEnfant(1, 1);
-- SELECT * FROM examen.inscrireEnfant(2, 2);
-- SELECT * FROM examen.inscrireEnfant(2, 3);
-- SELECT * FROM examen.inscrireEnfant(1, 4); --échec
-- SELECT * FROM examen.inscrireEnfant(1, 2); --échec
-- SELECT * FROM examen.inscrireEnfant(1, 5);
-- SELECT * FROM examen.inscrireEnfant(3, 5);
-- SELECT * FROM examen.inscrireEnfant(3, 1);
-- SELECT * FROM examen.inscrireEnfant(4, 1); --échec
--
-- SELECT * FROM examen.vue
