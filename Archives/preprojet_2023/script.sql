--Question 2

DROP SCHEMA IF EXISTS preprojet CASCADE;
CREATE SCHEMA preprojet;
CREATE TABLE preprojet.utilisateurs (
                                        id_utilisateur SERIAL PRIMARY KEY,
                                        nom VARCHAR(100) NOT NULL CHECK (nom<>''),
                                        prenom VARCHAR(100) NOT NULL CHECK (prenom<>'')
);

CREATE TABLE preprojet.comptes (
                                   numero CHARACTER(10) PRIMARY KEY
                                       CHECK(numero SIMILAR TO '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]'),
	id_utilisateur INTEGER REFERENCES preprojet.utilisateurs (id_utilisateur) NOT NULL
);


CREATE TABLE preprojet.operations (
                                      id_operation SERIAL PRIMARY KEY ,
                                      compte_source CHARACTER(10) REFERENCES preprojet.comptes (numero) NOT NULL,
                                      compte_destination CHARACTER(10) REFERENCES preprojet.comptes (numero) NOT NULL,
                                      montant INTEGER NOT NULL CHECK (montant>0),
                                      date_op DATE NOT NULL DEFAULT current_date,
                                      CHECK (compte_source<>compte_destination)
);

--Question 3

INSERT INTO preprojet.utilisateurs VALUES (DEFAULT, 'Cambron','Isabelle');
INSERT INTO preprojet.utilisateurs VALUES (DEFAULT, 'Damas', 'Christophe');
INSERT INTO preprojet.utilisateurs VALUES (DEFAULT, 'Ferneeuw', 'Stéphanie');

INSERT INTO preprojet.comptes VALUES ('5632-12564',1);
INSERT INTO preprojet.comptes VALUES ('1236-02364',1);
INSERT INTO preprojet.comptes VALUES ('1234-56789',2);
INSERT INTO preprojet.comptes VALUES ('9876-87654',2);
INSERT INTO preprojet.comptes VALUES ('7896-23565',3);

INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-1');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-2');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-3');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-4');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1236-02364','7896-23565',150,'2006-12-5');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-6');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-7');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-8');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-9');

--Question 4

SELECT u1.nom, u1.prenom, c1.numero,
       u2.nom, u2.prenom, c2.numero,
       o.date_op, o.montant
FROM preprojet.comptes c1, preprojet.comptes c2,
     preprojet.utilisateurs u1, preprojet.utilisateurs u2,
     preprojet.operations o
WHERE o.compte_source=c1.numero
  AND c1.id_utilisateur=u1.id_utilisateur
  AND o.compte_destination=c2.numero
  AND c2.id_utilisateur=u2.id_utilisateur
ORDER BY o.date_op;

--Question 5

CREATE OR REPLACE FUNCTION preprojet.insererTransaction(nom_source VARCHAR(100), prenom_source VARCHAR(100), compte_source CHARACTER(10),
			nom_destination VARCHAR(100), prenom_destination VARCHAR(100), compte_destination CHARACTER(10),date_operation DATE, montant_operation INTEGER) RETURNS INTEGER AS $$
DECLARE
id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_source AND c.id_utilisateur=u.id_utilisateur
	  		    AND u.nom=nom_source and u.prenom=prenom_source) THEN
		RAISE foreign_key_violation;
END IF;
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_destination AND c.id_utilisateur=u.id_utilisateur
                            AND u.nom=nom_destination and u.prenom=prenom_destination) THEN
		RAISE foreign_key_violation;
END IF;
INSERT INTO preprojet.operations VALUES 	(DEFAULT,compte_source,compte_destination,montant_operation,date_operation)
    RETURNING id_operation INTO id;
RETURN id;
END;
$$ LANGUAGE plpgsql;

--> Question 6

CREATE OR REPLACE FUNCTION preprojet.evolution(compte CHARACTER(10)) RETURNS SETOF RECORD AS $$
DECLARE
balance INTEGER:=0;
	operation RECORD;
	avecQui CHARACTER(10);
	sortie RECORD;
BEGIN
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c
			    WHERE c.numero=compte) THEN
		RAISE 'compte invalide';
END IF;
FOR operation IN SELECT * FROM preprojet.operations o WHERE o.compte_source=compte OR o.compte_destination=compte ORDER BY o.date_op LOOP
		IF (operation.compte_source=compte)
			THEN 	avecQui:=operation.compte_destination;
balance:=balance-operation.montant;
ELSE	avecQui:=operation.compte_source;
				balance:=balance+operation.montant;
END IF;
SELECT operation.date_op, avecQui, balance INTO sortie;
RETURN NEXT sortie;
END LOOP;
	RETURN;
END;
$$ LANGUAGE 'plpgsql';

SELECT * from preprojet.evolution('1234-56789') t(date_op DATE, avecQui CHARACTER(10), balance INTEGER);

-- Question 7

ALTER TABLE preprojet.comptes ADD COLUMN solde INTEGER;
ALTER TABLE preprojet.comptes ALTER COLUMN solde SET DEFAULT 0;

CREATE OR REPLACE FUNCTION preprojet.trigger () RETURNS TRIGGER AS $$
DECLARE
ancien_solde INTEGER;
BEGIN
SELECT c.solde FROM preprojet.comptes c
WHERE c.numero=NEW.compte_source INTO ancien_solde;
UPDATE preprojet.comptes
SET solde=ancien_solde-NEW.montant
WHERE numero=NEW.compte_source;
SELECT c.solde FROM preprojet.comptes c
WHERE c.numero=NEW.compte_destination INTO ancien_solde;
UPDATE preprojet.comptes
SET solde=ancien_solde+NEW.montant
WHERE numero=NEW.compte_destination;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_solde AFTER INSERT ON preprojet.operations
    FOR EACH ROW EXECUTE PROCEDURE preprojet.trigger();

