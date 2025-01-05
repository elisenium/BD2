DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen;

CREATE TABLE examen.blocs (
    numero      INTEGER     PRIMARY KEY CHECK ( numero BETWEEN 1 AND 3 )
);

CREATE TABLE examen.series (
    id_serie    SERIAL      PRIMARY KEY,
    bloc        INTEGER     NOT NULL CHECK ( bloc = SUBSTRING(code FROM 1 FOR 1)::INTEGER ),
    code        CHAR(5)     UNIQUE NOT NULL CHECK ( code SIMILAR TO '[1-3]BIN[1-9]' ),

    UNIQUE (code, bloc),
    FOREIGN KEY (bloc) REFERENCES examen.blocs(numero)
);

CREATE TABLE examen.etudiants (
    id_etudiant     SERIAL      PRIMARY KEY,
    nom             VARCHAR(50) NOT NULL CHECK ( trim(nom) != '' ),
    prenom          VARCHAR(50) NOT NULL CHECK ( trim(nom) != '' ),
    bloc            INTEGER     NOT NULL,
    serie           INTEGER     NOT NULL,
    deja_change     BOOLEAN     NOT NULL DEFAULT FALSE,

    FOREIGN KEY (bloc)  REFERENCES examen.blocs(numero),
    FOREIGN KEY (serie) REFERENCES examen.series(id_serie)
);

CREATE OR REPLACE VIEW examen.vue AS
SELECT s.code, s.bloc, s.id_serie, COALESCE(COUNT(e.id_etudiant), 0) AS nbre_etudiants
FROM examen.series s
LEFT OUTER JOIN examen.etudiants e ON s.id_serie = e.serie
GROUP BY s.code, s.bloc, s.id_serie;

CREATE OR REPLACE FUNCTION examen.changementSerie_trigger() RETURNS TRIGGER AS $$
DECLARE
    _bloc_nvlle_serie INTEGER;
    _max_new_bloc INTEGER;
    _nbre_etudiants_old INTEGER;

BEGIN
    IF (OLD.deja_change = TRUE) THEN
        RAISE EXCEPTION 'L’étudiant a déjà changé de série.';
    END IF;

    IF (NEW.serie = OLD.serie) THEN
        RAISE EXCEPTION 'La série en paramètre est la série actuelle de l’étudiant.';
    END IF;

    SELECT s.bloc FROM examen.series s WHERE s.id_serie = NEW.serie INTO _bloc_nvlle_serie;

    IF (OLD.bloc != _bloc_nvlle_serie) THEN
        RAISE EXCEPTION 'La série en paramètre n’appartient pas au même bloc que celui de l’étudiant.';
    END IF;

    SELECT MAX(v.nbre_etudiants) FROM examen.vue v WHERE v.bloc = NEW.bloc INTO _max_new_bloc;
    SELECT v.nbre_etudiants FROM examen.vue v WHERE v.id_serie = OLD.serie INTO _nbre_etudiants_old;

    IF (_nbre_etudiants_old != _max_new_bloc) THEN
        RAISE EXCEPTION 'La série initiale de l’étudiant n’est pas parmi les séries les plus peuplées du bloc';
    END IF;

    NEW.deja_change := TRUE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER changementSerie_trigger BEFORE UPDATE ON examen.etudiants
FOR EACH ROW EXECUTE FUNCTION examen.changementSerie_trigger();

CREATE OR REPLACE FUNCTION examen.changerSerie(_id_etudiant INTEGER, _code_serie CHAR(5)) RETURNS INTEGER AS $$
DECLARE
    _id_nvlle_serie INTEGER;
    _bloc_etudiant INTEGER;
    _toReturn INTEGER;

BEGIN
    SELECT s.id_serie INTO _id_nvlle_serie
    FROM examen.series s
    WHERE s.code = _code_serie;

    SELECT e.bloc FROM examen.etudiants e WHERE e.id_etudiant = _id_etudiant INTO _bloc_etudiant;

    UPDATE examen.etudiants SET serie = _id_nvlle_serie WHERE id_etudiant = _id_etudiant;

    SELECT COALESCE(COUNT(s.id_serie), 0) INTO _toReturn
    FROM examen.series s
    LEFT OUTER JOIN examen.etudiants e ON s.id_serie = e.serie
    WHERE e.id_etudiant IS NULL AND s.bloc = _bloc_etudiant
    GROUP BY s.bloc;

    RETURN _toReturn;
END;
$$ LANGUAGE plpgsql;
