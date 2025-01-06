DROP SCHEMA IF EXISTS examen CASCADE;

CREATE SCHEMA examen;

CREATE TABLE examen.articles (
    id_article      SERIAL          PRIMARY KEY,
    nom_article     VARCHAR(50)     NOT NULL CHECK ( trim(nom_article) != '' ),
    prix            INTEGER         NOT NULL CHECK ( prix > 0 ),
    poids           INTEGER         NOT NULL CHECK ( poids > 0 ),
    quantite_max    INTEGER         CHECK ( quantite_max > 0 ) DEFAULT NULL
);

CREATE TABLE examen.commandes (
    id_commande     SERIAL          PRIMARY KEY,
    nom_client      VARCHAR(50)     NOT NULL CHECK ( trim(nom_client) != '' ),
    date_commande   DATE            NOT NULL,
    type_commande   VARCHAR(10)     NOT NULL CHECK ( type_commande IN ('livraison', 'à emporter') ),
    poids_total     INTEGER         NOT NULL CHECK ( poids_total >= 0 ) DEFAULT 0
);

CREATE TABLE examen.lignes_de_commande (
    commande        INTEGER         NOT NULL,
    article         INTEGER         NOT NULL,
    quantite        INTEGER         NOT NULL CHECK ( quantite > 0 ),

    PRIMARY KEY (commande, article),
    FOREIGN KEY (commande) REFERENCES examen.commandes(id_commande),
    FOREIGN KEY (article)  REFERENCES examen.articles(id_article)
);

--trigger
CREATE OR REPLACE FUNCTION examen.ajouterArticle_trigger() RETURNS TRIGGER AS $$
DECLARE
    _quantite_max INTEGER;
    _prix_article INTEGER;
    _poids_article INTEGER;
    _quantite_lc INTEGER;
    _type_commande VARCHAR(10);
    _prix_total_commande INTEGER;
    _poids_total INTEGER;
BEGIN
    -- infos de l'article
    SELECT a.quantite_max, a.prix, a.poids INTO _quantite_max, _prix_article, _poids_article
    FROM examen.articles a
    WHERE a.id_article = NEW.article;

    -- Check si une ligne de commande existe déjà pour cette commande et cet article
    IF (EXISTS (SELECT 1 FROM examen.lignes_de_commande lc WHERE lc.commande = NEW.commande AND lc.article = NEW.article)) THEN
        SELECT lc.quantite INTO _quantite_lc
        FROM examen.lignes_de_commande lc
        WHERE lc.commande = NEW.commande AND lc.article = NEW.article;

        -- Si la quantité maximale autorisée est dépassée
        IF (_quantite_max IS NOT NULL AND _quantite_lc + 1 > _quantite_max) THEN
            RAISE EXCEPTION 'La quantité commandée dépasse, pour cette commande, la quantité maximale autorisée pour cet article.';
        END IF;

        -- infos: le type de commande et le poids total de la commande
        SELECT c.type_commande, c.poids_total INTO _type_commande, _poids_total
        FROM examen.commandes c
        WHERE c.id_commande = NEW.commande;

        -- Calcul prix total de la commande
        SELECT SUM(a.prix * lc.quantite) INTO _prix_total_commande
        FROM examen.articles a
        JOIN examen.lignes_de_commande lc ON a.id_article = lc.article
        WHERE lc.commande = NEW.commande;

        -- Si le type est 'livraison' et que le prix est supérieur à 1000 €
        IF (_type_commande = 'livraison' AND _prix_total_commande + _prix_article > 1000) THEN
            RAISE EXCEPTION 'Les commandes de type livraison ne peuvent pas dépasser 1000 euros.';
        END IF;

        -- Incrémenter la quantité de la ligne de commande existante
        UPDATE examen.lignes_de_commande
        SET quantite = quantite + 1
        WHERE commande = NEW.commande AND article = NEW.article;

        -- Recalculer le poids total de la commande
        SELECT SUM(a.poids * lc.quantite) INTO _poids_total
        FROM examen.articles a
        JOIN examen.lignes_de_commande lc ON a.id_article = lc.article
        WHERE lc.commande = NEW.commande;

        -- Màj du poids total
        UPDATE examen.commandes
        SET poids_total = _poids_total
        WHERE id_commande = NEW.commande;

        RETURN NULL; -- Empêcher l'insertion d'une nouvelle ligne si elle existe déjà
    ELSE
        -- Ajout du poids total
        SELECT c.poids_total INTO _poids_total
        FROM examen.commandes c
        WHERE c.id_commande = NEW.commande;

        UPDATE examen.commandes
        SET poids_total = _poids_total
        WHERE id_commande = NEW.commande;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER ajouterArticle_trigger BEFORE INSERT ON examen.lignes_de_commande
FOR EACH ROW EXECUTE FUNCTION examen.ajouterArticle_trigger();

CREATE OR REPLACE FUNCTION examen.ajouterArticle(_commande INTEGER, _article INTEGER) RETURNS INTEGER AS $$
DECLARE
    _toReturn INTEGER;
BEGIN
    INSERT INTO examen.lignes_de_commande(commande, article, quantite)
    VALUES (_commande, _article, 1);

    SELECT COUNT(DISTINCT lc1.article) INTO _toReturn
    FROM examen.lignes_de_commande lc1, examen.lignes_de_commande lc2
    WHERE lc1.article = lc2.article AND lc1.commande <> lc2.commande;

    RETURN _toReturn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW examen.vue AS
SELECT c.nom_client, c.id_commande, c.date_commande, COALESCE(SUM(lc.quantite), 0) AS nbre_articles_total
FROM examen.commandes c
    LEFT OUTER JOIN examen.lignes_de_commande lc ON c.id_commande = lc.commande
WHERE c.type_commande = 'livraison'
GROUP BY c.nom_client, c.id_commande, c.date_commande;

INSERT INTO examen.articles (nom_article, prix, poids, quantite_max) VALUES
('Article A', 100, 10, 5),
('Article B', 200, 20, 3),
('Article C', 150, 15, NULL),
('Article D', 250, 25, 4),
('Article E', 300, 30, NULL);

INSERT INTO examen.commandes (nom_client, date_commande, type_commande, poids_total) VALUES
('Client1', '2023-12-01', 'livraison', 0),
('Client2', '2023-12-02', 'à emporter', 0),
('Client3', '2023-12-03', 'livraison', 0),
('Client4', '2023-12-04', 'à emporter', 0),
('Client5', '2023-12-05', 'livraison', 0);

-- INSERT INTO examen.lignes_de_commande (commande, article, quantite) VALUES
-- (1, 1, 5),
-- (1, 2, 3),
-- (2, 3, 2),
-- (2, 4, 1),
-- (3, 5, 4),
-- (3, 1, 2),
-- (4, 2, 3),
-- (4, 3, 1),
-- (5, 4, 2),
-- (5, 5, 3);

INSERT INTO examen.commandes (nom_client, date_commande, type_commande, poids_total) VALUES
('Client1', '2023-12-11', 'livraison', 0);


SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(1,1);
SELECT * FROM examen.ajouterArticle(2,3);
SELECT * FROM examen.ajouterArticle(2,2);
SELECT * FROM examen.ajouterArticle(5,2);
SELECT * FROM examen.ajouterArticle(1,4);

SELECT * FROM examen.vue;

