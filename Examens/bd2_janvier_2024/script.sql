DROP SCHEMA IF EXISTS examen CASCADE;
CREATE SCHEMA examen;

CREATE TABLE examen.blocs (
    numero  INTEGER     PRIMARY KEY CHECK ( numero BETWEEN 1 AND 3 )
);

CREATE TABLE examen.series (
    id      SERIAL      PRIMARY KEY,
    code    CHAR(5)     UNIQUE NOT NULL CHECK ( code SIMILAR TO '[1-3]BIN[1-9]' ),
    bloc    INTEGER REFERENCES examen.blocs(numero) NOT NULL CHECK ( bloc = SUBSTRING(code FROM 1 FOR 1)::INTEGER ),
    UNIQUE (code, bloc)
);

CREATE TABLE examen.etudiants (
    id          SERIAL          PRIMARY KEY,
    nom         VARCHAR(50)     NOT NULL CHECK ( nom != '' ),
    prenom      VARCHAR(50)     NOT NULL CHECK ( prenom != '' ),
    deja_change BOOLEAN         NOT NULL DEFAULT FALSE,

    bloc    INTEGER REFERENCES examen.blocs(numero) NOT NULL,
    serie   INTEGER REFERENCES examen.series(id)    NOT NULL
);

CREATE OR REPLACE FUNCTION examen.changementSerie_trigger() RETURNS TRIGGER AS $$
DECLARE
    _new_bloc INTEGER;
    _max INTEGER;
BEGIN
    SELECT etu.bloc INTO _new_bloc FROM examen.etudiants etu WHERE etu.serie = NEW.serie;
    --Si la série en paramètre n'appartient pas au même bloc que celui de l'étudiant
    IF (OLD.bloc != _new_bloc) THEN
        RAISE EXCEPTION 'La série en paramètre n''appartient pas au même bloc que celui de l''étudiant';
    END IF;

    --Si l'étudiant a déjà changé de série
    IF (OLD.deja_change = TRUE) THEN
        RAISE EXCEPTION 'Cet(te) étudiant(e) a déjà changé de série';
    END IF;

    --Si la série en paramètre est la série actuelle de l'étudiant
    IF ((OLD.serie) = NEW.serie) THEN
        RAISE EXCEPTION 'La série entrée en paramètre est la série actuelle de l''étudiant';
    END IF;

    --Si la série initiale de l'étudiant n'est pas parmi les séries les plus peuplées du bloc
    SELECT MAX(v2.nbre_etudiants) FROM examen.vue v2 WHERE v2.bloc = _new_bloc INTO _max;
    IF ((SELECT v.nbre_etudiants FROM examen.vue v WHERE v.id = OLD.serie) != _max) THEN
        RAISE EXCEPTION 'La série initiale de l''étudiant n''est pas parmi les séries les plus peuplées du bloc';
    END IF;

    NEW.deja_change := TRUE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER changementSerie_trigger BEFORE UPDATE ON examen.etudiants
    FOR EACH ROW EXECUTE FUNCTION examen.changementSerie_trigger();

CREATE OR REPLACE VIEW examen.vue AS
    SELECT s.code, s.bloc, COALESCE(COUNT(e.id), 0) AS "nbre_etudiants", s.id
    FROM examen.series s LEFT OUTER JOIN examen.etudiants e ON s.id = e.serie
    GROUP BY s.id, s.code, s.bloc
    ORDER BY nbre_etudiants DESC;

CREATE OR REPLACE FUNCTION examen.changerSerie(_etudiant INTEGER, _code_serie CHAR(5)) RETURNS INTEGER AS $$
DECLARE
    _id_new_serie INTEGER;
    _toReturn INTEGER;
BEGIN
    SELECT s.id INTO _id_new_serie FROM examen.series s WHERE s.code = _code_serie;

    UPDATE examen.etudiants SET serie = _id_new_serie WHERE id = _etudiant;

    SELECT COUNT(v.code) FROM examen.vue v WHERE v.nbre_etudiants = 0 INTO _toReturn;
    RETURN _toReturn;
END
$$ LANGUAGE plpgsql;

/* INSERTS */

INSERT INTO examen.blocs (numero) VALUES (1);
INSERT INTO examen.blocs (numero) VALUES (2);
INSERT INTO examen.blocs (numero) VALUES (3);

INSERT INTO examen.series (code, bloc) VALUES ('1BIN1', 1);
INSERT INTO examen.series (code, bloc) VALUES ('1BIN2', 1);
INSERT INTO examen.series (code, bloc) VALUES ('1BIN3', 1);
INSERT INTO examen.series (code, bloc) VALUES ('2BIN1', 2);
INSERT INTO examen.series (code, bloc) VALUES ('2BIN2', 2);
INSERT INTO examen.series (code, bloc) VALUES ('2BIN3', 2);
INSERT INTO examen.series (code, bloc) VALUES ('3BIN1', 3);
INSERT INTO examen.series (code, bloc) VALUES ('3BIN2', 3);
INSERT INTO examen.series (code, bloc) VALUES ('3BIN3', 3);

INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Grelaud', 'Elise', 1, 1);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Smith', 'Lola', 3, 7);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Da Santos', 'Maria', 1, 2);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Martin', 'Georges', 3, 7);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Hill', 'Joe', 3, 7);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Will', 'Barry', 2, 5);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Wright', 'Jalen', 2, 5);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Jackson', 'Lucia', 2, 5);
INSERT INTO examen.etudiants (nom, prenom, bloc, serie) VALUES ('Devine', 'Lorette', 3, 9);


/*TESTS*/

/*
SELECT * FROM examen.changerSerie(4, '3BIN2');
SELECT * FROM examen.changerSerie(2, '3BIN3');
SELECT * FROM examen.changerSerie(7, '2BIN1');
SELECT * FROM examen.changerSerie(2, '3BIN3'); --ERROR: Cet(te) étudiant(e) a déjà changé de série
SELECT * FROM examen.changerSerie(4, '3BIN1'); --ERROR: Cet(te) étudiant(e) a déjà changé de série
SELECT * FROM examen.changerSerie(6, '1BIN2'); --ERROR: La série en paramètre n'appartient pas au même bloc que celui de l'étudiant
SELECT * FROM examen.changerSerie(6, '2BIN2'); --ERROR: La série entrée en paramètre est la série actuelle de l'étudiant
SELECT * FROM examen.changerSerie(1, '1BIN2');
SELECT * FROM examen.changerSerie(1,'1BIN3'); --ERROR: Cet(te) étudiant(e) a déjà changé de série
SELECT * FROM examen.changerSerie(5,'3BIN3'); --ERROR: La série initiale de l'étudiant n'est pas parmi les séries les plus peuplées du bloc
*/