DELETE FROM preprojet.operations;
UPDATE preprojet.comptes SET solde=0;

INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-1');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-2');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-3');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-4');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1236-02364','7896-23565',150,'2006-12-5');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-6');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-7');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-8');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-9');

SELECT u.nom, u.prenom, c.*
FROM preprojet.utilisateurs u, preprojet.comptes c
WHERE u.id_utilisateur=c.id_utilisateur;

-- Question 8

ALTER TABLE preprojet.utilisateurs ADD COLUMN balance_utilisateur INTEGER;

CREATE OR REPLACE FUNCTION preprojet.trigger2 () RETURNS TRIGGER AS $$
DECLARE
record RECORD;
BEGIN
SELECT u.balance_utilisateur, u.id_utilisateur FROM preprojet.comptes c, preprojet.utilisateurs u
WHERE c.numero=NEW.compte_source AND c.id_utilisateur=u.id_utilisateur INTO record;
UPDATE preprojet.utilisateurs
SET balance_utilisateur=record.balance_utilisateur-NEW.montant
WHERE id_utilisateur=record.id_utilisateur;
SELECT u.balance_utilisateur, u.id_utilisateur FROM preprojet.comptes c, preprojet.utilisateurs u
WHERE c.numero=NEW.compte_destination AND c.id_utilisateur=u.id_utilisateur INTO record;
UPDATE preprojet.utilisateurs
SET balance_utilisateur=record.balance_utilisateur+NEW.montant
WHERE id_utilisateur=record.id_utilisateur;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_balance_utilisateur AFTER INSERT ON preprojet.operations
    FOR EACH ROW EXECUTE PROCEDURE preprojet.trigger2();

DELETE FROM preprojet.operations;
UPDATE preprojet.comptes SET solde=0;
UPDATE preprojet.utilisateurs SET balance_utilisateur=0;

INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-1');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-2');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-3');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-4');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1236-02364','7896-23565',150,'2006-12-5');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'5632-12564','1236-02364',120,'2006-12-6');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'1234-56789','5632-12564',100,'2006-12-7');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'9876-87654','7896-23565',80,'2006-12-8');
INSERT INTO preprojet.operations VALUES
    (DEFAULT,'7896-23565','9876-87654',80,'2006-12-9');

SELECT u.nom, u.prenom, u.balance_utilisateur
FROM preprojet.utilisateurs u;

-- Question 9

CREATE OR REPLACE FUNCTION preprojet.modifierTransaction(nom_source VARCHAR(100), prenom_source VARCHAR(100), compte_s CHARACTER(10),
			nom_destination VARCHAR(100), prenom_destination VARCHAR(100), compte_d CHARACTER(10),date_operation DATE, montant_operation INTEGER) RETURNS INTEGER AS $$
DECLARE
id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_s AND c.id_utilisateur=u.id_utilisateur
	  		    AND u.nom=nom_source and u.prenom=prenom_source) THEN
		RAISE 'compte source invalide';
END IF;
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_d AND c.id_utilisateur=u.id_utilisateur
                            AND u.nom=nom_destination and u.prenom=prenom_destination) THEN
		RAISE 'compte destination invalide';
END IF;
	IF (1<>(SELECT COUNT(*) FROM preprojet.operations o  WHERE o.compte_source=compte_s AND o.compte_destination=compte_d
	AND o.date_op=date_operation)) THEN RAISE 'operation invalide';
END IF;
UPDATE preprojet.operations  SET montant=montant_operation WHERE compte_source=compte_s AND compte_destination=compte_d
                                                             AND date_op=date_operation RETURNING id_operation INTO id;
RETURN id;
END;
$$ LANGUAGE plpgsql;

--Question 10

CREATE OR REPLACE FUNCTION preprojet.supprimerTransaction(nom_source VARCHAR(100), prenom_source VARCHAR(100), compte_s CHARACTER(10),
			nom_destination VARCHAR(100), prenom_destination VARCHAR(100), compte_d CHARACTER(10),date_operation DATE, montant_operation INTEGER) RETURNS INTEGER AS $$
DECLARE
nb INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_s AND c.id_utilisateur=u.id_utilisateur
	  		    AND u.nom=nom_source and u.prenom=prenom_source) THEN
		RAISE 'compte source invalide';
END IF;
	IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.utilisateurs u
			    WHERE c.numero=compte_d AND c.id_utilisateur=u.id_utilisateur
                            AND u.nom=nom_destination and u.prenom=prenom_destination) THEN
		RAISE 'compte destination invalide';
END IF;
SELECT COUNT(*) FROM preprojet.operations o  WHERE o.compte_source=compte_s AND o.compte_destination=compte_d AND o.date_op=date_operation AND o.montant=montant_operation INTO nb;
IF (nb=0) THEN RAISE 'aucune opération correspondante'; END IF;
DELETE FROM preprojet.operations o WHERE o.compte_source=compte_s AND o.compte_destination=compte_d AND o.date_op=date_operation AND o.montant=montant_operation;
RETURN nb;
END;
$$ LANGUAGE plpgsql;